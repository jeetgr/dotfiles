import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Pill {
    id: tlpPill

    property bool onAc: false

    icon: onAc ? "󰚥" : "󰁹"
    text: onAc ? "AC" : "BAT"
    textColor: Colors.lavender
    iconColor: textColor

    Process {
        id: tlpProcess

        command: ["bash", "-c", "ac=$(find /sys/class/power_supply -maxdepth 1 -iname 'A*' | head -n1); if [ -n \"$ac\" ] && [ \"$(cat \"$ac/online\" 2>/dev/null)\" = 1 ]; then echo AC; else echo BAT; fi"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                let mode = line.trim();
                if (mode === "AC" || mode === "BAT")
                    tlpPill.onAc = mode === "AC";

            }
        }

    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            tlpProcess.running = false;
            tlpProcess.running = true;
        }
    }

    Popout {
        id: tlpPopout

        anchorItem: tlpPill
        show: tlpPill.hovered || tlpPopout.popoutHovered
        borderColor: Colors.lavender

        Text {
            text: "Power"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Row {
            spacing: 10

            Text {
                text: tlpPill.icon
                color: Colors.lavender
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 22
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: tlpPill.onAc ? "AC power" : "Battery power"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "TLP managed"
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

            }

        }

        Text {
            width: 220
            text: tlpPill.onAc ? "Laptop is plugged in. TLP uses the AC profile." : "Running on battery. TLP uses the BAT profile."
            color: Colors.overlay1
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }

        Rectangle {
            width: 220
            height: 28
            radius: 8
            color: tlpBtnHover.hovered ? Colors.surface1 : Colors.surface0

            HoverHandler {
                id: tlpBtnHover
            }

            Text {
                anchors.centerIn: parent
                text: "Show tlp-stat"
                color: Colors.lavender
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "tlp-stat", "-s"])
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
        onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "tlp-stat", "-s"])
    }

}
