import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Rectangle {
    id: root

    Layout.preferredHeight: 28
    Layout.preferredWidth: row.implicitWidth + 24
    radius: 14
    color: Colors.surface0
    visible: row.implicitWidth > 0

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

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
                    opacity: trayItem.isPassive ? 0.45 : 1.0

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

    }

}
