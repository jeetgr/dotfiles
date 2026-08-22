import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Pill {
    id: btPill

    property string state: "disabled"
    property string deviceName: ""
    property int batteryPercent: -1
    property string controllerAlias: ""
    property string controllerAddress: ""
    property string stateLabel: {
        if (state === "connected")
            return "Connected";

        if (state === "powered")
            return "Powered · idle";

        return "Powered off";
    }

    icon: state === "disabled" ? "󰂲" : "󰂯"
    text: state === "connected" && batteryPercent >= 0 ? batteryPercent + "%" : ""
    textColor: state === "connected" ? Colors.blue : Colors.subtext0
    iconColor: textColor

    Process {
        id: btProcess

        property bool gotResult: false

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
                let parts = line.trim().split("|");
                if (parts.length < 1)
                    return ;

                if (parts[0] === "disabled" || parts[0] === "powered") {
                    btPill.state = parts[0];
                    btPill.deviceName = "";
                    btPill.batteryPercent = -1;
                    btPill.controllerAlias = parts.length > 1 ? parts[1] : "";
                    btPill.controllerAddress = parts.length > 2 ? parts[2] : "";
                    btProcess.gotResult = true;
                    return ;
                }
                if (parts[0] !== "connected")
                    return ;

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

    Popout {
        id: btPopout

        anchorItem: btPill
        show: btPill.hovered || btPopout.popoutHovered
        borderColor: Colors.blue

        PopoutTitle {
            text: "Bluetooth"
        }

        PopoutHeader {
            icon: btPill.icon
            iconColor: btPill.textColor
            title: btPill.state === "connected" ? (btPill.deviceName || "Device") : btPill.stateLabel
            subtitle: btPill.state === "connected" ? btPill.stateLabel : ""
        }

        Column {
            spacing: Tokens.rowGap
            width: Tokens.popoutWidthWide

            PopoutRow {
                label: "Adapter"
                value: btPill.controllerAlias || "—"
            }

            PopoutRow {
                rowVisible: btPill.controllerAddress.length > 0
                label: "Address"
                value: btPill.controllerAddress
            }

            PopoutRow {
                rowVisible: btPill.state === "connected" && btPill.batteryPercent >= 0
                label: "Battery"
                value: btPill.batteryPercent + "%"
                valueColor: Colors.blue
            }

            MeterBar {
                visible: btPill.state === "connected" && btPill.batteryPercent >= 0
                barWidth: Tokens.popoutWidthWide
                barHeight: 6
                value: btPill.batteryPercent / 100
                fill: Colors.blue
            }

        }

        PopoutButton {
            text: "Open Blueman"
            accent: Colors.blue
            buttonWidth: Tokens.popoutWidthWide
            onClicked: Quickshell.execDetached(["blueman-manager"])
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["blueman-manager"])
    }

}
