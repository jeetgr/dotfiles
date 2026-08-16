import QtQuick
import QtQuick.Layouts
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
                let devType = parts[0];
                if (devType !== "wifi" && devType !== "ethernet")
                    return ;

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

    Popout {
        id: netPopout

        anchorItem: netPill
        show: netPill.hovered || netPopout.popoutHovered
        borderColor: Colors.teal

        Text {
            text: "Network"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Row {
            spacing: 8

            Text {
                text: netPill.icon
                color: netPill.textColor
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 20
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: 200
                    text: netPill.type === "disconnected" ? "Disconnected" : (netPill.name || netPill.type)
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    text: netPill.type === "wifi" ? "Wi-Fi" : (netPill.type === "ethernet" ? "Ethernet" : "No connection")
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

            }

        }

        Column {
            visible: netPill.type !== "disconnected"
            spacing: 6
            width: 240

            RowLayout {
                width: parent.width

                Text {
                    text: "Device"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: netPill.device || "—"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

            }

            RowLayout {
                width: parent.width

                Text {
                    text: "IPv4"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: netPill.ipCidr || "—"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

            }

            Column {
                visible: netPill.type === "wifi" && netPill.signal >= 0
                spacing: 4
                width: parent.width

                RowLayout {
                    width: parent.width

                    Text {
                        text: "Signal"
                        color: Colors.overlay0
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                    }

                    Text {
                        Layout.fillWidth: true
                        text: netPill.signal + "%"
                        color: Colors.teal
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
                        width: parent.width * (netPill.signal / 100)
                        radius: parent.radius
                        color: Colors.teal
                    }

                }

            }

        }

        Rectangle {
            width: 240
            height: 28
            radius: 8
            color: netBtnHover.hovered ? Colors.surface1 : Colors.surface0

            HoverHandler {
                id: netBtnHover
            }

            Text {
                anchors.centerIn: parent
                text: "Open Network Manager"
                color: Colors.teal
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["nmgui"])
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
        onClicked: Quickshell.execDetached(["nmgui"])
    }

}
