#!/usr/bin/env bash
# Build and install Calm-shell from the user's preferred repository.
set -Eeuo pipefail

readonly CALM_SHELL_REPO="${CALM_SHELL_REPO:-https://github.com/yksouthx/calm-shell.git}"
readonly SOURCE_DIR="${CALM_SHELL_SOURCE_DIR:-$HOME/.local/src/calm-shell}"
readonly BUILD_DIR="$SOURCE_DIR/build"
readonly INSTALL_PREFIX="${CALM_SHELL_INSTALL_PREFIX:-$HOME/.local}"

log() { printf '[calm-shell] %s\n' "$*"; }
err() { printf '[calm-shell] error: %s\n' "$*" >&2; }

if [[ "$SOURCE_DIR" == "/" || "$SOURCE_DIR" == "$HOME" ]]; then
    err "Refusing unsafe Calm-shell source directory: $SOURCE_DIR"
    exit 1
fi

for command in git cmake ninja; do
    if ! command -v "$command" >/dev/null 2>&1; then
        err "'$command' is required. Install the build prerequisites, then rerun this script."
        exit 1
    fi
done

mkdir -p "$(dirname "$SOURCE_DIR")"
if [[ -d "$SOURCE_DIR/.git" ]]; then
    log "Updating $SOURCE_DIR"
    git -C "$SOURCE_DIR" pull --ff-only
elif [[ -e "$SOURCE_DIR" || -L "$SOURCE_DIR" ]]; then
    err "Refusing to overwrite existing non-repository path: $SOURCE_DIR"
    err "Move it aside or set CALM_SHELL_SOURCE_DIR to an empty path, then rerun."
    exit 1
else
    log "Cloning $CALM_SHELL_REPO"
    git clone "$CALM_SHELL_REPO" "$SOURCE_DIR"
fi

log "Configuring Calm-shell"
cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
log "Building Calm-shell"
cmake --build "$BUILD_DIR"
log "Installing Calm-shell into $INSTALL_PREFIX"
cmake --install "$BUILD_DIR"

if [[ -x "$INSTALL_PREFIX/bin/calm" ]]; then
    "$INSTALL_PREFIX/bin/calm" repair >/dev/null 2>&1 || true
    log "Installed $INSTALL_PREFIX/bin/calm"
else
    err "The build completed, but $INSTALL_PREFIX/bin/calm was not found."
    exit 1
fi
