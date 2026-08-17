import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.components

Rectangle {
    id: root

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

    Layout.preferredHeight: Tokens.pillHeight
    Layout.preferredWidth: row.implicitWidth + 24
    radius: Tokens.pillRadius
    color: Colors.surface0
    visible: itemCount > 0
    onCompactChanged: {
        if (!compact)
            expanded = false;

    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.rowGap

        Repeater {
            model: root.showIcons ? SystemTray.items : []

            TrayIcon {
            }

        }

        Item {
            id: chevronBtn

            visible: root.compact
            Layout.preferredWidth: visible ? 18 : 0
            Layout.preferredHeight: 22

            Text {
                anchors.centerIn: parent
                text: root.expanded ? "󰅃" : "󰅀"
                color: root.hasAttention && !root.expanded ? Colors.red : Colors.subtext0
                font.family: Tokens.fontFamily
                font.pixelSize: 16
            }

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

                PopoutTitle {
                    text: "System tray"
                }

                Text {
                    text: root.itemCount + (root.itemCount === 1 ? " item" : " items") + (root.hasAttention ? "  ·  attention" : "")
                    color: Colors.text
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontBody
                    font.weight: Font.DemiBold
                }

                Flow {
                    width: Math.min(Tokens.popoutWidth, Math.max(1, root.itemCount) * 28)
                    spacing: 8

                    Repeater {
                        model: SystemTray.items

                        TrayIcon {
                        }

                    }

                }

                Text {
                    text: "Click chevron to pin open"
                    color: Colors.overlay0
                    font.family: Tokens.fontFamily
                    font.pixelSize: 10
                }

            }

            HoverHandler {
                id: chevronHover
            }

        }

    }

    component TrayIcon: Item {
        id: trayIcon

        required property var modelData
        property var menuWindow: trayIcon.QsWindow ? trayIcon.QsWindow.window : null
        readonly property bool isPassive: modelData.status === Status.Passive
        readonly property bool needsAttention: modelData.status === Status.NeedsAttention

        width: 22
        height: 22
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: 6
            color: Colors.red
            visible: trayIcon.needsAttention
            opacity: 0.9
        }

        Image {
            anchors.centerIn: parent
            width: 18
            height: 18
            source: trayIcon.modelData.icon
            smooth: true
            opacity: trayIcon.isPassive ? 0.45 : 1
        }

        QsMenuAnchor {
            id: menuAnchor

            menu: trayIcon.modelData.menu
            anchor.window: trayIcon.menuWindow
            anchor.rect.x: trayIcon.menuWindow ? trayIcon.mapToItem(trayIcon.menuWindow.contentItem, 0, 0).x : 0
            anchor.rect.y: trayIcon.menuWindow ? trayIcon.mapToItem(trayIcon.menuWindow.contentItem, 0, 0).y : 0
            anchor.rect.width: trayIcon.width
            anchor.rect.height: trayIcon.height
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton)
                    menuAnchor.open();
                else
                    trayIcon.modelData.activate();
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
