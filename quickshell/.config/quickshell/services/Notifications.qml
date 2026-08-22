import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.services
pragma Singleton

QtObject {
    id: root

    property bool visible: false
    property int unread: 0
    property var items: []
    property var popups: []
    readonly property int count: items.length
    readonly property int popupCount: popups.length

    property NotificationServer server: NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => root.ingest(n)
    }

    function ingest(n) {
        n.tracked = true;
        n.closed.connect(() => root.drop(n));
        root.items = [n].concat(root.items);

        while (root.items.length > 50) {
            let oldest = root.items[root.items.length - 1];
            if (!oldest)
                break;
            oldest.expire();
        }

        if (n.lastGeneration)
            return;

        if (root.visible) {
            root.unread = 0;
            return;
        }

        root.unread += 1;
        root.popups = [n].concat(root.popups).slice(0, 4);
    }

    function drop(n) {
        root.items = root.items.filter(x => x !== n);
        root.popups = root.popups.filter(x => x !== n);
        root.unread = Math.min(root.unread, root.items.length);
    }

    function hidePopup(n) {
        root.popups = root.popups.filter(x => x !== n);
        if (n && n.transient)
            n.expire();
    }

    function dismiss(n) {
        if (n)
            n.dismiss();
    }

    function clearAll() {
        let copy = root.items.slice();
        for (let i = 0; i < copy.length; i++) {
            if (copy[i])
                copy[i].dismiss();
        }
        root.unread = 0;
        root.popups = [];
    }

    function open() {
        Launcher.close();
        Cheatsheet.close();
        root.popups = [];
        root.unread = 0;
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    function toggle() {
        if (root.visible)
            root.close();
        else
            root.open();
    }

    function toastInterval(n) {
        if (!n)
            return 5000;

        if (n.urgency === NotificationUrgency.Critical)
            return 8000;

        let t = n.expireTimeout;
        if (t === 0)
            return 0;
        if (t < 0)
            return 5000;
        if (t < 100)
            return Math.round(t * 1000);
        return Math.min(15000, Math.round(t));
    }

    function accent(n) {
        if (!n)
            return Colors.mauve;
        if (n.urgency === NotificationUrgency.Critical)
            return Colors.red;
        if (n.urgency === NotificationUrgency.Low)
            return Colors.overlay0;
        return Colors.mauve;
    }

    function iconSource(n) {
        if (!n)
            return "";
        if (n.image && n.image.length)
            return n.image;
        if (n.appIcon && n.appIcon.length) {
            if (n.appIcon.indexOf("/") >= 0 || n.appIcon.indexOf(":") >= 0)
                return n.appIcon;
            return Quickshell.iconPath(n.appIcon, "application-x-executable");
        }
        return "";
    }

    function appLabel(n) {
        if (!n)
            return "Notification";
        return n.appName || n.desktopEntry || "Notification";
    }

}
