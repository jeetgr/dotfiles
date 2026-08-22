import QtQuick
import Quickshell
import Quickshell.Hyprland
pragma Singleton

QtObject {
    function classOf(t) {
        if (!t)
            return "";

        if (t.lastIpcObject && t.lastIpcObject.class)
            return String(t.lastIpcObject.class);

        if (t.wayland && t.wayland.appId)
            return String(t.wayland.appId);

        return "";
    }

    function titleOf(t) {
        if (!t)
            return "";

        return t.title || (t.wayland && t.wayland.title) || (t.lastIpcObject && t.lastIpcObject.title) || "";
    }

    function iconForClass(cls) {
        if (!cls)
            return Quickshell.iconPath("application-x-executable");

        if (Quickshell.hasThemeIcon(cls))
            return Quickshell.iconPath(cls);

        let lower = cls.toLowerCase();
        if (Quickshell.hasThemeIcon(lower))
            return Quickshell.iconPath(lower);

        let shortName = lower.split(".").pop();
        if (shortName && Quickshell.hasThemeIcon(shortName))
            return Quickshell.iconPath(shortName);

        return Quickshell.iconPath(cls, "application-x-executable");
    }

    function iconForToplevel(t) {
        return iconForClass(classOf(t));
    }

    function addressOf(t) {
        if (!t)
            return "";

        let addr = t.address || "";
        if (!addr.length && t.lastIpcObject && t.lastIpcObject.address)
            addr = String(t.lastIpcObject.address);

        addr = String(addr).replace(/^0x/i, "");
        return addr;
    }

    function workspaceLabel(t) {
        if (!t || !t.workspace)
            return "";

        let name = t.workspace.name || "";
        if (name.indexOf("special") === 0)
            return "scratchpad";

        let id = t.workspace.id;
        if (id !== undefined && id !== null && id > 0)
            return "ws " + id;

        return name || "";
    }

    function isShellWindow(t) {
        let cls = classOf(t).toLowerCase();
        return cls === "quickshell" || cls.indexOf("quickshell") >= 0;
    }

    function selector(t) {
        let addr = addressOf(t);
        if (!addr.length)
            return "";

        return "address:0x" + addr;
    }

    function collectWindows(wsId, hyprWorkspace) {
        let windows = [];
        let seen = {
        };

        function addWindow(t) {
            if (!t)
                return ;

            let title = titleOf(t);
            let cls = classOf(t);
            let key = (cls || "") + "|" + (title || "");
            if (seen[key])
                return ;

            seen[key] = true;
            windows.push({
                "title": title,
                "className": cls,
                "icon": iconForToplevel(t)
            });
        }
        if (hyprWorkspace && hyprWorkspace.toplevels) {
            let list = hyprWorkspace.toplevels.values || [];
            for (let i = 0; i < list.length; i++) addWindow(list[i])
        }
        if (windows.length === 0 && Hyprland.toplevels) {
            let all = Hyprland.toplevels.values || [];
            for (let i = 0; i < all.length; i++) {
                let t = all[i];
                if (t.workspace && t.workspace.id === wsId)
                    addWindow(t);

            }
        }
        return windows;
    }

}
