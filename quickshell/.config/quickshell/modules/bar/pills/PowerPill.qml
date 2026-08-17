import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Pill {
    id: powerPill

    function accentColor(name) {
        if (name === "sky")
            return Colors.sky;

        if (name === "mauve")
            return Colors.mauve;

        if (name === "yellow")
            return Colors.yellow;

        if (name === "peach")
            return Colors.peach;

        return Colors.red;
    }

    function runAction(action) {
        powerPill.menuOpen = false;
        PowerMenu.run(action);
    }

    property bool menuOpen: false

    icon: "󰐥"
    text: ""
    textColor: Colors.red
    iconColor: textColor
    Layout.preferredWidth: 36

    Timer {
        id: closeTimer

        interval: 220
        onTriggered: {
            if (!powerPopout.popoutHovered && !powerPill.hovered)
                powerPill.menuOpen = false;

        }
    }

    Popout {
        id: powerPopout

        anchorItem: powerPill
        show: powerPill.menuOpen || powerPopout.popoutHovered
        borderColor: Colors.red
        openDelayMs: 0
        onPopoutHoveredChanged: {
            if (!popoutHovered)
                closeTimer.restart();

        }

        PopoutTitle {
            text: "Power"
        }

        Repeater {
            model: PowerMenu.actions

            PopoutButton {
                required property var modelData

                text: modelData.label
                icon: modelData.glyph
                accent: powerPill.accentColor(modelData.accent)
                buttonWidth: 200
                buttonHeight: 32
                onClicked: powerPill.runAction(modelData.id)
            }

        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: powerPill.menuOpen = !powerPill.menuOpen
    }

}
