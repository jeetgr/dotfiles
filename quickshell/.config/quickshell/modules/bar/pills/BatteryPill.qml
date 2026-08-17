import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Pill {
    id: batteryPill

    property int capacity: 0
    property bool charging: false
    property bool pluggedIn: false
    property bool isWarning: capacity <= 30 && !pluggedIn
    property bool isCritical: capacity <= 15 && !pluggedIn
    property color criticalFg: Colors.red
    property string timeLabel: ""
    property int healthPercent: -1
    property string energyLabel: ""
    property string modelName: ""
    property string stateLabel: charging ? "Charging" : (pluggedIn ? "Plugged in" : "Discharging")
    property bool onAc: false
    readonly property color restColor: flat ? "transparent" : Colors.surface0

    icon: {
        let icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return charging ? "󰂄" : icons[Math.min(9, Math.floor(capacity / 10))];
    }
    text: capacity + "%"
    textColor: isCritical ? criticalFg : (isWarning ? Colors.peach : (charging ? Colors.yellow : Colors.green))
    iconColor: textColor

    Process {
        id: batteryProcess

        property bool gotResult: false

        command: ["bash", "-c", "bat=$(upower -e 2>/dev/null | awk '/battery_/{print; exit}'); if [ -z \"$bat\" ]; then echo missing; exit 0; fi; info=$(upower -i \"$bat\" 2>/dev/null); cap=$(echo \"$info\" | awk -F: '/percentage/ {gsub(/[% \\t]/,\"\",$2); print $2; exit}'); status=$(echo \"$info\" | awk -F: '/state/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}'); time=$(echo \"$info\" | awk -F: '/time to empty|time to full/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}'); health=$(echo \"$info\" | awk -F: '/^\\s*capacity:/ {gsub(/[% \\t]/,\"\",$2); print $2; exit}'); energy=$(echo \"$info\" | awk -F: '/^\\s*energy:/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}'); energy_full=$(echo \"$info\" | awk -F: '/energy-full:/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}'); model=$(echo \"$info\" | awk -F: '/model:/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}'); echo \"${cap}|${status}|${time}|${health}|${energy}|${energy_full}|${model}\""]
        running: false
        onRunningChanged: {
            if (running)
                gotResult = false;

        }

        stdout: SplitParser {
            onRead: (line) => {
                let trimmed = line.trim();
                if (trimmed === "missing" || trimmed.length === 0)
                    return ;

                let parts = trimmed.split("|");
                if (parts.length < 2)
                    return ;

                let cap = parseInt(parts[0], 10);
                if (isNaN(cap))
                    return ;

                let status = parts[1].trim().toLowerCase();
                batteryPill.capacity = Math.max(0, Math.min(100, cap));
                batteryPill.charging = status === "charging";
                batteryPill.pluggedIn = status === "charging" || status === "fully-charged" || status === "pending-charge";
                batteryPill.timeLabel = parts.length > 2 ? parts[2].trim() : "";
                let health = parts.length > 3 ? parseInt(parts[3], 10) : NaN;
                batteryPill.healthPercent = isNaN(health) ? -1 : Math.max(0, Math.min(100, health));
                let energy = parts.length > 4 ? parts[4].trim() : "";
                let energyFull = parts.length > 5 ? parts[5].trim() : "";
                if (energy.length > 0 && energyFull.length > 0)
                    batteryPill.energyLabel = energy + " / " + energyFull;
                else
                    batteryPill.energyLabel = energy;
                batteryPill.modelName = parts.length > 6 ? parts.slice(6).join("|").trim() : "";
                batteryProcess.gotResult = true;
            }
        }

    }

    Process {
        id: tlpProcess

        command: ["bash", "-c", "ac=$(find /sys/class/power_supply -maxdepth 1 -iname 'A*' | head -n1); if [ -n \"$ac\" ] && [ \"$(cat \"$ac/online\" 2>/dev/null)\" = 1 ]; then echo AC; else echo BAT; fi"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                let mode = line.trim();
                if (mode === "AC" || mode === "BAT")
                    batteryPill.onAc = mode === "AC";

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
            tlpProcess.running = false;
            tlpProcess.running = true;
        }
    }

    Popout {
        id: batteryPopout

        anchorItem: batteryPill
        show: batteryPill.hovered || batteryPopout.popoutHovered
        borderColor: batteryPill.isCritical ? Colors.red : (batteryPill.charging ? Colors.yellow : Colors.green)

        PopoutTitle {
            text: "Battery"
        }

        PopoutHeader {
            icon: batteryPill.icon
            iconColor: batteryPill.textColor
            title: batteryPill.capacity + "%  ·  " + batteryPill.stateLabel
            subtitle: batteryPill.modelName
        }

        MeterBar {
            barWidth: Tokens.popoutWidthWide
            value: batteryPill.capacity / 100
            fill: batteryPill.textColor
        }

        Column {
            spacing: Tokens.rowGap
            width: Tokens.popoutWidthWide

            PopoutRow {
                label: batteryPill.charging ? "Time to full" : "Time remaining"
                value: batteryPill.timeLabel.length > 0 ? batteryPill.timeLabel : "unavailable"
            }

            PopoutRow {
                rowVisible: batteryPill.healthPercent >= 0
                label: "Health"
                value: batteryPill.healthPercent + "%"
                valueColor: batteryPill.healthPercent < 70 ? Colors.peach : Colors.green
            }

            PopoutRow {
                rowVisible: batteryPill.energyLabel.length > 0
                label: "Energy"
                value: batteryPill.energyLabel
            }

            PopoutRow {
                label: "Profile"
                value: batteryPill.onAc ? "AC" : "BAT"
                valueColor: Colors.lavender
            }

        }

        PopoutButton {
            text: "Show tlp-stat"
            accent: Colors.lavender
            buttonWidth: Tokens.popoutWidthWide
            onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "tlp-stat", "-s"])
        }

    }

    SequentialAnimation {
        running: batteryPill.isCritical
        loops: Animation.Infinite
        onRunningChanged: {
            if (!running) {
                batteryPill.color = batteryPill.restColor;
                batteryPill.criticalFg = Colors.red;
            }
        }

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
                to: batteryPill.restColor
                duration: 750
            }

            ColorAnimation {
                target: batteryPill
                property: "criticalFg"
                to: Colors.red
                duration: 750
            }

        }

    }

}
