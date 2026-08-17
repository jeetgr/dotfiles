import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Pill {
    id: memPill

    property real usedGb: 0
    property real totalGb: 0
    property real availableGb: 0
    property real swapUsedGb: 0
    property real swapTotalGb: 0
    property int percent: 0

    icon: "󰍛"
    text: usedGb.toFixed(1) + "G"
    textColor: Colors.peach
    iconColor: textColor

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
            let swapTotal = 0;
            let swapFree = 0;
            for (let line of lines) {
                if (line.startsWith("MemTotal:"))
                    total = parseInt(line.match(/\d+/)[0]);
                else if (line.startsWith("MemAvailable:"))
                    available = parseInt(line.match(/\d+/)[0]);
                else if (line.startsWith("SwapTotal:"))
                    swapTotal = parseInt(line.match(/\d+/)[0]);
                else if (line.startsWith("SwapFree:"))
                    swapFree = parseInt(line.match(/\d+/)[0]);
            }
            memPill.totalGb = total / 1024 / 1024;
            memPill.availableGb = available / 1024 / 1024;
            memPill.usedGb = (total - available) / 1024 / 1024;
            memPill.percent = total > 0 ? Math.round((total - available) * 100 / total) : 0;
            memPill.swapTotalGb = swapTotal / 1024 / 1024;
            memPill.swapUsedGb = Math.max(0, (swapTotal - swapFree) / 1024 / 1024);
        }
    }

    Popout {
        id: memPopout

        anchorItem: memPill
        show: memPill.hovered || memPopout.popoutHovered
        borderColor: Colors.peach

        PopoutTitle {
            text: "Memory"
        }

        PopoutHeader {
            icon: "󰍛"
            iconColor: Colors.peach
            title: memPill.usedGb.toFixed(1) + "G / " + memPill.totalGb.toFixed(1) + "G"
            subtitle: memPill.percent + "% used"
        }

        MeterBar {
            barWidth: Tokens.popoutWidthWide
            value: memPill.percent / 100
            fill: Colors.peach
        }

        Column {
            spacing: Tokens.rowGap
            width: Tokens.popoutWidthWide

            PopoutRow {
                label: "Available"
                value: memPill.availableGb.toFixed(1) + "G"
            }

            PopoutRow {
                label: "Swap"
                value: memPill.swapTotalGb > 0 ? (memPill.swapUsedGb.toFixed(1) + "G / " + memPill.swapTotalGb.toFixed(1) + "G") : "none"
            }

        }

        PopoutButton {
            text: "Open btop"
            accent: Colors.peach
            buttonWidth: Tokens.popoutWidthWide
            onClicked: Quickshell.execDetached(["kitty", "--class", "btop-float", "-e", "btop"])
        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["kitty", "--class", "btop-float", "-e", "btop"])
    }

}
