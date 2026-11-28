import Quickshell
import Quickshell.Services.Mpris

Scope {
    id: root

    property bool mediaDashboardOpen: false
    property bool quickSettingsOpen: false
    property bool cavaVisualizerEnabled: false
    property var activePlayer: {
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying)
                return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    // One wallpaper surface and one bar per monitor (hot-plug aware).
    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }

    Variants {
        model: Quickshell.screens

        Bar {
            player: root.activePlayer
            cavaEnabled: root.cavaVisualizerEnabled
            dashboardOpen: root.mediaDashboardOpen
            onMediaClicked: root.mediaDashboardOpen = !root.mediaDashboardOpen
            onQuickSettingsClicked: root.quickSettingsOpen = !root.quickSettingsOpen
        }
    }

    // Overlays set no explicit screen, so the compositor places them on the
    // focused monitor.
    MediaDashboard {
        player: root.activePlayer
        visible: root.mediaDashboardOpen
        onDismissed: root.mediaDashboardOpen = false
    }

    QuickSettings {
        visible: root.quickSettingsOpen
        onDismissed: root.quickSettingsOpen = false
    }
}
