import QtQuick
import Quickshell
import Quickshell.Io

Pill {
    id: memPill

    property real usedGb: 0
    property real totalGb: 0
    property int percent: 0

    icon: "󰍛"
    text: usedGb.toFixed(1) + "G"
    textColor: Colors.peach
    iconColor: textColor
    tooltipText: totalGb > 0 ? ("RAM: " + usedGb.toFixed(1) + "G / " + totalGb.toFixed(1) + "G (" + percent + "%)") : ""

    FileView {
        id: memFile

        path: "/proc/meminfo"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            memFile.reload();
            let text = memFile.text();
            let lines = text.split("\n");
            let total = 0;
            let available = 0;
            for (let line of lines) {
                if (line.startsWith("MemTotal:"))
                    total = parseInt(line.match(/\d+/)[0]);
                else if (line.startsWith("MemAvailable:"))
                    available = parseInt(line.match(/\d+/)[0]);
            }
            memPill.totalGb = total / 1024 / 1024;
            memPill.usedGb = (total - available) / 1024 / 1024;
            memPill.percent = total > 0 ? Math.round((total - available) * 100 / total) : 0;
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["kitty", "--class", "btop-float", "-e", "btop"])
    }

}
