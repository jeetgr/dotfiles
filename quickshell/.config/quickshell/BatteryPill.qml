import QtQuick
import Quickshell.Io

Pill {
    id: batteryPill

    property int capacity: 0
    property bool charging: false
    property bool pluggedIn: false
    property bool isWarning: capacity <= 30 && !pluggedIn
    property bool isCritical: capacity <= 15 && !pluggedIn
    property color criticalFg: Colors.red
    property string timeLabel: ""

    icon: {
        let icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        let index = Math.min(9, Math.floor(capacity / 10));
        return charging ? "󰂄" : icons[index];
    }
    text: capacity + "%"
    textColor: isCritical ? criticalFg : (isWarning ? Colors.peach : (charging ? Colors.yellow : Colors.green))
    iconColor: textColor
    tooltipText: {
        let state = charging ? "Charging" : (pluggedIn ? "Plugged in" : "Discharging");
        if (timeLabel.length > 0)
            return state + "\n" + timeLabel;
        return state + "\nTime remaining: unavailable";
    }

    Process {
        id: batteryProcess

        property bool gotResult: false

        // capacity|status|time label (may be empty)
        command: ["bash", "-c", "bat=$(upower -e 2>/dev/null | awk '/battery_/{print; exit}'); if [ -z \"$bat\" ]; then echo missing; exit 0; fi; info=$(upower -i \"$bat\" 2>/dev/null); cap=$(echo \"$info\" | awk -F: '/percentage/ {gsub(/[% \\t]/,\"\",$2); print $2; exit}'); status=$(echo \"$info\" | awk -F: '/state/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}'); time=$(echo \"$info\" | awk -F: '/time to empty|time to full/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}'); echo \"${cap}|${status}|${time}\""]
        running: false
        onRunningChanged: {
            if (running)
                gotResult = false;
        }

        stdout: SplitParser {
            onRead: (line) => {
                let trimmed = line.trim();
                if (trimmed === "missing" || trimmed.length === 0)
                    return;

                let parts = trimmed.split("|");
                if (parts.length < 2)
                    return;

                let cap = parseInt(parts[0], 10);
                if (isNaN(cap))
                    return;

                let status = parts[1].trim().toLowerCase();
                batteryPill.capacity = Math.max(0, Math.min(100, cap));
                batteryPill.charging = status === "charging";
                batteryPill.pluggedIn = status === "charging" || status === "fully-charged" || status === "pending-charge";
                batteryPill.timeLabel = parts.length > 2 ? parts.slice(2).join("|").trim() : "";
                batteryProcess.gotResult = true;
            }
        }

    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batteryProcess.running = false;
            batteryProcess.running = true;
        }
    }

    // Match waybar: blink background + foreground together (~1.5s cycle).
    SequentialAnimation {
        running: batteryPill.isCritical
        loops: Animation.Infinite

        ParallelAnimation {
            ColorAnimation {
                target: batteryPill
                property: "color"
                to: Colors.red
                duration: 750
            }
            ColorAnimation {
                target: batteryPill
                property: "criticalFg"
                to: Colors.base
                duration: 750
            }
        }

        ParallelAnimation {
            ColorAnimation {
                target: batteryPill
                property: "color"
                to: Colors.surface0
                duration: 750
            }
            ColorAnimation {
                target: batteryPill
                property: "criticalFg"
                to: Colors.red
                duration: 750
            }
        }

        onRunningChanged: {
            if (!running) {
                batteryPill.color = Colors.surface0;
                batteryPill.criticalFg = Colors.red;
            }
        }
    }

}
