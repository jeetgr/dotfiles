import QtQuick
import Quickshell

Item {
    id: root

    width: clockPill.width
    height: 28

    function buildCalendar(d) {
        let year = d.getFullYear();
        let month = d.getMonth();
        let today = d.getDate();
        let firstDow = new Date(year, month, 1).getDay();
        let daysInMonth = new Date(year, month + 1, 0).getDate();
        let lines = [Qt.formatDateTime(d, "yyyy MMMM"), "Su Mo Tu We Th Fr Sa"];
        let cells = [];
        for (let i = 0; i < firstDow; i++)
            cells.push("  ");
        for (let day = 1; day <= daysInMonth; day++) {
            if (day === today)
                cells.push(day < 10 ? "*" + day : "" + day + "*");
            else
                cells.push(day < 10 ? " " + day : "" + day);
        }
        while (cells.length % 7 !== 0)
            cells.push("  ");
        for (let i = 0; i < cells.length; i += 7)
            lines.push(cells.slice(i, i + 7).join(" "));
        return lines.join("\n");
    }

    Rectangle {
        id: clockPill

        property bool showDate: false

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

        Tooltip {
            anchorItem: clockPill
            text: root.buildCalendar(clock.currentTime)
            show: clockMouse.containsMouse && !clockPill.showDate
            delayMs: 250
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
