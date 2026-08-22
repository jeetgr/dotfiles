import QtQuick

Item {
    id: root

    property date today: new Date()
    property bool active: false
    property int viewYear: 0
    property int viewMonth: 0
    readonly property bool isCurrentMonth: viewYear === today.getFullYear() && viewMonth === today.getMonth()
    readonly property int cellSize: 34
    readonly property var cells: root.buildCells()
    readonly property var weekdayLabels: {
        let names = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
        if (root.firstDayJs() === 0)
            return ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];

        return names;
    }

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
    width: implicitWidth
    height: implicitHeight

    function firstDayJs() {
        let fd = Qt.locale().firstDayOfWeek;
        if (fd === 7 || fd === 0)
            return 0;

        if (typeof fd === "number" && fd >= 1 && fd <= 6)
            return fd;

        return 1;
    }

    function shiftMonth(delta) {
        let m = root.viewMonth + delta;
        let y = root.viewYear;
        while (m < 0) {
            m += 12;
            y -= 1;
        }
        while (m > 11) {
            m -= 12;
            y += 1;
        }
        root.viewYear = y;
        root.viewMonth = m;
    }

    function resetView() {
        root.viewYear = root.today.getFullYear();
        root.viewMonth = root.today.getMonth();
    }

    function buildCells() {
        let y = root.viewYear;
        let m = root.viewMonth;
        let now = root.today;
        let firstJs = new Date(y, m, 1).getDay();
        let offset = (firstJs - root.firstDayJs() + 7) % 7;
        let start = new Date(y, m, 1 - offset);
        let cells = [];
        for (let i = 0; i < 42; i++) {
            let d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            let inMonth = d.getMonth() === m && d.getFullYear() === y;
            let isToday = d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate();
            let jsDay = d.getDay();
            cells.push({
                "day": d.getDate(),
                "inMonth": inMonth,
                "isToday": isToday,
                "weekend": jsDay === 0 || jsDay === 6
            });
        }
        return cells;
    }

    onActiveChanged: {
        if (active)
            root.resetView();

    }

    Component.onCompleted: root.resetView()

    MouseArea {
        anchors.fill: parent
        z: 20
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onWheel: (event) => {
            root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1);
            event.accepted = true;
        }
    }

    Column {
        id: col

        spacing: 8

        Item {
            width: grid.width
            height: 28

            Text {
                anchors.left: parent.left
                anchors.right: todayLink.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                color: Colors.text
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.fontTitle
                font.weight: Font.DemiBold
                elide: Text.ElideRight

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetView()
                }

            }

            Text {
                id: todayLink

                anchors.right: navButtons.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.isCurrentMonth
                width: visible ? implicitWidth : 0
                text: "Today"
                color: Colors.mauve
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.fontCaption
                font.weight: Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetView()
                }

            }

            Row {
                id: navButtons

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: 28
                    height: 28
                    radius: Tokens.buttonRadius
                    color: prevHover.hovered ? Colors.surface1 : Colors.surface0

                    HoverHandler {
                        id: prevHover
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        color: Colors.mauve
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontIcon
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftMonth(-1)
                    }

                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: Tokens.buttonRadius
                    color: nextHover.hovered ? Colors.surface1 : Colors.surface0

                    HoverHandler {
                        id: nextHover
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        color: Colors.mauve
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontIcon
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftMonth(1)
                    }

                }

            }

        }

        Row {
            spacing: 0

            Repeater {
                model: 7

                Text {
                    required property int index

                    width: root.cellSize
                    horizontalAlignment: Text.AlignHCenter
                    text: root.weekdayLabels[index]
                    color: Colors.overlay1
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontCaption
                    font.weight: Font.DemiBold
                }

            }

        }

        Grid {
            id: grid

            columns: 7
            rowSpacing: 2
            columnSpacing: 0

            Repeater {
                model: 42

                Item {
                    id: dayCell

                    required property int index
                    readonly property var cell: root.cells[index] || {
                        "day": "",
                        "inMonth": false,
                        "isToday": false,
                        "weekend": false
                    }

                    width: root.cellSize
                    height: root.cellSize

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 14
                        color: {
                            if (dayCell.cell.isToday)
                                return Colors.mauve;

                            if (dayHover.hovered && dayCell.cell.inMonth)
                                return Colors.surface1;

                            return "transparent";
                        }

                        HoverHandler {
                            id: dayHover
                        }

                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.cell.day
                        color: {
                            if (dayCell.cell.isToday)
                                return Colors.base;

                            if (!dayCell.cell.inMonth)
                                return Colors.overlay0;

                            if (dayCell.cell.weekend)
                                return Colors.overlay2;

                            return Colors.text;
                        }
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontBody
                        font.weight: dayCell.cell.isToday || dayCell.cell.inMonth ? Font.DemiBold : Font.Normal
                    }

                }

            }

        }

    }

}
