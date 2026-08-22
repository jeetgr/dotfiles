import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services

PanelWindow {
    exclusiveZone: 0
    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }

    margins {
        top: Tokens.barHeight + 16
        right: 12
    }

    Column {
        id: column

        width: 380
        spacing: 8

        Repeater {
            model: Notifications.popups

            NotificationCard {
                id: toast

                compact: true

                Timer {
                    interval: Notifications.toastInterval(toast.n)
                    running: interval > 0
                    onTriggered: Notifications.hidePopup(toast.n)
                }

            }

        }

    }

}
