import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Io

PanelWindow {
    id: root

    property var player
    property bool cavaEnabled: false
    property bool dashboardOpen: false
    property string memoryText: "RAM --%"
    signal mediaClicked()
    signal quickSettingsClicked()

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 52
    exclusiveZone: 46
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "hyprmono-bar"

    Process {
        id: memorySample
        command: [
            "sh", "-c",
            "memory=$(awk '/^MemTotal:/ { total=$2 } /^MemAvailable:/ { available=$2 } END { if (total > 0) printf \"RAM %d%%\", (total - available) * 100 / total }' /proc/meminfo); load=$(awk '{ print $1 }' /proc/loadavg); printf '%s · LOAD %s' \"$memory\" \"$load\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.memoryText = text.trim()
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: memorySample.running = true
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        radius: 11
        color: "#080808"
        border.width: 1
        border.color: "#333333"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 10

                Row {
                    spacing: 3

                    Repeater {
                        model: Hyprland.workspaces.values.filter(
                            workspace => workspace.id > 0 && workspace.id <= 10
                        )

                        delegate: Rectangle {
                            required property var modelData
                            width: 23
                            height: 25
                            radius: 6
                            color: modelData.focused ? "#eeeeee" : "#181818"
                            border.width: modelData.active && !modelData.focused ? 1 : 0
                            border.color: "#777777"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: modelData.focused ? "#080808" : "#bcbcbc"
                                font.pixelSize: 11
                                font.family: "NType82Mono"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 18
                    color: "#444444"
                }

                Text {
                    Layout.maximumWidth: 210
                    text: Hyprland.activeToplevel?.title ?? "H Y P R M O N O"
                    color: "#cfcfcf"
                    font.pixelSize: 11
                    font.family: "NType82Mono"
                    elide: Text.ElideRight
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                MediaPill {
                    player: root.player
                    cavaEnabled: root.cavaEnabled
                    dashboardOpen: root.dashboardOpen
                    onClicked: root.mediaClicked()
                }

                Text {
                    id: clock
                    property date now: new Date()
                    text: Qt.formatDateTime(now, "ddd dd MMM  HH:mm")
                    color: "#d8d8d8"
                    font.pixelSize: 11
                    font.family: "NType82Mono"

                    Timer {
                        interval: 30000
                        repeat: true
                        running: true
                        onTriggered: clock.now = new Date()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                Text {
                    text: root.memoryText
                    color: "#a9a9a9"
                    font.pixelSize: 10
                    font.family: "NType82Mono"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.quickSettingsClicked()
                    }
                }

                Row {
                    spacing: 5

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            required property var modelData
                            width: 18
                            height: 20

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: modelData.icon
                                sourceSize: Qt.size(32, 32)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }

                Rectangle {
                    width: 30
                    height: 28
                    radius: 7
                    color: settingsMouse.containsMouse ? "#292929" : "#171717"

                    Text {
                        anchors.centerIn: parent
                        text: "SET"
                        color: "#eeeeee"
                        font.pixelSize: 8
                        font.family: "NType82Mono"
                    }

                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.quickSettingsClicked()
                    }
                }
            }
        }
    }
}
