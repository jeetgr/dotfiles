import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Pill {
    id: netPill

    property string type: "disconnected"
    property string name: ""
    property string device: ""
    property string ipCidr: ""
    property int signal: -1

    icon: type === "wifi" ? "󰤨" : (type === "ethernet" ? "󰈀" : "󰤭")
    text: ""
    textColor: type === "disconnected" ? Colors.red : Colors.teal
    iconColor: textColor

    Process {
        id: netProcess

        property bool gotResult: false

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
                let parts = line.trim().split("|");
                if (parts.length < 1)
                    return ;

                if (parts[0] === "disconnected") {
                    netPill.type = "disconnected";
                    netPill.name = "";
                    netPill.device = "";
                    netPill.ipCidr = "";
                    netPill.signal = -1;
                    netProcess.gotResult = true;
                    return ;
                }
                if (parts[0] !== "wifi" && parts[0] !== "ethernet")
                    return ;

                netPill.type = parts[0];
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

    Popout {
        id: netPopout

        anchorItem: netPill
        show: netPill.hovered || netPopout.popoutHovered
        borderColor: Colors.teal

        PopoutTitle {
            text: "Network"
        }

        PopoutHeader {
            icon: netPill.icon
            iconColor: netPill.textColor
            title: netPill.type === "disconnected" ? "Disconnected" : (netPill.name || netPill.type)
            subtitle: netPill.type === "wifi" ? "Wi-Fi" : (netPill.type === "ethernet" ? "Ethernet" : "No connection")
        }

        Column {
            visible: netPill.type !== "disconnected"
            spacing: Tokens.rowGap
            width: Tokens.popoutWidthWide

            PopoutRow {
                label: "Device"
                value: netPill.device || "—"
            }

            PopoutRow {
                label: "IPv4"
                value: netPill.ipCidr || "—"
            }

            PopoutRow {
                rowVisible: netPill.type === "wifi" && netPill.signal >= 0
                label: "Signal"
                value: netPill.signal + "%"
                valueColor: Colors.teal
            }

            MeterBar {
                visible: netPill.type === "wifi" && netPill.signal >= 0
                barWidth: Tokens.popoutWidthWide
                barHeight: 6
                value: netPill.signal / 100
                fill: Colors.teal
            }

        }

        PopoutButton {
            text: "Open Network Manager"
            accent: Colors.teal
            buttonWidth: Tokens.popoutWidthWide
            onClicked: Quickshell.execDetached(["nmgui"])
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["nmgui"])
    }

}
