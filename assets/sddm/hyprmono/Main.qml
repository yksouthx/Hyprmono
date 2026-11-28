import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#000000"

    Image {
        anchors.fill: parent
        source: "wall.webp"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.58
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM d  -  hh:mm")
    }

    Text {
        id: clock
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 32
        anchors.rightMargin: 36
        color: "#FFFFFF"
        font.family: "Noto Sans"
        font.pixelSize: 18
        font.bold: true
    }

    Rectangle {
        width: Math.min(parent.width * 0.38, 440)
        height: 390
        anchors.centerIn: parent
        radius: 18
        color: "#111111"
        opacity: 0.94
        border.width: 1
        border.color: "#444444"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 14

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "HYPRMONO"
                color: "#FFFFFF"
                font.family: "NType82Mono"
                font.pixelSize: 32
                font.bold: true
                font.letterSpacing: 5
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome"
                color: "#CCCCCC"
                font.family: "Noto Sans"
                font.pixelSize: 15
            }

            TextField {
                id: username
                Layout.fillWidth: true
                text: sddm.lastUser
                placeholderText: "Username"
                color: "#FFFFFF"
                placeholderTextColor: "#777777"
                font.pixelSize: 16
                leftPadding: 14
                rightPadding: 14
                implicitHeight: 48
                background: Rectangle {
                    radius: 10
                    color: "#090909"
                    border.width: 1
                    border.color: username.activeFocus ? "#CCCCCC" : "#444444"
                }
                Keys.onReturnPressed: password.forceActiveFocus()
            }

            TextField {
                id: password
                Layout.fillWidth: true
                placeholderText: "Password"
                echoMode: TextInput.Password
                color: "#FFFFFF"
                placeholderTextColor: "#777777"
                font.pixelSize: 16
                leftPadding: 14
                rightPadding: 14
                implicitHeight: 48
                background: Rectangle {
                    radius: 10
                    color: "#090909"
                    border.width: 1
                    border.color: password.activeFocus ? "#CCCCCC" : "#444444"
                }
                Keys.onReturnPressed: login()
            }

            ComboBox {
                id: session
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: sddm.currentSessionIndex
                implicitHeight: 44
            }

            Text {
                id: status
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: ""
                color: "#FFFFFF"
                font.pixelSize: 13
                height: 18
            }

            Button {
                Layout.fillWidth: true
                implicitHeight: 46
                text: "Sign in"
                onClicked: login()
                contentItem: Text {
                    text: parent.text
                    color: "#000000"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                background: Rectangle {
                    radius: 10
                    color: parent.hovered ? "#FFFFFF" : "#CCCCCC"
                    border.width: 1
                    border.color: "#FFFFFF"
                }
            }
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 24
        anchors.rightMargin: 28
        spacing: 10

        Button {
            text: "Suspend"
            visible: sddm.canSuspend
            onClicked: sddm.suspend()
        }
        Button {
            text: "Reboot"
            visible: sddm.canReboot
            onClicked: sddm.reboot()
        }
        Button {
            text: "Power off"
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            status.text = "Login failed"
            password.text = ""
            password.forceActiveFocus()
        }
        function onLoginSucceeded() {
            status.text = "Signing in..."
        }
    }

    function login() {
        if (username.text.length === 0) {
            status.text = "Enter a username"
            username.forceActiveFocus()
            return
        }
        status.text = "Signing in..."
        sddm.login(username.text, password.text, session.currentIndex)
    }

    Component.onCompleted: {
        if (username.text.length > 0)
            password.forceActiveFocus()
        else
            username.forceActiveFocus()
    }
}
