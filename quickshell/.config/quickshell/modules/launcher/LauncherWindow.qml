import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
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
        onClicked: Launcher.close()
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
        width: Math.min(620, parent.width - 48)
        height: Math.min(520, parent.height - 96)
        radius: 16
        color: Colors.mantle
        border.color: Colors.surface0
        border.width: 1
        clip: true
        Component.onCompleted: searchField.forceActiveFocus()
        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => {
                return searchField.forceActiveFocus();
            });

        }

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => {
                return mouse.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 12
                color: Colors.surface0
                border.color: searchField.activeFocus ? Launcher.modeColor : Colors.surface1
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: Launcher.modeGlyph
                        color: Launcher.modeColor
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontIcon
                    }

                    TextField {
                        id: searchField

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: Launcher.placeholder
                        placeholderTextColor: Colors.overlay0
                        color: Colors.text
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontLabel
                        focus: true
                        text: Launcher.query
                        onTextChanged: {
                            if (Launcher.query !== text)
                                Launcher.query = text;

                            Launcher.selectedIndex = 0;
                        }
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                Launcher.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                Launcher.moveSelection(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_Backtab)) {
                                Launcher.moveSelection(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                Launcher.activateSelected();
                                event.accepted = true;
                            } else if (Launcher.mode === "clip" && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
                                Launcher.pinSelected();
                                event.accepted = true;
                            } else if (Launcher.mode === "clip" && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_D) {
                                Launcher.deleteSelected();
                                event.accepted = true;
                            }
                        }

                        background: Item {
                        }

                    }

                    Rectangle {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: modeTag.implicitWidth + 14
                        radius: 8
                        color: Colors.base

                        Text {
                            id: modeTag

                            anchors.centerIn: parent
                            text: Launcher.modeLabel
                            color: Launcher.modeColor
                            font.family: Tokens.fontFamily
                            font.pixelSize: Tokens.fontCaption
                            font.weight: Font.DemiBold
                        }

                    }

                }

            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: Launcher.results
                currentIndex: Launcher.selectedIndex
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 80
                keyNavigationEnabled: false

                Connections {
                    function onSelectedIndexChanged() {
                        list.currentIndex = Launcher.selectedIndex;
                        list.positionViewAtIndex(Launcher.selectedIndex, ListView.Contain);
                    }

                    target: Launcher
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: Launcher.mode === "clip" ? "Clipboard is empty" : (Launcher.mode === "windows" ? "No open windows" : "No matches")
                    color: Colors.overlay0
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontTitle
                }

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool isClip: modelData && modelData.kind === "clip"
                    readonly property bool isImage: !!(isClip && modelData.isImage)

                    width: list.width
                    height: isImage ? 68 : 48
                    radius: 10
                    color: index === Launcher.selectedIndex ? Colors.surface1 : "transparent"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: row.modelData.kind === "hint" ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onEntered: Launcher.selectedIndex = row.index
                        onClicked: Launcher.activate(row.modelData)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Item {
                                Layout.preferredWidth: row.isImage ? 72 : 28
                                Layout.preferredHeight: row.isImage ? 48 : 28

                                Image {
                                    id: thumb

                                    anchors.fill: parent
                                    visible: row.isImage && status === Image.Ready
                                    source: {
                                        let _rev = Launcher.thumbRev;
                                        let path = (row.modelData && row.modelData.thumbPath) || "";
                                        if (!path.length)
                                            return "";

                                        return "file://" + path;
                                    }
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    mipmap: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: row.isImage && thumb.status !== Image.Ready
                                    text: "󰋩"
                                    color: Launcher.modeColor
                                    font.family: Tokens.fontFamily
                                    font.pixelSize: Tokens.fontIcon
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    visible: !row.isImage && !!(row.modelData.icon && row.modelData.icon.length)
                                    source: {
                                        let icon = row.modelData.icon || "";
                                        if (!icon.length)
                                            return "";

                                        if (Quickshell.hasThemeIcon(icon))
                                            return Quickshell.iconPath(icon);

                                        return Quickshell.iconPath(icon, "application-x-executable");
                                    }
                                    implicitSize: 28
                                    mipmap: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !row.isImage && !(row.modelData.icon && row.modelData.icon.length)
                                    text: row.modelData.glyph || "󰘔"
                                    color: Launcher.modeColor
                                    font.family: Tokens.fontFamily
                                    font.pixelSize: Tokens.fontIcon
                                }

                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.title || ""
                                    color: Colors.text
                                    font.family: Tokens.fontFamily
                                    font.pixelSize: Tokens.fontTitle
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: !!(row.modelData.subtitle && row.modelData.subtitle.length)
                                    text: row.modelData.subtitle || ""
                                    color: row.modelData.pinned ? Colors.peach : Colors.overlay0
                                    font.family: Tokens.fontFamily
                                    font.pixelSize: Tokens.fontCaption
                                    elide: Text.ElideRight
                                }

                            }

                            Text {
                                visible: row.isClip
                                text: row.modelData.pinned ? "󰐃" : "󰤱"
                                color: row.modelData.pinned ? Colors.peach : Colors.overlay0
                                font.family: Tokens.fontFamily
                                font.pixelSize: Tokens.fontIcon
                                Layout.alignment: Qt.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        Launcher.togglePin(row.modelData);
                                    }
                                }

                            }

                            Text {
                                visible: row.isClip
                                text: "󰆴"
                                color: Colors.overlay0
                                font.family: Tokens.fontFamily
                                font.pixelSize: Tokens.fontIcon
                                Layout.alignment: Qt.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        Launcher.deleteClip(row.modelData);
                                    }
                                }

                            }

                        }

                    }

                }

            }

            Text {
                Layout.fillWidth: true
                text: Launcher.mode === "clip" ? "↑↓  move    Enter  copy    Ctrl+P  pin    Ctrl+D  delete    Esc  close" : (Launcher.mode === "windows" ? "↑↓  move    Enter  focus    Esc  close" : "↑↓  move    Enter  select    Esc  close    > run    ; clip    = calc    : power    # windows")
                color: Colors.overlay0
                font.family: Tokens.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }

        }

    }

}
