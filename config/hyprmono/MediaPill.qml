import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Io

Item {
    id: root

    property var player
    property bool hovered: hover.hovered
    property bool cavaEnabled: false
    property bool dashboardOpen: false
    property var spectrum: [0.2, 0.35, 0.5, 0.35, 0.2]
    readonly property int artSize: 30
    signal clicked()

    visible: player !== null
    implicitWidth: visible ? pill.width : 0
    implicitHeight: 36

    function updateSpectrum(line) {
        const parsed = line.trim().split(/[;,\s]+/)
            .filter(value => value.length > 0)
            .map(Number)
            .filter(Number.isFinite)
            .map(value => Math.max(0, Math.min(1, value / 100)))
        if (parsed.length > 0)
            spectrum = parsed.slice(0, 5)
    }

    Process {
        id: cava
        command: [
            "sh", "-c",
            "command -v cava >/dev/null 2>&1 || exit 127; config_home=\"${XDG_CONFIG_HOME:-$HOME/.config}\"; exec cava -p \"$config_home/hyprmono/cava.conf\""
        ]
        running: root.cavaEnabled && root.player !== null && root.player.isPlaying
            && root.visible && !root.dashboardOpen
        onExited: (exitCode, exitStatus) => {
            if (root.player?.isPlaying && exitCode !== 0)
                console.warn("CAVA could not start; using the static media indicator.")
        }
        stdout: SplitParser {
            onRead: data => root.updateSpectrum(data)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.player !== null && root.player.isPlaying && root.visible
            && !root.dashboardOpen
        onTriggered: root.player.positionChanged()
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: row.implicitWidth + 22
        height: 36
        radius: 10
        color: hover.hovered ? "#202020" : "#111111"
        border.width: 1
        border.color: "#3b3b3b"

        Behavior on width {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                Layout.preferredWidth: root.artSize
                Layout.preferredHeight: root.artSize
                radius: width / 2
                color: "#262626"
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize: Qt.size(root.artSize * 2, root.artSize * 2)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.player?.trackArtUrl === ""
                    text: "♪"
                    color: "#d8d8d8"
                    font.pixelSize: 16
                }
            }

            Row {
                spacing: 2
                height: root.artSize

                Repeater {
                    model: 5

                    Rectangle {
                        required property int index
                        readonly property real cavaLevel: root.spectrum[index] ?? 0.25
                        width: 3
                        height: Math.max(4, root.artSize * (
                            cava.running ? 0.12 + cavaLevel * 0.88 :
                            root.player?.isPlaying ? 0.18 + (index % 3) * 0.08 : 0.12
                        ))
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 2
                        color: root.player?.isPlaying ? "#eeeeee" : "#777777"
                    }
                }
            }

            Item {
                Layout.preferredWidth: root.hovered
                    ? Math.min(trackInfo.implicitWidth, 190) : 0
                Layout.preferredHeight: trackInfo.implicitHeight
                clip: true
                visible: Layout.preferredWidth > 0

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: trackInfo
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.player?.trackTitle || "Unknown track")
                        + (root.player?.trackArtist ? "  ·  " + root.player.trackArtist : "")
                    color: "#dddddd"
                    font.pixelSize: 10
                    font.family: "NType82Mono"
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            x: 10
            y: parent.height - 3
            width: Math.max(0, (parent.width - 20) * (
                root.player?.length > 0
                    ? Math.min(1, root.player.position / root.player.length)
                    : 0
            ))
            height: 2
            radius: 1
            color: "#dedede"
            visible: root.player?.positionSupported && root.player?.length > 0
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.clicked()
            else if (mouse.button === Qt.MiddleButton && root.player?.canTogglePlaying)
                root.player.togglePlaying()
            else if (mouse.button === Qt.RightButton && root.player?.canGoNext)
                root.player.next()
        }
    }

    WheelHandler {
        onWheel: event => {
            if (root.player?.canControl && root.player?.volumeSupported) {
                const delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                root.player.volume = Math.max(0, Math.min(1, root.player.volume + delta))
            }
        }
    }
}
