import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: cpuPill

    property real usage: 0
    property var prevIdle: 0
    property var prevTotal: 0
    property string loadAvg: ""

    icon: "󰻠"
    text: Math.round(usage) + "%"
    textColor: Colors.green
    iconColor: textColor
    tooltipText: {
        let tip = "CPU usage: " + Math.round(usage) + "%";
        if (loadAvg.length > 0)
            tip += "\nLoad average: " + loadAvg;
        return tip;
    }

    FileView {
        id: statFile

        path: "/proc/stat"
    }

    FileView {
        id: loadFile

        path: "/proc/loadavg"
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
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["missioncenter"])
    }

}
