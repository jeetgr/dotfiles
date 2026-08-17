import QtQuick
import Quickshell.Services.Mpris
import qs.components

Rectangle {
    id: root

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
    height: Tokens.pillHeight
    width: Math.min(contentRow.width + 24, maxWidth)
    radius: Tokens.pillRadius
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

        PopoutTitle {
            text: "Now playing"
        }

        Text {
            width: Tokens.popoutWidthWide
            text: root.player ? (root.player.trackTitle || "Unknown track") : ""
            color: Colors.text
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontTitle
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Column {
            spacing: 4
            width: Tokens.popoutWidthWide

            Text {
                visible: root.player && (root.player.trackArtist || "").length > 0
                width: parent.width
                text: root.player ? root.player.trackArtist : ""
                color: Colors.mauve
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.fontBody
                elide: Text.ElideRight
            }

            Text {
                visible: root.player && (root.player.trackAlbum || "").length > 0
                width: parent.width
                text: root.player ? root.player.trackAlbum : ""
                color: Colors.subtext0
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.fontCaption
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!root.player)
                        return "";

                    let bits = [root.player.isPlaying ? "Playing" : "Paused"];
                    if (root.player.identity)
                        bits.push(root.player.identity);

                    return bits.join("  ·  ");
                }
                color: Colors.overlay0
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.fontCaption
                elide: Text.ElideRight
            }

        }

        Row {
            spacing: 8

            PopoutButton {
                icon: "󰒮"
                text: ""
                accent: Colors.mauve
                buttonWidth: 72
                enabled: !!(root.player && root.player.canGoPrevious)
                onClicked: {
                    if (root.player)
                        root.player.previous();

                }
            }

            PopoutButton {
                icon: root.playIcon
                text: ""
                accent: Colors.mauve
                buttonWidth: 72
                enabled: !!(root.player && root.player.canTogglePlaying)
                onClicked: {
                    if (root.player)
                        root.player.togglePlaying();

                }
            }

            PopoutButton {
                icon: "󰒭"
                text: ""
                accent: Colors.mauve
                buttonWidth: 72
                enabled: !!(root.player && root.player.canGoNext)
                onClicked: {
                    if (root.player)
                        root.player.next();

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
        spacing: Tokens.rowGap

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.playIcon
            color: Colors.mauve
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontIcon
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.labelMax)
            text: root.labelText
            color: Colors.mauve
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontLabel
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
