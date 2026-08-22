import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

PanelWindow {
    margins.bottom: Math.round((screen ? screen.height : 1080) * 0.14)
    exclusiveZone: 0
    implicitHeight: Osd.showMeter ? 72 : 56
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
        height: Osd.showMeter ? 64 : 48

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
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontIconLg
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Tokens.rowGap

                    Text {
                        text: Osd.caption
                        color: Colors.text
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontTitle
                        font.weight: Font.DemiBold
                    }

                    MeterBar {
                        visible: Osd.showMeter
                        Layout.fillWidth: true
                        barWidth: parent.width
                        value: Osd.value / 100
                        fill: Osd.accent
                    }

                    Text {
                        visible: !Osd.showMeter && Osd.detail.length > 0
                        Layout.fillWidth: true
                        text: Osd.detail
                        color: Colors.subtext0
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontCaption
                        elide: Text.ElideRight
                    }

                }

            }

        }

    }

    mask: Region {
    }

}
