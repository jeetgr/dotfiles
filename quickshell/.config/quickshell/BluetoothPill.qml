import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: btPill

    // disabled | powered | connected
    property string state: "disabled"
    property string deviceName: ""
    property int batteryPercent: -1
    property string controllerAlias: ""
    property string controllerAddress: ""

    icon: state === "disabled" ? "󰂲" : "󰂯"
    text: {
        if (state === "connected") {
            let label = deviceName;
            if (batteryPercent >= 0)
                label += "  " + batteryPercent + "%";
            return label;
        }
        return "";
    }
    textColor: state === "connected" ? Colors.blue : Colors.overlay0
    iconColor: textColor
    tooltipText: {
        let tip = (controllerAlias || "Bluetooth");
        if (controllerAddress.length > 0)
            tip += "\n" + controllerAddress;
        if (state === "disabled")
            tip += "\nPowered: no";
        else if (state === "powered")
            tip += "\nPowered: yes\nNo device connected";
        else {
            tip += "\nConnected: " + deviceName;
            if (batteryPercent >= 0)
                tip += " (" + batteryPercent + "%)";
        }
        return tip;
    }

    Process {
        id: btProcess

        property bool gotResult: false

        // disabled|alias|addr OR powered|alias|addr OR connected|name|bat|alias|addr
        command: ["bash", "-c", "show=$(bluetoothctl show 2>/dev/null); alias=$(echo \"$show\" | awk -F': ' '/^[\\t ]*Alias:/ {print $2; exit}'); addr=$(echo \"$show\" | awk '/^Controller/ {print $2; exit}'); powered=$(echo \"$show\" | awk '/Powered:/ {print $2; exit}'); if [ \"$powered\" != yes ]; then echo \"disabled|${alias}|${addr}\"; exit 0; fi; line=$(bluetoothctl devices Connected 2>/dev/null | head -1); if [ -z \"$line\" ]; then echo \"powered|${alias}|${addr}\"; exit 0; fi; mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); bat=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F': ' '/Battery Percentage:/ { if (match($2, /\\(([0-9]+)\\)/)) { print substr($2, RSTART+1, RLENGTH-2); exit } if (match($2, /[0-9]+/)) { print substr($2, RSTART, RLENGTH); exit } }'); echo \"connected|${name:-$mac}|${bat:--1}|${alias}|${addr}\""]
        running: false
        onRunningChanged: {
            if (running)
                gotResult = false;
        }
        onExited: {
            if (!gotResult) {
                btPill.state = "disabled";
                btPill.deviceName = "";
                btPill.batteryPercent = -1;
            }
        }

        stdout: SplitParser {
            onRead: (line) => {
                let trimmed = line.trim();
                let parts = trimmed.split("|");
                if (parts.length < 1)
                    return;

                if (parts[0] === "disabled" || parts[0] === "powered") {
                    btPill.state = parts[0];
                    btPill.deviceName = "";
                    btPill.batteryPercent = -1;
                    btPill.controllerAlias = parts.length > 1 ? parts[1] : "";
                    btPill.controllerAddress = parts.length > 2 ? parts[2] : "";
                    btProcess.gotResult = true;
                    return;
                }

                if (parts[0] !== "connected")
                    return;

                btPill.state = "connected";
                btPill.deviceName = parts.length > 1 ? parts[1] : "";
                let bat = parts.length > 2 ? parseInt(parts[2], 10) : -1;
                btPill.batteryPercent = isNaN(bat) ? -1 : bat;
                btPill.controllerAlias = parts.length > 3 ? parts[3] : "";
                btPill.controllerAddress = parts.length > 4 ? parts[4] : "";
                btProcess.gotResult = true;
            }
        }

    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            btProcess.running = false;
            btProcess.running = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["blueman-manager"])
    }

}
