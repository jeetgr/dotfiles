import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

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

        Text {
            text: "CPU"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Row {
            spacing: 10

            Text {
                text: "󰻠"
                color: Colors.green
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 22
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: Math.round(cpuPill.usage) + "% usage"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    visible: cpuPill.coreCount > 0
                    text: cpuPill.coreCount + " cores"
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

            }

        }

        Rectangle {
            width: 220
            height: 8
            radius: 4
            color: Colors.surface0

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (cpuPill.usage / 100)
                radius: parent.radius
                color: Colors.green
            }

        }

        RowLayout {
            width: 220

            Text {
                text: "Load avg"
                color: Colors.overlay0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
            }

            Text {
                Layout.fillWidth: true
                text: cpuPill.loadAvg.length > 0 ? cpuPill.loadAvg : "—"
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignRight
            }

        }

        Rectangle {
            width: 220
            height: 28
            radius: 8
            color: cpuBtnHover.hovered ? Colors.surface1 : Colors.surface0

            HoverHandler {
                id: cpuBtnHover
            }

            Text {
                anchors.centerIn: parent
                text: "Open Mission Center"
                color: Colors.green
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["missioncenter"])
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
        onClicked: Quickshell.execDetached(["missioncenter"])
    }

}
