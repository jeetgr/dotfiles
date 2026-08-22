import QtQuick
import qs.components
import qs.services

Pill {
    id: notifPill

    icon: Notifications.unread > 0 ? "󰂞" : "󰂚"
    text: Notifications.unread > 0 ? (Notifications.unread > 9 ? "9+" : String(Notifications.unread)) : ""
    textColor: Notifications.unread > 0 ? Colors.peach : Colors.overlay0
    iconColor: textColor
    tooltipText: Notifications.unread > 0 ? (Notifications.unread + " unread") : (Notifications.count > 0 ? "Notification history" : "No notifications")

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Notifications.clearAll();
                return;
            }
            Notifications.toggle();
        }
    }

}
