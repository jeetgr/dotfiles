import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Pill {
    id: powerPill

    icon: "󰐥"
    text: ""
    textColor: Colors.red
    iconColor: textColor
    Layout.preferredWidth: 36

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: PowerMenu.toggle()
    }

}
