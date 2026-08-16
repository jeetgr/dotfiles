import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Rectangle {
    id: root

    // Collapse behind a chevron once the tray gets crowded.
    property int compactThreshold: 3
    property bool expanded: false
    readonly property int itemCount: SystemTray.items.values ? SystemTray.items.values.length : 0
    readonly property bool compact: itemCount > compactThreshold
    readonly property bool showIcons: !compact || expanded
    readonly property bool hasAttention: {
        let items = SystemTray.items.values || [];
        for (let i = 0; i < items.length; i++) {
            if (items[i].status === Status.NeedsAttention)
                return true;

        }
        return false;
    }

    Layout.preferredHeight: 28
    Layout.preferredWidth: row.implicitWidth + 24
    radius: 14
    color: Colors.surface0
    visible: itemCount > 0
    // Auto-collapse when tray shrinks below threshold.
    onCompactChanged: {
        if (!compact)
            expanded = false;

    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.showIcons ? SystemTray.items : []

            Item {
                id: trayItem

                required property var modelData
                readonly property bool isPassive: modelData.status === Status.Passive
                readonly property bool needsAttention: modelData.status === Status.NeedsAttention

                Layout.preferredWidth: 22
                Layout.preferredHeight: 22

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 6
                    color: Colors.red
                    visible: trayItem.needsAttention
                    opacity: 0.9
                }

                Image {
                    id: trayIcon

                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: trayItem.modelData.icon
                    smooth: true
                    opacity: trayItem.isPassive ? 0.45 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }

                    }

                }

                QsMenuAnchor {
                    id: menuAnchor

                    menu: trayItem.modelData.menu
                    anchor.window: trayItem.QsWindow.window
                    anchor.rect.x: trayItem.QsWindow.window ? trayItem.mapToItem(trayItem.QsWindow.window.contentItem, 0, 0).x : 0
                    anchor.rect.y: trayItem.QsWindow.window ? trayItem.mapToItem(trayItem.QsWindow.window.contentItem, 0, 0).y : 0
                    anchor.rect.width: trayItem.width
                    anchor.rect.height: trayItem.height
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton)
                            menuAnchor.open();
                        else
                            trayItem.modelData.activate();
                    }
                }

            }

        }

        // Chevron when compact (or always shown while expanded so you can collapse).
        Item {
            id: chevronBtn

            visible: root.compact
            Layout.preferredWidth: visible ? 18 : 0
            Layout.preferredHeight: 22

            Text {
                anchors.centerIn: parent
                text: root.expanded ? "󰅃" : "󰅀"
                color: root.hasAttention && !root.expanded ? Colors.red : Colors.subtext0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 16

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }

                }

            }

            // Attention dot when collapsed.
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -1
                anchors.topMargin: 1
                width: 6
                height: 6
                radius: 3
                color: Colors.red
                visible: root.hasAttention && !root.expanded
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }

            Popout {
                id: trayPopout

                anchorItem: chevronBtn
                show: !root.expanded && root.compact && (chevronHover.hovered || trayPopout.popoutHovered)
                borderColor: Colors.overlay1

                Text {
                    text: "System tray"
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.itemCount + (root.itemCount === 1 ? " item" : " items") + (root.hasAttention ? "  ·  attention" : "")
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Flow {
                    width: Math.min(220, Math.max(1, root.itemCount) * 28)
                    spacing: 8

                    Repeater {
                        model: SystemTray.items

                        Item {
                            id: popTrayItem

                            required property var modelData
                            readonly property bool isPassive: modelData.status === Status.Passive
                            readonly property bool needsAttention: modelData.status === Status.NeedsAttention

                            width: 22
                            height: 22

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -2
                                radius: 6
                                color: Colors.red
                                visible: popTrayItem.needsAttention
                                opacity: 0.9
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                source: popTrayItem.modelData.icon
                                smooth: true
                                opacity: popTrayItem.isPassive ? 0.45 : 1
                            }

                            QsMenuAnchor {
                                id: popMenuAnchor

                                menu: popTrayItem.modelData.menu
                                anchor.window: chevronBtn.QsWindow ? chevronBtn.QsWindow.window : null
                                anchor.rect.x: 0
                                anchor.rect.y: 0
                                anchor.rect.width: popTrayItem.width
                                anchor.rect.height: popTrayItem.height
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton)
                                        popMenuAnchor.open();
                                    else
                                        popTrayItem.modelData.activate();
                                }
                            }

                        }

                    }

                }

                Text {
                    text: "Click chevron to pin open"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                }

            }

            HoverHandler {
                id: chevronHover
            }

        }

    }

    Behavior on Layout.preferredWidth {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }

    }

}
