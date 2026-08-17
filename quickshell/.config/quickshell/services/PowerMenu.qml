import QtQuick
import Quickshell
import Quickshell.Hyprland
pragma Singleton

QtObject {
    id: root

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

    function run(action) {
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

}
