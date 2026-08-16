import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    // Material Design icons render small in Nerd Fonts — draw them larger than the label.
    property string icon: ""
    property alias text: label.text
    property alias textColor: label.color
    property color iconColor: label.color
    property bool hovered: hoverHandler.hovered
    property string tooltipText: ""

    default property alias contentData: content.data

    Layout.preferredWidth: row.width + 24
    Layout.preferredHeight: 28
    radius: 14
    color: Colors.surface0

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
        spacing: 6

        Text {
            id: iconLabel

            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon.length > 0
            text: root.icon
            color: root.iconColor
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 17
            font.weight: Font.Normal
        }

        Text {
            id: label

            anchors.verticalCenter: parent.verticalCenter
            visible: text.length > 0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

    }

    Item {
        id: content

        z: 1
        anchors.fill: parent
    }

}
