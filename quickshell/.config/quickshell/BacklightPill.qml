import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Pill {
    id: backlightPill

    property int percent: 0
    property string deviceName: ""
    property bool osdReady: false
    property string brightnessIcon: {
        let icons = ["󰃚", "󰃛", "󰃜", "󰃝", "󰃞", "󰃟", "󰃠"];
        let index = Math.min(icons.length - 1, Math.floor(percent / 100 * icons.length));
        return icons[index];
    }

    function refresh() {
        backlightProcess.running = false;
        backlightProcess.running = true;
    }

    function setBrightness(percent) {
        let value = Math.max(1, Math.min(100, Math.round(percent)));
        Quickshell.execDetached(["brightnessctl", "set", value + "%"]);
        quickRefresh.restart();
    }

    function setFromX(x, width) {
        if (width <= 0)
            return ;

        setBrightness((x / width) * 100);
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

        // name|percent
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

        Text {
            text: "Brightness"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Text {
            width: 220
            text: backlightPill.deviceName.length > 0 ? backlightPill.deviceName : "Display"
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        RowLayout {
            width: 220
            spacing: 10

            Text {
                text: backlightPill.brightnessIcon
                color: Colors.yellow
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Colors.surface0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (backlightPill.percent / 100)
                        radius: parent.radius
                        color: Colors.yellow
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => {
                        return backlightPill.setFromX(mouse.x, width);
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed)
                            backlightPill.setFromX(mouse.x, width);

                    }
                    onWheel: (event) => {
                        if (event.angleDelta.y > 0)
                            Quickshell.execDetached(["brightnessctl", "set", "5%+"]);
                        else
                            Quickshell.execDetached(["brightnessctl", "set", "5%-"]);
                        quickRefresh.restart();
                    }
                }

            }

            Text {
                text: backlightPill.percent + "%"
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }

        }

    }

    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                Quickshell.execDetached(["brightnessctl", "set", "5%+"]);
            else
                Quickshell.execDetached(["brightnessctl", "set", "5%-"]);
            quickRefresh.restart();
        }
    }

}
