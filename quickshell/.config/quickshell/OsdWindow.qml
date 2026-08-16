import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Centered bottom OSD; shown via Osd.visible (LazyLoader in shell).
PanelWindow {
    margins.bottom: Math.round((screen ? screen.height : 1080) * 0.14)
    exclusiveZone: 0
    implicitHeight: 72
    color: "transparent"

    anchors {
        left: true
        right: true
        bottom: true
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 300
        height: 64

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Colors.mantle
            border.color: Colors.surface1
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Text {
                    text: Osd.icon
                    color: Osd.accent
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 22
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    Text {
                        text: Osd.caption
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: 4
                        color: Colors.surface0

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (Osd.value / 100)
                            radius: parent.radius
                            color: Osd.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 120
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    mask: Region {
    }

}
