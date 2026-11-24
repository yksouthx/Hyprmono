import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ApplicationWindow {
    id: root

    readonly property string dataFile: decodeURIComponent(
        Qt.resolvedUrl("../hypr/assets/emoji-data.txt").toString().replace(/^file:\/\//, "")
    )
    property var entries: []
    property string errorText: ""

    width: 620
    height: 680
    minimumWidth: 480
    minimumHeight: 420
    visible: true
    title: "HyprMono Emoji Picker"
    color: "#090909"

    Component.onCompleted: {
        loadEmojiData.exec(["cat", dataFile])
        search.forceActiveFocus()
    }

    function updateResults(query) {
        const needle = query.trim().toLowerCase()
        emojiModel.clear()
        for (const entry of entries) {
            if (needle === "" || entry.description.toLowerCase().includes(needle))
                emojiModel.append(entry)
        }
        results.currentIndex = emojiModel.count > 0 ? 0 : -1
    }

    function copyEmoji(value) {
        errorText = ""
        copyToClipboard.exec(["wl-copy", value])
    }

    Process {
        id: loadEmojiData

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = []
                for (const line of text.split("\n")) {
                    const parts = line.trim().split(/\s+/)
                    if (parts.length > 1)
                        root.entries.push({
                            emoji: parts[0],
                            description: parts.slice(1).join(" ")
                        })
                }
                root.updateResults(search.text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: root.errorText = text.trim()
        }

        onExited: (exitCode, exitStatus) => {
            if (exitStatus !== 0 || exitCode !== 0)
                root.errorText = "Could not load emoji data from " + root.dataFile
        }
    }

    Process {
        id: copyToClipboard

        stderr: StdioCollector {
            onStreamFinished: root.errorText = text.trim()
        }

        onExited: (exitCode, exitStatus) => {
            if (exitStatus === 0 && exitCode === 0)
                root.close()
            else if (root.errorText === "")
                root.errorText = "Copy failed. Check that wl-clipboard is installed."
        }
    }

    ListModel {
        id: emojiModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        Label {
            text: "EMOJI"
            color: "#f4f4f4"
            font.pixelSize: 13
            font.letterSpacing: 2
            font.weight: Font.DemiBold
        }

        TextField {
            id: search

            Layout.fillWidth: true
            placeholderText: "Search emoji"
            color: "#eeeeee"
            placeholderTextColor: "#888888"
            selectByMouse: true
            onTextChanged: root.updateResults(text)
            Keys.onDownPressed: {
                if (results.currentIndex < emojiModel.count - 1)
                    results.currentIndex += 1
            }
            Keys.onUpPressed: {
                if (results.currentIndex > 0)
                    results.currentIndex -= 1
            }
            Keys.onReturnPressed: {
                if (emojiModel.count > 0 && results.currentIndex >= 0)
                    root.copyEmoji(emojiModel.get(results.currentIndex).emoji)
            }
            Keys.onEscapePressed: root.close()
        }

        ListView {
            id: results

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: emojiModel
            spacing: 3

            delegate: ItemDelegate {
                required property string emoji
                required property string description

                width: results.width
                highlighted: ListView.isCurrentItem
                onClicked: root.copyEmoji(emoji)

                contentItem: RowLayout {
                    spacing: 14

                    Label {
                        text: emoji
                        color: "#ffffff"
                        font.pixelSize: 24
                    }

                    Label {
                        Layout.fillWidth: true
                        text: description
                        color: "#d0d0d0"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.errorText !== "" ? root.errorText : "Select an emoji to copy it."
            color: root.errorText !== "" ? "#ff8a80" : "#888888"
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}
