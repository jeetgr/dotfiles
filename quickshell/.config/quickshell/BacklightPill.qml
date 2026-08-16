import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: backlightPill

    property int percent: 0
    property string brightnessIcon: {
        let icons = ["󰃚", "󰃛", "󰃜", "󰃝", "󰃞", "󰃟", "󰃠"];
        let index = Math.min(icons.length - 1, Math.floor(percent / 100 * icons.length));
        return icons[index];
    }

    function refresh() {
        backlightProcess.running = false;
        backlightProcess.running = true;
    }

    icon: brightnessIcon
    text: percent + "%"
    textColor: Colors.yellow
    iconColor: textColor

    Process {
        id: backlightProcess

        // Device-agnostic: "name,class,value,percent%,max"
        command: ["bash", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); print $4}'"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                let value = parseInt(line.trim(), 10);
                if (!isNaN(value))
                    backlightPill.percent = Math.max(0, Math.min(100, value));

            }
        }

    }

    Timer {
        interval: 750
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backlightPill.refresh()
    }

    Timer {
        id: quickRefresh

        interval: 80
        repeat: false
        onTriggered: backlightPill.refresh()
    }

    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                Quickshell.execDetached(["brightnessctl", "set", "5%+"]);
            else
                Quickshell.execDetached(["brightnessctl", "set", "5%-"]);
            quickRefresh.restart();
        }
    }

}
