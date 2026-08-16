import QtQuick
pragma Singleton

QtObject {
    id: root

    property bool visible: false
    property string icon: "󰕾"
    property int value: 0
    property color accent: Colors.sky
    property string caption: ""
    property Timer hideTimer

    hideTimer: Timer {
        interval: 1400
        onTriggered: root.visible = false
    }

    function push(icon, value, accent, caption) {
        root.icon = icon;
        root.value = Math.max(0, Math.min(100, Math.round(value)));
        root.accent = accent;
        root.caption = caption || (root.value + "%");
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

}
