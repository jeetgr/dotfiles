import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Rectangle {
    id: root

    // Cap from shell so we never reach the centered clock.
    property real maxWidth: 220
    readonly property var player: {
        let all = Mpris.players.values || [];
        if (all.length === 0)
            return null;

        for (let i = 0; i < all.length; i++) {
            if (all[i].isPlaying)
                return all[i];

        }
        return all[0];
    }
    readonly property bool usable: {
        if (!player)
            return false;

        let state = player.playbackState;
        return state === MprisPlaybackState.Playing || state === MprisPlaybackState.Paused;
    }
    readonly property string labelText: {
        if (!player)
            return "";

        let title = (player.trackTitle || "").trim();
        let artist = (player.trackArtist || "").trim();
        if (title && artist)
            return artist + "  ·  " + title;

        return title || artist || (player.identity || "Media");
    }
    readonly property string playIcon: player && player.isPlaying ? "󰏤" : "󰐊"
    readonly property bool hovered: hoverHandler.hovered
    readonly property real labelMax: Math.max(40, maxWidth - 24 - 17 - 6)

    visible: usable && maxWidth > 64
    height: 28
    width: Math.min(contentRow.width + 24, maxWidth)
    radius: 14
    color: Colors.surface0
    clip: true

    HoverHandler {
        id: hoverHandler
    }

    Popout {
        id: mediaPopout

        anchorItem: root
        show: root.hovered || mediaPopout.popoutHovered
        borderColor: Colors.mauve

        Text {
            text: "Now playing"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Text {
            width: 240
            text: root.player ? (root.player.trackTitle || "Unknown track") : ""
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Column {
            spacing: 4
            width: 240

            Text {
                visible: root.player && (root.player.trackArtist || "").length > 0
                width: parent.width
                text: root.player ? root.player.trackArtist : ""
                color: Colors.mauve
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Text {
                visible: root.player && (root.player.trackAlbum || "").length > 0
                width: parent.width
                text: root.player ? root.player.trackAlbum : ""
                color: Colors.subtext0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!root.player)
                        return "";

                    let bits = [];
                    bits.push(root.player.isPlaying ? "Playing" : "Paused");
                    if (root.player.identity)
                        bits.push(root.player.identity);

                    return bits.join("  ·  ");
                }
                color: Colors.overlay0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
                elide: Text.ElideRight
            }

        }

        Row {
            spacing: 8

            Rectangle {
                width: 72
                height: 28
                radius: 8
                color: prevHover.hovered ? Colors.surface1 : Colors.surface0
                opacity: root.player && root.player.canGoPrevious ? 1 : 0.4

                HoverHandler {
                    id: prevHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: Colors.mauve
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player && root.player.canGoPrevious
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.previous()
                }

            }

            Rectangle {
                width: 72
                height: 28
                radius: 8
                color: playHover.hovered ? Colors.surface1 : Colors.surface0

                HoverHandler {
                    id: playHover
                }

                Text {
                    anchors.centerIn: parent
                    text: root.playIcon
                    color: Colors.mauve
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player && root.player.canTogglePlaying
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.togglePlaying()
                }

            }

            Rectangle {
                width: 72
                height: 28
                radius: 8
                color: nextHover.hovered ? Colors.surface1 : Colors.surface0
                opacity: root.player && root.player.canGoNext ? 1 : 0.4

                HoverHandler {
                    id: nextHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: Colors.mauve
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player && root.player.canGoNext
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.next()
                }

            }

        }

    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colors.surface1
        opacity: root.hovered ? 1 : 0
        z: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }

        }

    }

    Row {
        id: contentRow

        z: 2
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.playIcon
            color: Colors.mauve
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 17
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.labelMax)
            text: root.labelText
            color: Colors.mauve
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
            wrapMode: Text.NoWrap
            clip: true
        }

    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (!root.player)
                return ;

            if (mouse.button === Qt.MiddleButton) {
                if (root.player.canGoNext)
                    root.player.next();

                return ;
            }
            if (root.player.canTogglePlaying)
                root.player.togglePlaying();

        }
        onWheel: (event) => {
            if (!root.player)
                return ;

            if (event.angleDelta.y > 0) {
                if (root.player.canGoNext)
                    root.player.next();

            } else if (root.player.canGoPrevious) {
                root.player.previous();
            }
        }
    }

}
