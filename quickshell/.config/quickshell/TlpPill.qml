import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: tlpPill

    property bool onAc: false

    icon: onAc ? "󰚥" : "󰁹"
    text: onAc ? "AC" : "BAT"
    textColor: Colors.lavender
    iconColor: textColor
    tooltipText: "Power mode: " + (onAc ? "AC" : "BAT") + " (TLP managed)"

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

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "tlp-stat", "-s"])
    }

}
