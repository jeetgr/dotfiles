import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.components
pragma Singleton

QtObject {
    id: root

    property bool visible: false
    property bool ready: false
    property bool showMeter: true
    property string icon: "󰕾"
    property int value: 0
    property color accent: Colors.sky
    property string caption: ""
    property string detail: ""
    property bool lastCaps: false
    property bool capsSeen: false
    property string lastLayout: ""
    property string capsLedPath: ""
    property Timer hideTimer
    property Timer readyTimer
    property Process ledProbe
    property FileView capsLed
    property Timer capsPoll
    property Process clipWatch
    property Connections hyprEvents

    function push(icon, value, accent, caption) {
        root.showMeter = true;
        root.detail = "";
        root.icon = icon;
        root.value = Math.max(0, Math.min(100, Math.round(value)));
        root.accent = accent;
        root.caption = caption || (root.value + "%");
        root.visible = true;
        hideTimer.restart();
    }

    function pushStatus(icon, accent, caption, detail) {
        root.showMeter = false;
        root.icon = icon;
        root.value = 0;
        root.accent = accent;
        root.caption = caption;
        root.detail = detail || "";
        root.visible = true;
        hideTimer.restart();
    }

    function pushVolume(volume, muted, headphone) {
        let icons = ["󰕿", "󰖀", "󰕾"];
        let icon = "󰝟";
        if (!muted && volume > 0) {
            if (headphone)
                icon = "󰋋";
            else
                icon = icons[Math.min(2, Math.floor(volume / 100 * icons.length))];
        }
        push(icon, muted ? 0 : volume, muted ? Colors.overlay0 : Colors.sky, muted ? "muted" : (Math.round(volume) + "%"));
    }

    function pushBrightness(percent) {
        let icons = ["󰃚", "󰃛", "󰃜", "󰃝", "󰃞", "󰃟", "󰃠"];
        let index = Math.min(icons.length - 1, Math.floor(percent / 100 * icons.length));
        push(icons[index], percent, Colors.yellow, Math.round(percent) + "%");
    }

    function pushMic(volume, muted) {
        let icon = (muted || volume <= 0) ? "󰍭" : "󰍬";
        push(icon, muted ? 0 : volume, muted ? Colors.overlay0 : Colors.pink, muted ? "mic muted" : (Math.round(volume) + "%"));
    }

    function pushCaps(on) {
        pushStatus(on ? "󰪛" : "󰌎", on ? Colors.yellow : Colors.overlay0, "Caps lock", on ? "on" : "off");
    }

    function pushLayout(name) {
        let label = (name || "").trim();
        if (!label.length)
            return;
        pushStatus("󰌌", Colors.lavender, "Layout", label);
    }

    function pushCopied(preview, isImage) {
        if (isImage) {
            pushStatus("󰋩", Colors.peach, "Copied", "image");
            return;
        }
        let text = (preview || "").trim();
        pushStatus("󰆏", Colors.peach, "Copied", text.length ? text : "clipboard");
    }

    function handleCaps(on) {
        if (on === root.lastCaps)
            return;
        root.lastCaps = on;
        if (root.ready)
            root.pushCaps(on);
    }

    function handleLayout(name) {
        let label = (name || "").trim();
        if (!label.length || label === root.lastLayout)
            return;
        let first = root.lastLayout.length === 0;
        root.lastLayout = label;
        if (root.ready && !first)
            root.pushLayout(label);
    }

    function pollCaps() {
        capsLed.reload();
    }

    hideTimer: Timer {
        interval: 1400
        onTriggered: root.visible = false
    }

    readyTimer: Timer {
        interval: 600
        running: true
        repeat: false
        onTriggered: root.ready = true
    }

    ledProbe: Process {
        command: ["bash", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null | head -1"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                let dir = line.trim();
                if (dir.length)
                    root.capsLedPath = dir + "/brightness";
            }
        }
    }

    capsLed: FileView {
        path: root.capsLedPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let on = text().trim() === "1";
            if (!root.capsSeen) {
                root.lastCaps = on;
                root.capsSeen = true;
                return;
            }
            root.handleCaps(on);
        }
    }

    capsPoll: Timer {
        interval: 300
        running: root.capsLedPath.length > 0
        repeat: true
        onTriggered: capsLed.reload()
    }

    clipWatch: Process {
        command: ["wl-paste", "--watch", (Quickshell.env("HOME") || "/home/jeetgr") + "/.config/hypr/scripts/clip-osd.sh"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (!root.ready)
                    return;
                let s = (line || "").replace(/\n$/, "");
                if (s === "image") {
                    root.pushCopied("", true);
                    return;
                }
                if (s.indexOf("text:") === 0)
                    root.pushCopied(s.slice(5), false);
            }
        }
    }

    hyprEvents: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event || event.name !== "activelayout")
                return;
            let parts = event.parse(2);
            if (!parts || parts.length < 2)
                return;
            root.handleLayout(parts[1]);
        }
    }

}
