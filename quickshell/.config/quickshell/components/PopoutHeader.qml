import QtQuick

Row {
    id: root

    property string icon: ""
    property color iconColor: Colors.text
    property string title: ""
    property string subtitle: ""
    property color titleColor: Colors.text
    property int iconSize: Tokens.fontIconLg

    spacing: 10

    Text {
        visible: root.icon.length > 0
        text: root.icon
        color: root.iconColor
        font.family: Tokens.fontFamily
        font.pixelSize: root.iconSize
        anchors.verticalCenter: parent.verticalCenter
    }

    Column {
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: root.title
            color: root.titleColor
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontTitle
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: Math.max(implicitWidth, 1)
        }

        Text {
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Colors.subtext0
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontCaption
            elide: Text.ElideRight
        }

    }

}
