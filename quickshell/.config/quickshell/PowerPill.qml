import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Power button → session menu (lock / logout / suspend / reboot / shutdown).
Pill {
    id: powerPill

    property bool menuOpen: false

    function runAction(action) {
        powerPill.menuOpen = false;
        switch (action) {
        case "lock":
            Quickshell.execDetached(["hyprlock"]);
            break;
        case "logout":
            Hyprland.dispatch("hl.dsp.exit()");
            break;
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }

    function maybeCloseMenu() {
        if (!powerPopout.popoutHovered && !powerPill.hovered)
            powerPill.menuOpen = false;

    }

    icon: "󰐥"
    text: ""
    textColor: Colors.red
    iconColor: textColor
    Layout.preferredWidth: 36

    Timer {
        id: closeTimer

        interval: 220
        onTriggered: powerPill.maybeCloseMenu()
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

        Text {
            text: "Power"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Repeater {
            model: [{
                "id": "lock",
                "label": "Lock",
                "glyph": "󰌾",
                "accent": Colors.sky
            }, {
                "id": "logout",
                "label": "Logout",
                "glyph": "󰍃",
                "accent": Colors.mauve
            }, {
                "id": "suspend",
                "label": "Suspend",
                "glyph": "󰒲",
                "accent": Colors.yellow
            }, {
                "id": "reboot",
                "label": "Reboot",
                "glyph": "󰜉",
                "accent": Colors.peach
            }, {
                "id": "shutdown",
                "label": "Shutdown",
                "glyph": "󰐥",
                "accent": Colors.red
            }]

            Rectangle {
                id: actionBtn

                required property var modelData

                width: 200
                height: 32
                radius: 8
                color: actionHover.hovered ? Colors.surface1 : Colors.surface0

                HoverHandler {
                    id: actionHover
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    spacing: 10

                    Text {
                        text: actionBtn.modelData.glyph
                        color: actionBtn.modelData.accent
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: actionBtn.modelData.label
                        color: actionBtn.modelData.accent
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerPill.runAction(actionBtn.modelData.id)
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }

                }

            }

        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: powerPill.menuOpen = !powerPill.menuOpen
    }

}
