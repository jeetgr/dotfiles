import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string icon: ""
    property alias text: label.text
    property alias textColor: label.color
    property color iconColor: label.color
    property bool hovered: hoverHandler.hovered
    property bool flat: false
    property string tooltipText: ""
    default property alias contentData: content.data

    readonly property int hPad: flat ? 14 : 24

    implicitWidth: row.width + hPad
    implicitHeight: Tokens.pillHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    radius: flat ? 8 : Tokens.pillRadius
    color: flat ? "transparent" : Colors.surface0

    HoverHandler {
        id: hoverHandler
    }

    Tooltip {
        anchorItem: root
        text: root.tooltipText
        show: root.hovered && root.tooltipText.length > 0
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colors.surface1
        opacity: root.hovered ? 1 : 0
        z: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }

        }

    }

    Row {
        id: row

        z: 2
        anchors.centerIn: parent
        spacing: Tokens.rowGap

        Text {
            id: iconLabel

            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon.length > 0
            text: root.icon
            color: root.iconColor
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontIcon
        }

        Text {
            id: label

            anchors.verticalCenter: parent.verticalCenter
            visible: text.length > 0
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontLabel
            font.weight: Font.DemiBold
        }

    }

    Item {
        id: content

        z: 1
        anchors.fill: parent
    }

}
