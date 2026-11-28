import QtQuick
import Quickshell
import Quickshell.Wayland

// Desktop wallpaper on the background layer. A missing or unreadable image
// simply leaves the near-black fill. WebP decoding needs qt6-imageformats.
PanelWindow {
    required property var modelData

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "#050505"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "hyprmono-wallpaper"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../hypr/assets/wall.webp")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Decode at screen size instead of the full source resolution.
        sourceSize.width: Math.round(modelData.width * modelData.devicePixelRatio)
    }
}
