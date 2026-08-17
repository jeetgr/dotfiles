import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    id: win

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
        onClicked: PowerMenu.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(17 / 255, 17 / 255, 27 / 255, 0.62)
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 280
        implicitHeight: column.implicitHeight + 28
        radius: 16
        color: Colors.mantle
        border.color: Colors.surface0
        border.width: 1
        Component.onCompleted: searchField.forceActiveFocus()

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => {
                return mouse.accepted = true;
            }
        }

        Column {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 8

            Rectangle {
                width: column.width
                height: 40
                radius: 12
                color: Colors.surface0
                border.color: searchField.activeFocus ? Colors.red : Colors.surface1
                border.width: 1

                TextField {
                    id: searchField

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    placeholderText: "Search…"
                    placeholderTextColor: Colors.overlay0
                    color: Colors.text
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontLabel
                    focus: true
                    text: PowerMenu.query
                    onTextChanged: {
                        if (PowerMenu.query !== text)
                            PowerMenu.query = text;

                        PowerMenu.selectedIndex = 0;
                    }
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            PowerMenu.close();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            PowerMenu.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            PowerMenu.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            PowerMenu.activateSelected();
                            event.accepted = true;
                        }
                    }

                    background: Item {
                    }

                }

            }

            Repeater {
                model: PowerMenu.filtered

                Rectangle {
                    required property var modelData
                    required property int index

                    width: column.width
                    height: 40
                    radius: 10
                    color: index === PowerMenu.selectedIndex ? Colors.surface1 : "transparent"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        spacing: 10

                        Text {
                            text: modelData.glyph
                            color: win.accentColor(modelData.accent)
                            font.family: Tokens.fontFamily
                            font.pixelSize: Tokens.fontIcon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.label
                            color: Colors.text
                            font.family: Tokens.fontFamily
                            font.pixelSize: Tokens.fontTitle
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: PowerMenu.selectedIndex = index
                        onClicked: PowerMenu.run(modelData.id)
                    }

                }

            }

            Text {
                visible: PowerMenu.filtered.length === 0
                width: column.width
                text: "No matches"
                color: Colors.overlay0
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.fontCaption
                horizontalAlignment: Text.AlignHCenter
            }

        }

    }

}
