import QtQuick
import QtQuick.Layouts
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
    property string stateLabel: {
        if (state === "connected")
            return "Connected";

        if (state === "powered")
            return "Powered · idle";

        return "Powered off";
    }

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

        Text {
            text: "Bluetooth"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Row {
            spacing: 10

            Text {
                text: btPill.icon
                color: btPill.textColor
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 22
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: 200
                    text: btPill.state === "connected" ? (btPill.deviceName || "Device") : btPill.stateLabel
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    text: btPill.stateLabel
                    visible: btPill.state === "connected"
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

            }

        }

        Column {
            spacing: 6
            width: 240

            RowLayout {
                width: parent.width

                Text {
                    text: "Adapter"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: btPill.controllerAlias || "—"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

            }

            RowLayout {
                visible: btPill.controllerAddress.length > 0
                width: parent.width

                Text {
                    text: "Address"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: btPill.controllerAddress
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

            }

            Column {
                visible: btPill.state === "connected" && btPill.batteryPercent >= 0
                spacing: 4
                width: parent.width

                RowLayout {
                    width: parent.width

                    Text {
                        text: "Battery"
                        color: Colors.overlay0
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                    }

                    Text {
                        Layout.fillWidth: true
                        text: btPill.batteryPercent + "%"
                        color: Colors.blue
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                    }

                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Colors.surface0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (btPill.batteryPercent / 100)
                        radius: parent.radius
                        color: Colors.blue
                    }

                }

            }

        }

        Rectangle {
            width: 240
            height: 28
            radius: 8
            color: btBtnHover.hovered ? Colors.surface1 : Colors.surface0

            HoverHandler {
                id: btBtnHover
            }

            Text {
                anchors.centerIn: parent
                text: "Open Blueman"
                color: Colors.blue
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["blueman-manager"])
            }

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }

            }

        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["blueman-manager"])
    }

}
