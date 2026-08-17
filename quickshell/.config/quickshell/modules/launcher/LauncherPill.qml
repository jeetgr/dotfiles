import QtQuick
import qs.components
import qs.services

Pill {
    id: launcherPill

    icon: "󰀻"
    text: "apps"
    textColor: Colors.mauve
    iconColor: textColor

    Popout {
        id: tip

        anchorItem: launcherPill
        show: launcherPill.hovered || tip.popoutHovered
        borderColor: Colors.mauve

        PopoutTitle {
            text: "Launcher demo"
        }

        Text {
            width: Tokens.popoutWidth
            text: "Search apps, run commands, clipboard, and calculator."
            color: Colors.text
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontBody
            wrapMode: Text.Wrap
        }

        Text {
            width: Tokens.popoutWidth
            text: "Also: qs ipc call launcher toggle"
            color: Colors.overlay0
            font.family: Tokens.fontFamily
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Launcher.toggle()
    }

}
