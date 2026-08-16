import QtQuick
import QtQuick.Layouts
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
    property int healthPercent: -1
    property string energyLabel: ""
    property string modelName: ""
    property string stateLabel: {
        if (charging)
            return "Charging";

        if (pluggedIn)
            return "Plugged in";

        return "Discharging";
    }

    icon: {
        let icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        let index = Math.min(9, Math.floor(capacity / 10));
        return charging ? "󰂄" : icons[index];
    }
    text: capacity + "%"
    textColor: isCritical ? criticalFg : (isWarning ? Colors.peach : (charging ? Colors.yellow : Colors.green))
    iconColor: textColor

    Process {
        id: batteryProcess

        property bool gotResult: false

        // capacity|status|time|health|energy|energy_full|model
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
                else if (energy.length > 0)
                    batteryPill.energyLabel = energy;
                else
                    batteryPill.energyLabel = "";
                batteryPill.modelName = parts.length > 6 ? parts.slice(6).join("|").trim() : "";
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

    Popout {
        id: batteryPopout

        anchorItem: batteryPill
        show: batteryPill.hovered || batteryPopout.popoutHovered
        borderColor: batteryPill.isCritical ? Colors.red : (batteryPill.charging ? Colors.yellow : Colors.green)

        Text {
            text: "Battery"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Row {
            spacing: 10

            Text {
                text: batteryPill.icon
                color: batteryPill.textColor
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 22
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: batteryPill.capacity + "%  ·  " + batteryPill.stateLabel
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    visible: batteryPill.modelName.length > 0
                    text: batteryPill.modelName
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

            }

        }

        Rectangle {
            width: 240
            height: 8
            radius: 4
            color: Colors.surface0

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (batteryPill.capacity / 100)
                radius: parent.radius
                color: batteryPill.textColor
            }

        }

        Column {
            spacing: 6
            width: 240

            RowLayout {
                width: parent.width

                Text {
                    text: batteryPill.charging ? "Time to full" : "Time remaining"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: batteryPill.timeLabel.length > 0 ? batteryPill.timeLabel : "unavailable"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

            }

            RowLayout {
                visible: batteryPill.healthPercent >= 0
                width: parent.width

                Text {
                    text: "Health"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: batteryPill.healthPercent + "%"
                    color: batteryPill.healthPercent < 70 ? Colors.peach : Colors.green
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                }

            }

            RowLayout {
                visible: batteryPill.energyLabel.length > 0
                width: parent.width

                Text {
                    text: "Energy"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: batteryPill.energyLabel
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

            }

        }

    }

    // Match waybar: blink background + foreground together (~1.5s cycle).
    SequentialAnimation {
        running: batteryPill.isCritical
        loops: Animation.Infinite
        onRunningChanged: {
            if (!running) {
                batteryPill.color = Colors.surface0;
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

    }

}
