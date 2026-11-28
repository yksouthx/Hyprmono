import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ApplicationWindow {
    id: root

    readonly property string repositoryPath: decodeURIComponent(
        Qt.resolvedUrl("../../").toString().replace(/^file:\/\//, "")
    )
    property bool installing: false
    property bool finished: false
    property bool succeeded: false

    width: 900
    height: 660
    minimumWidth: 720
    minimumHeight: 560
    visible: true
    title: "HyprMono Installer"
    color: "#080808"

    onClosing: (close) => {
        if (root.installing)
            close.accepted = false
    }

    Process {
        id: installProcess

        onExited: (exitCode, exitStatus) => {
            root.installing = false
            root.finished = true
            root.succeeded = exitStatus === 0 && exitCode === 0
        }
    }

    function startInstallation() {
        const command = [
            "bash",
            repositoryPath + "/scripts/run-installer-terminal",
            repositoryPath + "/scripts/install.sh",
            "--terminal",
            "--profile",
            profileSelector.currentText.toLowerCase()
        ]

        if (!reviewCleanup.checked)
            command.push("--no-cleanup")
        if (skipDependencies.checked)
            command.push("--skip-deps")
        if (dryRun.checked)
            command.push("--dry-run")

        installing = true
        finished = false
        installProcess.exec(command)
    }

    Rectangle {
        anchors.fill: parent
        color: "#080808"

        Image {
            id: wallpaper
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.78, 720)
            height: Math.min(parent.height * 0.48, 340)
            source: Qt.resolvedUrl("../../assets/wall.webp")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: 0.9
        }

        Rectangle {
            anchors.fill: parent
            color: "#c9080808"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        anchors.topMargin: 34
        anchors.bottomMargin: 30
        spacing: 18

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "H Y P R M O N O"
                color: "#f4f4f4"
                font.pixelSize: 15
                font.letterSpacing: 3
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Label {
                text: "INSTALLER"
                color: "#929292"
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }

        Item { Layout.fillHeight: true }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 620
            Layout.fillWidth: true
            spacing: 14

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.finished
                    ? (root.succeeded ? "Installation finished" : "Installation needs attention")
                    : "A quieter desktop, built around you."
                color: "#ffffff"
                font.pixelSize: 28
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Label {
                Layout.fillWidth: true
                text: root.installing
                    ? "The installer is running in a terminal. Review its log and approve each cleanup action there."
                    : root.finished
                        ? (root.succeeded
                            ? "The installer completed successfully. You can close this window."
                            : "The installer exited with an error. Check the terminal output before trying again.")
                        : "Choose a profile, then continue in the terminal for detailed logs and explicit cleanup approval."
                color: "#c0c0c0"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 12
                radius: 12
                color: "#b80d0d0d"
                border.color: "#45ffffff"
                border.width: 1
                implicitHeight: options.implicitHeight + 32

                ColumnLayout {
                    id: options
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    ComboBox {
                        id: profileSelector
                        Layout.fillWidth: true
                        model: ["Minimal", "Standard", "Extended", "Custom"]
                        currentIndex: 0
                        enabled: !root.installing
                    }

                    CheckBox {
                        id: reviewCleanup
                        text: "Scan for existing desktop components and ask before each removal"
                        checked: true
                        enabled: !root.installing
                    }

                    CheckBox {
                        id: dryRun
                        text: "Preview only (make no installation changes)"
                        checked: false
                        enabled: !root.installing
                    }

                    CheckBox {
                        id: skipDependencies
                        text: "Skip system and AUR dependency installation"
                        checked: false
                        enabled: !root.installing
                    }
                }
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                text: root.installing ? "Installation running…" : root.finished ? "Close" : "Start installation"
                enabled: !root.installing
                onClicked: {
                    if (root.finished)
                        root.close()
                    else
                        root.startInstallation()
                }
            }
        }

        Item { Layout.fillHeight: true }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "LIGHTWEIGHT  ·  MODULAR  ·  USER-CONTROLLED"
            color: "#888888"
            font.pixelSize: 10
            font.letterSpacing: 1.6
        }
    }

    Rectangle {
        id: progressTrack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        color: "#373737"

        Rectangle {
            id: progressLine
            width: root.installing ? Math.max(100, parent.width * 0.24) : (root.succeeded ? parent.width : 0)
            height: parent.height
            color: root.finished && !root.succeeded ? "#c95c5c" : "#f2f2f2"

            SequentialAnimation on x {
                running: root.installing
                loops: Animation.Infinite
                onRunningChanged: {
                    if (!running)
                        progressLine.x = 0
                }
                NumberAnimation {
                    from: -progressLine.width
                    to: progressTrack.width
                    duration: 1500
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
