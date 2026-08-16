import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

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

        Text {
            text: "Memory"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Row {
            spacing: 10

            Text {
                text: "󰍛"
                color: Colors.peach
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 22
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: memPill.usedGb.toFixed(1) + "G / " + memPill.totalGb.toFixed(1) + "G"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    text: memPill.percent + "% used"
                    color: Colors.subtext0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

            }

        }

        Rectangle {
            width: 240
            height: 8
            radius: 4
            color: Colors.surface0

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (memPill.percent / 100)
                radius: parent.radius
                color: Colors.peach
            }

        }

        Column {
            spacing: 6
            width: 240

            RowLayout {
                width: parent.width

                Text {
                    text: "Available"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: memPill.availableGb.toFixed(1) + "G"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                }

            }

            RowLayout {
                width: parent.width

                Text {
                    text: "Swap"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: memPill.swapTotalGb > 0 ? (memPill.swapUsedGb.toFixed(1) + "G / " + memPill.swapTotalGb.toFixed(1) + "G") : "none"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                }

            }

        }

        Rectangle {
            width: 240
            height: 28
            radius: 8
            color: memBtnHover.hovered ? Colors.surface1 : Colors.surface0

            HoverHandler {
                id: memBtnHover
            }

            Text {
                anchors.centerIn: parent
                text: "Open btop"
                color: Colors.peach
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["kitty", "--class", "btop-float", "-e", "btop"])
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
        onClicked: Quickshell.execDetached(["kitty", "--class", "btop-float", "-e", "btop"])
    }

}
