import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

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

        PopoutTitle {
            text: "Power"
        }

        PopoutHeader {
            icon: tlpPill.icon
            iconColor: Colors.lavender
            title: tlpPill.onAc ? "AC power" : "Battery power"
            subtitle: "TLP managed"
        }

        Text {
            width: Tokens.popoutWidth
            text: tlpPill.onAc ? "Laptop is plugged in. TLP uses the AC profile." : "Running on battery. TLP uses the BAT profile."
            color: Colors.overlay1
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontCaption
            wrapMode: Text.Wrap
        }

        PopoutButton {
            text: "Show tlp-stat"
            accent: Colors.lavender
            onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "tlp-stat", "-s"])
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "tlp-stat", "-s"])
    }

}
