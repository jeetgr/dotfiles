import QtQuick
import Quickshell
import Quickshell.Hyprland
pragma Singleton

QtObject {
    id: root

    property bool visible: false
    property int selectedIndex: 0
    property string query: ""
    readonly property var actions: [{
            "id": "lock",
            "label": "Lock",
            "glyph": "󰌾",
            "accent": "sky"
        }, {
            "id": "logout",
            "label": "Logout",
            "glyph": "󰍃",
            "accent": "mauve"
        }, {
            "id": "suspend",
            "label": "Suspend",
            "glyph": "󰒲",
            "accent": "yellow"
        }, {
            "id": "reboot",
            "label": "Reboot",
            "glyph": "󰜉",
            "accent": "peach"
        }, {
            "id": "shutdown",
            "label": "Shutdown",
            "glyph": "󰐥",
            "accent": "red"
        }]
    readonly property var filtered: {
        let q = root.query.trim().toLowerCase();
        if (!q.length)
            return root.actions;

        let out = [];
        for (let i = 0; i < root.actions.length; i++) {
            let a = root.actions[i];
            if ((a.label || "").toLowerCase().indexOf(q) !== -1 || (a.id || "").indexOf(q) !== -1)
                out.push(a);

        }
        return out;
    }

    function open() {
        root.query = "";
        root.selectedIndex = 0;
        root.visible = true;
    }

    function close() {
        root.visible = false;
        root.query = "";
        root.selectedIndex = 0;
    }

    function toggle() {
        if (root.visible)
            root.close();
        else
            root.open();

    }

    function moveSelection(delta) {
        let count = root.filtered.length;
        if (count === 0) {
            root.selectedIndex = 0;
            return ;
        }
        root.selectedIndex = (root.selectedIndex + delta + count) % count;
    }

    function activateSelected() {
        let items = root.filtered;
        if (items.length === 0)
            return ;

        let index = Math.max(0, Math.min(items.length - 1, root.selectedIndex));
        let action = items[index];
        if (action)
            root.run(action.id);

    }

    function run(action) {
        root.close();
        switch (action) {
        case "lock":
            Quickshell.execDetached(["hyprlock"]);
            break;
        case "logout":
            Hyprland.dispatch("hl.dsp.exit()");
            break;
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }

    onFilteredChanged: {
        if (root.selectedIndex >= root.filtered.length)
            root.selectedIndex = Math.max(0, root.filtered.length - 1);

    }

}
