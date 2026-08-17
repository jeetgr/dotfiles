import QtQuick

Rectangle {
    id: root

    property real value: 0
    property color fill: Colors.green
    property int barWidth: Tokens.popoutWidth
    property int barHeight: 8

    implicitWidth: barWidth
    implicitHeight: barHeight
    width: barWidth
    height: barHeight
    radius: Math.round(barHeight / 2)
    color: Colors.surface0

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, root.value))
        radius: parent.radius
        color: root.fill
    }

}
