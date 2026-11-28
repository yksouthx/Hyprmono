import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ApplicationWindow {
    id: root

    property string activeProfile: ""
    property string pendingProfile: ""
    property string lastError: ""
    property string performanceOutput: "No performance sample has been run."
    property string performanceError: ""
    property string statusText: "Reading the current compositor profile…"
    property bool busy: true
    property bool measuring: false

    width: 720
    height: 560
    minimumWidth: 620
    minimumHeight: 480
    visible: true
    title: "HyprMono Settings"
    color: "#090909"

    Component.onCompleted: readProfile.exec([
        "bash", "-c", "exec \"$HOME/.local/bin/profile.sh\" show"
    ])

    Process {
        id: readProfile

        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/profile: (low-resource|balanced|full-visual)/)
                if (match)
                    root.activeProfile = match[1]
                else
                    root.statusText = "Could not read the current compositor profile."
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false
            if (exitStatus !== 0 || exitCode !== 0)
                root.statusText = "Profile read failed. Check the installed profile helper."
            else if (root.activeProfile !== "")
                root.statusText = "Changes apply immediately and reload Hyprland."
        }
    }

    Process {
        id: writeProfile

        stderr: StdioCollector {
            onStreamFinished: {
                root.lastError = text.trim()
                if (!root.busy && root.lastError !== "")
                    root.statusText = "Profile update failed: " + root.lastError
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false
            if (exitStatus === 0 && exitCode === 0) {
                root.activeProfile = root.pendingProfile
                root.statusText = "Profile applied and Hyprland reloaded."
            } else {
                root.statusText = root.lastError !== ""
                    ? "Profile update failed: " + root.lastError
                    : "Profile update failed with exit code " + exitCode + "."
            }
        }
    }

    Process {
        id: performanceSample

        stdout: StdioCollector {
            onStreamFinished: root.performanceOutput = text.trim()
        }

        stderr: StdioCollector {
            onStreamFinished: root.performanceError = text.trim()
        }

        onExited: (exitCode, exitStatus) => {
            root.measuring = false
            if (exitStatus !== 0 || exitCode !== 0)
                root.performanceOutput = root.performanceError !== ""
                    ? root.performanceError
                    : "Performance sample failed with exit code " + exitCode + "."
        }
    }

    function applyProfile(profile) {
        const commands = {
            "low-resource": "exec \"$HOME/.local/bin/profile.sh\" low-resource",
            "balanced": "exec \"$HOME/.local/bin/profile.sh\" balanced",
            "full-visual": "exec \"$HOME/.local/bin/profile.sh\" full-visual"
        }

        if (!(profile in commands) || busy)
            return

        pendingProfile = profile
        lastError = ""
        busy = true
        statusText = "Applying profile…"
        writeProfile.exec(["bash", "-c", commands[profile]])
    }

    function measurePerformance() {
        performanceError = ""
        performanceOutput = "Sampling CPU and resident memory for five seconds…"
        measuring = true
        performanceSample.exec([
            "bash", "-c", "exec \"$HOME/.local/bin/performance.sh\" --seconds 5"
        ])
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 34
        spacing: 20

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "H Y P R M O N O"
                color: "#f4f4f4"
                font.pixelSize: 14
                font.letterSpacing: 2.5
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Label {
                text: "SETTINGS"
                color: "#8f8f8f"
                font.pixelSize: 10
                font.letterSpacing: 2
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#383838"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Performance"
                color: "#ffffff"
                font.pixelSize: 26
                font.weight: Font.Medium
            }

            Label {
                Layout.fillWidth: true
                text: "Choose how Hyprland balances visual effects and compositor workload."
                color: "#bcbcbc"
                font.pixelSize: 13
                wrapMode: Text.Wrap
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                Layout.fillWidth: true
                text: "Low Resource    —    Minimal blur, shadows, and animations"
                enabled: !root.busy && root.activeProfile !== "low-resource"
                onClicked: root.applyProfile("low-resource")
            }

            Button {
                Layout.fillWidth: true
                text: "Balanced    —    Reduced blur and shadows, animations enabled"
                enabled: !root.busy && root.activeProfile !== "balanced"
                onClicked: root.applyProfile("balanced")
            }

            Button {
                Layout.fillWidth: true
                text: "Full Visual    —    Full blur, shadows, and animations"
                enabled: !root.busy && root.activeProfile !== "full-visual"
                onClicked: root.applyProfile("full-visual")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 10
            color: "#171717"
            border.color: "#383838"
            border.width: 1
            implicitHeight: resourceControls.implicitHeight + 28

            ColumnLayout {
                id: resourceControls
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Label {
                    text: "Resource sample"
                    color: "#eeeeee"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                Label {
                    Layout.fillWidth: true
                    text: root.performanceOutput
                    color: "#bcbcbc"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }

                Button {
                    text: root.measuring ? "Measuring…" : "Measure CPU and RAM"
                    enabled: !root.measuring
                    onClicked: root.measurePerformance()
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.activeProfile !== ""
                ? "Current profile: " + root.activeProfile
                : root.statusText
            color: "#dedede"
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }

        Item { Layout.fillHeight: true }

        Label {
            Layout.fillWidth: true
            text: root.statusText
                + "\nUse `hyprmono performance --record` to save a baseline."
                + "\nAdvanced users can edit ~/.config/hypr/custom/*.lua directly."
            color: "#858585"
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}
