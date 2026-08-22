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
        onClicked: Cheatsheet.close()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Cheatsheet.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(17 / 255, 17 / 255, 27 / 255, 0.62)
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.1)
        width: Math.min(620, parent.width - 48)
        height: Math.min(640, parent.height - 72)
        radius: 16
        color: Colors.mantle
        border.color: Colors.surface0
        border.width: 1
        clip: true
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Question) {
                Cheatsheet.close();
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
                    text: "󰘳"
                    color: Colors.mauve
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontIcon
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Keybinds"
                        color: Colors.text
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontTitle
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Hyprland Lua  ·  Super+? again to close"
                        color: Colors.overlay0
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontCaption
                    }

                }

            }

            Flickable {
                id: flick

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: body.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: body

                    width: flick.width
                    spacing: 16

                    Repeater {
                        model: Cheatsheet.groups

                        Column {
                            required property var modelData

                            width: body.width
                            spacing: 6

                            Text {
                                text: modelData.title
                                color: modelData.accent
                                font.family: Tokens.fontFamily
                                font.pixelSize: Tokens.fontCaption
                                font.weight: Font.DemiBold
                            }

                            Repeater {
                                model: modelData.binds

                                RowLayout {
                                    required property var modelData

                                    width: body.width
                                    spacing: 12

                                    Text {
                                        text: modelData.keys
                                        color: Colors.subtext0
                                        font.family: Tokens.fontFamily
                                        font.pixelSize: Tokens.fontBody
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.action
                                        color: Colors.text
                                        font.family: Tokens.fontFamily
                                        font.pixelSize: Tokens.fontBody
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }

                                }

                            }

                        }

                    }

                }

            }

            Text {
                Layout.fillWidth: true
                text: "Esc  close    Super+?  toggle"
                color: Colors.overlay0
                font.family: Tokens.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }

        }

    }

}
