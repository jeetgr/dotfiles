import QtQuick

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property color accent: Colors.text
    property real buttonWidth: Tokens.popoutWidth
    property real buttonHeight: Tokens.pillHeight

    signal clicked()

    width: buttonWidth
    height: buttonHeight
    radius: Tokens.buttonRadius
    color: hover.hovered ? Colors.surface1 : Colors.surface0
    opacity: root.enabled ? 1 : 0.4

    HoverHandler {
        id: hover
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.accent
            font.family: Tokens.fontFamily
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.text.length > 0
            text: root.text
            color: root.accent
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontBody
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: 120
        }

    }

}
