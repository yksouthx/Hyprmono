import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    property real volume: 0.5
    property bool muted: false
    property string statusMessage: ""
    property string commandError: ""
    signal dismissed()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hyprmono-quick-settings"

    Process {
        id: readVolume
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume:\s+([0-9.]+)/)
                if (match) {
                    root.volume = Math.max(0, Math.min(1, Number(match[1])))
                    root.muted = /\[MUTED\]/.test(text)
                    root.statusMessage = ""
                } else {
                    root.statusMessage = "Could not read the audio output volume."
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.commandError = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (exitStatus !== 0 || exitCode !== 0)
                root.statusMessage = root.commandError !== ""
                    ? root.commandError
                    : "Audio volume query failed with exit code " + exitCode + "."
        }
    }

    Process {
        id: writeVolume
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", root.volume.toFixed(2)]
        stderr: StdioCollector {
            onStreamFinished: root.commandError = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (exitStatus !== 0 || exitCode !== 0)
                root.statusMessage = root.commandError !== ""
                    ? root.commandError
                    : "Audio volume update failed with exit code " + exitCode + "."
            else
                root.statusMessage = ""
        }
    }

    Process {
        id: toggleMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        stderr: StdioCollector {
            onStreamFinished: root.commandError = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (exitStatus !== 0 || exitCode !== 0) {
                root.statusMessage = root.commandError !== ""
                    ? root.commandError
                    : "Audio mute toggle failed with exit code " + exitCode + "."
            } else {
                root.statusMessage = ""
                readVolume.running = true
            }
        }
    }

    // Coalesce rapid slider/keyboard changes into one wpctl call.
    Timer {
        id: writeDebounce
        interval: 150
        onTriggered: writeVolume.running = true
    }

    onVisibleChanged: {
        if (visible) {
            root.commandError = ""
            readVolume.running = true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 60
        anchors.rightMargin: 18
        width: 300
        height: 240
        radius: 14
        color: "#0b0b0b"
        border.width: 1
        border.color: "#414141"
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        transformOrigin: Item.TopRight

        Behavior on opacity {
            UiAnimation {
                duration: 220
            }
        }

        Behavior on scale {
            UiAnimation {
                duration: 220
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "QUICK SETTINGS"
                    color: "#9b9b9b"
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.family: "NType82Mono"
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "×"
                    color: "#cfcfcf"
                    font.pixelSize: 19
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.dismissed()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#343434"
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "OUTPUT"
                    color: "#bdbdbd"
                    font.pixelSize: 10
                    font.family: "NType82Mono"
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: root.muted ? "UNMUTE" : "MUTE"
                    onClicked: {
                        root.commandError = ""
                        toggleMute.running = true
                    }
                }
            }

            Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                value: root.volume
                onMoved: {
                    root.volume = value
                    root.commandError = ""
                    writeDebounce.restart()
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Audio output · " + Math.round(root.volume * 100) + "%" + (root.muted ? " · muted" : "")
                color: "#858585"
                font.pixelSize: 10
                font.family: "NType82Mono"
            }

            Text {
                Layout.fillWidth: true
                text: root.statusMessage || "Default output via PipeWire (wpctl)"
                color: root.statusMessage ? "#d9aaaa" : "#656565"
                font.pixelSize: 9
                font.family: "NType82Mono"
            }
        }
    }
}
