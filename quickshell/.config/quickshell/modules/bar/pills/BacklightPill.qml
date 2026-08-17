import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.services

Pill {
    id: backlightPill

    property int percent: 0
    property string deviceName: ""
    property bool osdReady: false
    property string brightnessIcon: {
        let icons = ["󰃚", "󰃛", "󰃜", "󰃝", "󰃞", "󰃟", "󰃠"];
        return icons[Math.min(icons.length - 1, Math.floor(percent / 100 * icons.length))];
    }

    function refresh() {
        backlightProcess.running = false;
        backlightProcess.running = true;
    }

    function setBrightness(percent) {
        Quickshell.execDetached(["brightnessctl", "set", Math.max(1, Math.min(100, Math.round(percent))) + "%"]);
        quickRefresh.restart();
    }

    function setFromX(x, width) {
        if (width <= 0)
            return ;

        setBrightness((x / width) * 100);
    }

    function nudge(up) {
        Quickshell.execDetached(["brightnessctl", "set", up ? "5%+" : "5%-"]);
        quickRefresh.restart();
    }

    icon: brightnessIcon
    text: percent + "%"
    textColor: Colors.yellow
    iconColor: textColor
    Component.onCompleted: Qt.callLater(() => {
        backlightPill.osdReady = true;
    })
    onPercentChanged: {
        if (osdReady)
            Osd.pushBrightness(percent);

    }

    Process {
        id: backlightProcess

        command: ["bash", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); print $1 \"|\" $4}'"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                let parts = line.trim().split("|");
                if (parts.length < 2)
                    return ;

                backlightPill.deviceName = parts[0];
                let value = parseInt(parts[1], 10);
                if (!isNaN(value))
                    backlightPill.percent = Math.max(0, Math.min(100, value));

            }
        }

    }

    Timer {
        interval: 750
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backlightPill.refresh()
    }

    Timer {
        id: quickRefresh

        interval: 80
        repeat: false
        onTriggered: backlightPill.refresh()
    }

    Popout {
        id: backlightPopout

        anchorItem: backlightPill
        show: backlightPill.hovered || backlightPopout.popoutHovered
        borderColor: Colors.yellow

        PopoutTitle {
            text: "Brightness"
        }

        Text {
            width: Tokens.popoutWidth
            text: backlightPill.deviceName.length > 0 ? backlightPill.deviceName : "Display"
            color: Colors.text
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontBody
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        SliderBar {
            icon: backlightPill.brightnessIcon
            accent: Colors.yellow
            value: backlightPill.percent / 100
            valueText: backlightPill.percent + "%"
            onSetFromX: (x, width) => {
                return backlightPill.setFromX(x, width);
            }
            onWheeled: (event) => {
                return backlightPill.nudge(event.angleDelta.y > 0);
            }
        }

    }

    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            return backlightPill.nudge(event.angleDelta.y > 0);
        }
    }

}
