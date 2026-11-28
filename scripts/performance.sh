#!/usr/bin/env bash

set -Eeuo pipefail

readonly BASELINE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/Hyprmono/performance-baseline.tsv"
DURATION=5
RECORD=0
COMPARE=0
MAX_REGRESSION=""

usage() {
    cat <<'EOF'
Usage: hyprmono performance [OPTIONS]

Measure average CPU use and resident memory for running Niri and Caffyne Shell
processes. CPU is reported as a percentage of one logical CPU.

Options:
  --seconds N             Sample duration, from 1 to 60 (default: 5)
  --record                Save this sample as the comparison baseline
  --compare               Compare this sample with the saved baseline
  --fail-regression N     Compare and exit non-zero if any metric increases
                          more than N percent above the baseline
  --help                  Show this help
EOF
}

read_process_ticks() {
    local pid="$1" line remainder
    local -a fields=()
    [[ -r "/proc/$pid/stat" ]] || return 1
    IFS= read -r line < "/proc/$pid/stat" || return 1
    remainder=${line##*) }
    read -r -a fields <<< "$remainder"
    (( ${#fields[@]} >= 13 )) || return 1
    printf '%s\n' "$((fields[11] + fields[12]))"
}

process_group() {
    local pid="$1" comm first_arg
    [[ -r "/proc/$pid/comm" ]] || return 1
    IFS= read -r comm < "/proc/$pid/comm" || return 1
    case "$comm" in
        niri) printf '%s\n' niri; return 0 ;;
        python3|python) ;;
    esac

    [[ -r "/proc/$pid/cmdline" ]] || return 1
    IFS= read -r -d '' first_arg < "/proc/$pid/cmdline" || true
    if [[ "${first_arg##*/}" == niri ]]; then
        printf '%s\n' niri
        return 0
    fi

    local cmdline
    cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
    if [[ "$cmdline" == *"caffyne-shell"* || "$cmdline" == *"/main.py"* ]]; then
        printf '%s\n' caffyne
        return 0
    fi
    return 1
}

read_resident_kib() {
    local pid="$1"
    awk '/^VmRSS:/ { print $2; found = 1; exit } END { if (!found) print 0 }' "/proc/$pid/status"
}

snapshot_group() {
    local wanted_group="$1" output_name="$2"
    # shellcheck disable=SC2178  # nameref to the caller's associative array
    local -n output="$output_name"
    local proc_dir pid group ticks

    for proc_dir in /proc/[0-9]*; do
        pid=${proc_dir#/proc/}
        group=$(process_group "$pid") || continue
        [[ "$group" == "$wanted_group" ]] || continue
        ticks=$(read_process_ticks "$pid") || continue
        # shellcheck disable=SC2034  # writes through the nameref to the caller's array
        output["$pid"]="$ticks"
    done
}

current_group_usage() {
    local wanted_group="$1" before_name="$2"
    local -n before="$before_name"
    local proc_dir pid group ticks rss_kib
    local ticks_delta=0 rss_total=0 process_count=0

    for proc_dir in /proc/[0-9]*; do
        pid=${proc_dir#/proc/}
        group=$(process_group "$pid") || continue
        [[ "$group" == "$wanted_group" ]] || continue
        process_count=$((process_count + 1))
        rss_kib=$(read_resident_kib "$pid") || rss_kib=0
        rss_total=$((rss_total + rss_kib))
        if [[ -v "before[$pid]" ]] && ticks=$(read_process_ticks "$pid") &&
            (( ticks >= before[$pid] )); then
            ticks_delta=$((ticks_delta + ticks - before[$pid]))
        fi
    done

    local cpu_percent
    cpu_percent=$(awk -v ticks="$ticks_delta" -v hz="$CLK_TCK" -v duration="$DURATION" \
        'BEGIN { if (duration > 0) printf "%.2f", ticks * 100 / (hz * duration); else print "0.00" }')
    local memory_mib
    memory_mib=$(awk -v kib="$rss_total" 'BEGIN { printf "%.1f", kib / 1024 }')

    # Results are published to globals named <group>_cpu/_memory/_count.
    printf -v "${wanted_group}_cpu" '%s' "$cpu_percent"
    printf -v "${wanted_group}_memory" '%s' "$memory_mib"
    printf -v "${wanted_group}_count" '%s' "$process_count"
}

metric_regressed() {
    local current="$1" baseline="$2" tolerance="$3"
    awk -v current="$current" -v baseline="$baseline" -v tolerance="$tolerance" \
        'BEGIN {
            regressed = baseline == 0 ? current > 0 : current > baseline * (1 + tolerance / 100)
            exit(regressed ? 0 : 1)
        }'
}

# shellcheck disable=SC2154  # niri_*/caffyne_* are set via printf -v
compare_baseline() {
    local recorded_at recorded_duration base_niri_cpu base_niri_memory base_caffyne_cpu base_caffyne_memory
    [[ -r "$BASELINE_FILE" ]] || {
        printf 'Performance baseline not found: %s\n' "$BASELINE_FILE" >&2
        printf 'Record one with: hyprmono performance --record\n' >&2
        return 1
    }

    IFS=$'\t' read -r recorded_at recorded_duration base_niri_cpu base_niri_memory base_caffyne_cpu base_caffyne_memory \
        < "$BASELINE_FILE"
    [[ "$recorded_at" =~ ^[0-9T:+-]+$ &&
       "$recorded_duration" =~ ^[0-9]+$ &&
       "$base_niri_cpu" =~ ^[0-9]+([.][0-9]+)?$ &&
       "$base_niri_memory" =~ ^[0-9]+([.][0-9]+)?$ &&
       "$base_caffyne_cpu" =~ ^[0-9]+([.][0-9]+)?$ &&
       "$base_caffyne_memory" =~ ^[0-9]+([.][0-9]+)?$ ]] || {
        printf 'Invalid performance baseline file: %s\n' "$BASELINE_FILE" >&2
        return 1
    }

    printf '\nComparison with baseline recorded %s (%s-second sample):\n' "$recorded_at" "$recorded_duration"
    printf '  Niri CPU:   %s%% baseline, %s%% current\n' "$base_niri_cpu" "$niri_cpu"
    printf '  Niri RAM:   %s MiB baseline, %s MiB current\n' "$base_niri_memory" "$niri_memory"
    printf '  Caffyne Shell CPU: %s%% baseline, %s%% current\n' "$base_caffyne_cpu" "$caffyne_cpu"
    printf '  Caffyne Shell RAM: %s MiB baseline, %s MiB current\n' "$base_caffyne_memory" "$caffyne_memory"

    if [[ -n "$MAX_REGRESSION" ]]; then
        local regression=0 metric
        for metric in \
            "$niri_cpu:$base_niri_cpu" \
            "$niri_memory:$base_niri_memory" \
            "$caffyne_cpu:$base_caffyne_cpu" \
            "$caffyne_memory:$base_caffyne_memory"; do
            if metric_regressed "${metric%%:*}" "${metric#*:}" "$MAX_REGRESSION"; then
                regression=1
            fi
        done
        if (( regression )); then
            printf 'Resource regression exceeded the configured %s%% tolerance.\n' "$MAX_REGRESSION" >&2
            return 1
        fi
        printf 'No resource metric exceeded the configured %s%% tolerance.\n' "$MAX_REGRESSION"
    fi
}

# shellcheck disable=SC2154  # niri_*/caffyne_* are set via printf -v
main() {
    while (( $# > 0 )); do
        case "$1" in
            --seconds)
                [[ $# -ge 2 && "$2" =~ ^[0-9]+$ && "$2" -ge 1 && "$2" -le 60 ]] || {
                    printf '--seconds must be an integer from 1 to 60.\n' >&2
                    exit 2
                }
                DURATION="$2"
                shift 2
                ;;
            --record)
                RECORD=1
                shift
                ;;
            --compare)
                COMPARE=1
                shift
                ;;
            --fail-regression)
                [[ $# -ge 2 && "$2" =~ ^[0-9]+([.][0-9]+)?$ ]] || {
                    printf '--fail-regression requires a non-negative percentage.\n' >&2
                    exit 2
                }
                MAX_REGRESSION="$2"
                COMPARE=1
                shift 2
                ;;
            --help|-h)
                usage
                return 0
                ;;
            *)
                printf 'Unknown option: %s\n' "$1" >&2
                usage >&2
                exit 2
                ;;
        esac
    done

    if (( RECORD && COMPARE )); then
        printf 'Use either --record or --compare in one sample, not both.\n' >&2
        exit 2
    fi

    CLK_TCK=$(getconf CLK_TCK) || {
        printf 'Unable to determine the system clock tick rate.\n' >&2
        exit 1
    }

    local -A before_niri=() before_caffyne=()
    snapshot_group niri before_niri
    snapshot_group caffyne before_caffyne
    if (( ${#before_niri[@]} == 0 && ${#before_caffyne[@]} == 0 )); then
        printf 'No Niri or Caffyne Shell process is running; start the desktop before sampling.\n' >&2
        exit 1
    fi

    printf 'Sampling Niri and Caffyne Shell for %s seconds…\n' "$DURATION"
    sleep "$DURATION"
    current_group_usage niri before_niri
    current_group_usage caffyne before_caffyne

    printf 'Niri:   %s%% CPU, %s MiB resident memory (%s processes)\n' \
        "$niri_cpu" "$niri_memory" "$niri_count"
    printf 'Caffyne Shell: %s%% CPU, %s MiB resident memory (%s processes)\n' \
        "$caffyne_cpu" "$caffyne_memory" "$caffyne_count"

    if (( RECORD )); then
        mkdir -p "$(dirname "$BASELINE_FILE")"
        local temporary_file
        temporary_file=$(mktemp "${BASELINE_FILE}.XXXXXX")
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$(date --iso-8601=seconds)" "$DURATION" \
            "$niri_cpu" "$niri_memory" "$caffyne_cpu" "$caffyne_memory" > "$temporary_file"
        mv -f -- "$temporary_file" "$BASELINE_FILE"
        printf 'Saved performance baseline to %s\n' "$BASELINE_FILE"
    fi

    if (( COMPARE )); then
        compare_baseline
    fi
}

main "$@"
