import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Pill {
    id: cpuPill

    property real usage: 0
    property var prevIdle: 0
    property var prevTotal: 0
    property string loadAvg: ""
    property int coreCount: 0

    icon: "󰻠"
    text: Math.round(usage) + "%"
    textColor: Colors.green
    iconColor: textColor

    FileView {
        id: statFile

        path: "/proc/stat"
    }

    FileView {
        id: loadFile

        path: "/proc/loadavg"
    }

    FileView {
        id: cpuInfoFile

        path: "/proc/cpuinfo"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            loadFile.reload();
            let text = statFile.text();
            let firstLine = text.split("\n")[0];
            let parts = firstLine.trim().split(/\s+/).slice(1).map(Number);
            let idle = parts[3] + parts[4];
            let total = parts.reduce((a, b) => {
                return a + b;
            }, 0);
            let idleDelta = idle - cpuPill.prevIdle;
            let totalDelta = total - cpuPill.prevTotal;
            if (cpuPill.prevTotal > 0 && totalDelta > 0)
                cpuPill.usage = 100 * (1 - idleDelta / totalDelta);

            cpuPill.prevIdle = idle;
            cpuPill.prevTotal = total;
            let loadParts = loadFile.text().trim().split(/\s+/);
            if (loadParts.length >= 3)
                cpuPill.loadAvg = loadParts[0] + "  " + loadParts[1] + "  " + loadParts[2];

            if (cpuPill.coreCount === 0) {
                cpuInfoFile.reload();
                let cores = cpuInfoFile.text().match(/^processor\s*:/gm);
                cpuPill.coreCount = cores ? cores.length : 0;
            }
        }
    }

    Popout {
        id: cpuPopout

        anchorItem: cpuPill
        show: cpuPill.hovered || cpuPopout.popoutHovered
        borderColor: Colors.green

        PopoutTitle {
            text: "CPU"
        }

        PopoutHeader {
            icon: "󰻠"
            iconColor: Colors.green
            title: Math.round(cpuPill.usage) + "% usage"
            subtitle: cpuPill.coreCount > 0 ? (cpuPill.coreCount + " cores") : ""
        }

        MeterBar {
            value: cpuPill.usage / 100
            fill: Colors.green
        }

        PopoutRow {
            label: "Load avg"
            value: cpuPill.loadAvg.length > 0 ? cpuPill.loadAvg : "—"
        }

        PopoutButton {
            text: "Open Mission Center"
            accent: Colors.green
            onClicked: Quickshell.execDetached(["missioncenter"])
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["missioncenter"])
    }

}
