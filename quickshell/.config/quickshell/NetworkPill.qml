import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: netPill

    property string type: "disconnected"
    property string name: ""
    property string device: ""
    property string ipCidr: ""
    property int signal: -1

    icon: {
        if (type === "wifi")
            return "󰤨";
        if (type === "ethernet")
            return "󰈀";
        return "󰤭";
    }
    text: {
        if (type === "wifi" || type === "ethernet")
            return name;
        return "disconnected";
    }
    textColor: type === "disconnected" ? Colors.red : Colors.teal
    iconColor: textColor
    tooltipText: {
        if (type === "disconnected")
            return "No network connection";
        let tip = name;
        if (type === "wifi" && signal >= 0)
            tip += " (" + signal + "%)";
        if (device.length > 0)
            tip += "\n" + device;
        if (ipCidr.length > 0)
            tip += "\n" + ipCidr;
        return tip;
    }

    Process {
        id: netProcess

        property bool gotResult: false

        // disconnected|||| OR type|conn|device|ip/cidr|signal
        command: ["bash", "-c", "line=$(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE device | awk -F: '$1==\"ethernet\" && $2==\"connected\" {print; exit}'); [ -z \"$line\" ] && line=$(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE device | awk -F: '$1==\"wifi\" && $2==\"connected\" {print; exit}'); if [ -z \"$line\" ]; then echo 'disconnected||||'; exit 0; fi; typ=$(echo \"$line\" | awk -F: '{print $1}'); conn=$(echo \"$line\" | awk -F: '{print $3}'); dev=$(echo \"$line\" | awk -F: '{print $4}'); ip=$(nmcli -t -f IP4.ADDRESS device show \"$dev\" 2>/dev/null | head -1 | cut -d: -f2-); sig=; if [ \"$typ\" = wifi ]; then sig=$(nmcli -t -f IN-USE,SIGNAL device wifi 2>/dev/null | awk -F: '$1==\"*\" {print $2; exit}'); fi; echo \"$typ|$conn|$dev|$ip|${sig:--1}\""]
        running: false
        onRunningChanged: {
            if (running)
                gotResult = false;
        }
        onExited: {
            if (!gotResult) {
                netPill.type = "disconnected";
                netPill.name = "";
                netPill.device = "";
                netPill.ipCidr = "";
                netPill.signal = -1;
            }
        }

        stdout: SplitParser {
            onRead: (line) => {
                let trimmed = line.trim();
                let parts = trimmed.split("|");
                if (parts.length < 1)
                    return;

                if (parts[0] === "disconnected") {
                    netPill.type = "disconnected";
                    netPill.name = "";
                    netPill.device = "";
                    netPill.ipCidr = "";
                    netPill.signal = -1;
                    netProcess.gotResult = true;
                    return;
                }

                let devType = parts[0];
                if (devType !== "wifi" && devType !== "ethernet")
                    return;

                netPill.type = devType;
                netPill.name = parts.length > 1 ? parts[1] : "";
                netPill.device = parts.length > 2 ? parts[2] : "";
                netPill.ipCidr = parts.length > 3 ? parts[3] : "";
                let sig = parts.length > 4 ? parseInt(parts[4], 10) : -1;
                netPill.signal = isNaN(sig) ? -1 : sig;
                netProcess.gotResult = true;
            }
        }

    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netProcess.running = false;
            netProcess.running = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["nmgui"])
    }

}
