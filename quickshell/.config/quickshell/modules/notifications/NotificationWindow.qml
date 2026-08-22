import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: win

    color: "transparent"
    exclusiveZone: 0
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Notifications.close()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Notifications.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(17 / 255, 17 / 255, 27 / 255, 0.62)
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.14)
        width: Math.min(480, parent.width - 48)
        height: Math.min(560, parent.height - 96)
        radius: 16
        color: Colors.mantle
        border.color: Colors.surface0
        border.width: 1
        clip: true
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                Notifications.close();
                event.accepted = true;
            }
        }
        Component.onCompleted: forceActiveFocus()

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "󰂚"
                    color: Colors.mauve
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontIcon
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Notifications"
                        color: Colors.text
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontTitle
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: Notifications.count === 0 ? "You're up to date" : (Notifications.count === 1 ? "1 in history" : Notifications.count + " in history")
                        color: Colors.overlay0
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontCaption
                    }

                }

                Rectangle {
                    visible: Notifications.count > 0
                    implicitWidth: clearLabel.implicitWidth + 16
                    implicitHeight: 28
                    radius: Tokens.buttonRadius
                    color: clearHover.hovered ? Colors.surface1 : Colors.surface0

                    HoverHandler {
                        id: clearHover
                    }

                    Text {
                        id: clearLabel

                        anchors.centerIn: parent
                        text: "Clear all"
                        color: Colors.red
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontCaption
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.clearAll()
                    }

                }

            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: Notifications.items

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No notifications"
                    color: Colors.overlay0
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontTitle
                }

                delegate: NotificationCard {
                    width: list.width
                    compact: false
                }

            }

            Text {
                Layout.fillWidth: true
                text: "Esc  close    ✕  dismiss"
                color: Colors.overlay0
                font.family: Tokens.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }

        }

    }

}
