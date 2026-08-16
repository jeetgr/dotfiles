import QtQuick
import Quickshell

Item {
    id: root

    function buildCalendar(d) {
        let year = d.getFullYear();
        let month = d.getMonth();
        let today = d.getDate();
        let firstDow = new Date(year, month, 1).getDay();
        let daysInMonth = new Date(year, month + 1, 0).getDate();
        let lines = [Qt.formatDateTime(d, "yyyy MMMM"), "Su Mo Tu We Th Fr Sa"];
        let cells = [];
        for (let i = 0; i < firstDow; i++) cells.push("  ")
        for (let day = 1; day <= daysInMonth; day++) {
            if (day === today)
                cells.push(day < 10 ? "*" + day : "" + day + "*");
            else
                cells.push(day < 10 ? " " + day : "" + day);
        }
        while (cells.length % 7 !== 0)cells.push("  ")
        for (let i = 0; i < cells.length; i += 7) lines.push(cells.slice(i, i + 7).join(" "))
        return lines.join("\n");
    }

    width: clockPill.width
    height: 28

    Rectangle {
        id: clockPill

        property bool showDate: false
        property bool hovered: clockMouse.containsMouse

        anchors.verticalCenter: parent.verticalCenter
        width: clockRow.width + 32
        height: 28
        radius: 14
        color: Colors.accent

        Row {
            id: clockRow

            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: clockPill.showDate ? "󰃭" : "󰥔"
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 17
                font.weight: Font.Normal
                color: Colors.base
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: clockPill.showDate ? Qt.formatDateTime(clock.currentTime, "dddd, dd MMMM yyyy") : Qt.formatDateTime(clock.currentTime, "hh:mm")
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Colors.base
            }

        }

        Popout {
            id: clockPopout

            anchorItem: clockPill
            show: (clockPill.hovered || clockPopout.popoutHovered) && !clockPill.showDate
            borderColor: Colors.mauve

            Text {
                text: "Calendar"
                color: Colors.subtext0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                text: root.buildCalendar(clock.currentTime)
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.features: {
                    "tnum": 1
                }
            }

            Text {
                text: "Click clock to toggle date"
                color: Colors.overlay0
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 10
            }

        }

        MouseArea {
            id: clockMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: clockPill.showDate = !clockPill.showDate
        }

    }

    QtObject {
        id: clock

        property date currentTime: new Date()
    }

    Timer {
        id: clockTimer

        function alignToNextMinute() {
            let now = new Date();
            interval = Math.max(500, (60 - now.getSeconds()) * 1000 - now.getMilliseconds());
        }

        running: true
        repeat: true
        onTriggered: {
            clock.currentTime = new Date();
            alignToNextMinute();
        }
        Component.onCompleted: alignToNextMinute()
    }

}
