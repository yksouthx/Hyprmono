import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PanelWindow {
    id: root

    property var player
    signal dismissed()

    screen: Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hyprmono-media"

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.player !== null && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(460, parent.width - 32)
        height: 455
        radius: 16
        color: "#0b0b0b"
        border.width: 1
        border.color: "#414141"

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "NOW PLAYING"
                    color: "#9b9b9b"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    font.family: "NType82Mono"
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "×"
                    color: "#cfcfcf"
                    font.pixelSize: 20

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.dismissed()
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 128
                Layout.preferredHeight: 128
                radius: 12
                color: "#202020"
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize: Qt.size(256, 256)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.player || !root.player.trackArtUrl
                    text: "H M"
                    color: "#d7d7d7"
                    font.pixelSize: 28
                    font.family: "NType82Mono"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.player?.trackTitle || "Nothing playing"
                    color: "#f0f0f0"
                    font.pixelSize: 17
                    font.family: "NType82Mono"
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.player?.trackArtist || "Start playback in a media app"
                    color: "#999999"
                    font.pixelSize: 11
                    font.family: "NType82Mono"
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.player?.trackAlbum || ""
                    color: "#707070"
                    font.pixelSize: 10
                    font.family: "NType82Mono"
                    elide: Text.ElideRight
                }
            }

            Slider {
                id: seek
                Layout.fillWidth: true
                from: 0
                to: root.player?.length > 0 ? root.player.length : 1
                value: root.player?.position ?? 0
                enabled: root.player?.canSeek ?? false
                onMoved: {
                    if (root.player?.positionSupported)
                        root.player.position = value
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.player ? formatTime(root.player.position) : "0:00"
                    color: "#888888"
                    font.pixelSize: 10
                    font.family: "NType82Mono"
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.player ? formatTime(root.player.length) : "0:00"
                    color: "#888888"
                    font.pixelSize: 10
                    font.family: "NType82Mono"
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 22

                Button {
                    text: "⇄"
                    enabled: (root.player?.canControl && root.player?.shuffleSupported) ?? false
                    onClicked: root.player.shuffle = !root.player.shuffle
                }

                Button {
                    text: "‹"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                Button {
                    text: root.player?.isPlaying ? "Ⅱ" : "▶"
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }

                Button {
                    text: "›"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }

                Button {
                    text: root.player?.loopState === MprisLoopState.Track ? "↻¹" : "↻"
                    enabled: (root.player?.canControl && root.player?.loopSupported) ?? false
                    onClicked: {
                        if (root.player.loopState === MprisLoopState.None)
                            root.player.loopState = MprisLoopState.Playlist
                        else if (root.player.loopState === MprisLoopState.Playlist)
                            root.player.loopState = MprisLoopState.Track
                        else
                            root.player.loopState = MprisLoopState.None
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: (root.player?.canControl && root.player?.volumeSupported) ?? false
                Text {
                    text: "VOL"
                    color: "#999999"
                    font.pixelSize: 9
                    font.family: "NType82Mono"
                }

                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: root.player?.volume ?? 0
                    onMoved: root.player.volume = value
                }
            }
        }
    }

    function formatTime(seconds) {
        const safeSeconds = Math.max(0, Math.floor(seconds || 0))
        return Math.floor(safeSeconds / 60) + ":"
            + String(safeSeconds % 60).padStart(2, "0")
    }
}
