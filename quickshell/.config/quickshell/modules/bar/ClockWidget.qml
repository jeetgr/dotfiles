import QtQuick
import qs.components

Item {
    id: root

    readonly property int swapMs: 420
    readonly property var spatialEase: [0.38, 1.21, 0.22, 1]

    width: clockPill.width
    height: Tokens.pillHeight

    Rectangle {
        id: clockPill

        property bool showDate: false

        anchors.verticalCenter: parent.verticalCenter
        width: clockRow.width + 32
        height: Tokens.pillHeight
        radius: Tokens.pillRadius
        color: Colors.accent
        clip: true

        Row {
            id: clockRow

            anchors.centerIn: parent
            spacing: Tokens.rowGap

            Item {
                id: iconSlot

                width: Math.max(iconTime.implicitWidth, iconDate.implicitWidth)
                height: Math.max(iconTime.implicitHeight, iconDate.implicitHeight)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: iconTime

                    anchors.centerIn: parent
                    text: "󰥔"
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontIcon
                    color: Colors.base
                    opacity: clockPill.showDate ? 0 : 1
                    scale: clockPill.showDate ? 0.72 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }

                    }

                }

                Text {
                    id: iconDate

                    anchors.centerIn: parent
                    text: "󰃭"
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontIcon
                    color: Colors.base
                    opacity: clockPill.showDate ? 1 : 0
                    scale: clockPill.showDate ? 1 : 0.72

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }

                    }

                }

            }

            Item {
                id: labelClip

                width: clockPill.showDate ? dateLabel.implicitWidth : timeLabel.implicitWidth
                height: Math.max(timeLabel.implicitHeight, dateLabel.implicitHeight)
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Text {
                    id: timeLabel

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: clockPill.showDate ? -height - 2 : 0
                    text: Qt.formatDateTime(clock.currentTime, "hh:mm")
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontLabel
                    font.weight: Font.Bold
                    color: Colors.base
                    opacity: clockPill.showDate ? 0 : 1

                    Behavior on y {
                        NumberAnimation {
                            duration: 340
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }

                    }

                }

                Text {
                    id: dateLabel

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: clockPill.showDate ? 0 : height + 2
                    text: Qt.formatDateTime(clock.currentTime, "dddd, dd MMMM yyyy")
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontLabel
                    font.weight: Font.Bold
                    color: Colors.base
                    opacity: clockPill.showDate ? 1 : 0

                    Behavior on y {
                        NumberAnimation {
                            duration: 340
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }

                    }

                }

                Behavior on width {
                    NumberAnimation {
                        duration: root.swapMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.spatialEase
                    }

                }

            }

        }

        MouseArea {
            id: clockMouse

            property bool suppressPopout: false

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                clockPill.showDate = !clockPill.showDate;
                suppressPopout = true;
            }
            onContainsMouseChanged: {
                if (!containsMouse)
                    suppressPopout = false;

            }
            onWheel: (event) => {
                if (!calPopout.showInternal)
                    return ;

                calGrid.shiftMonth(event.angleDelta.y > 0 ? -1 : 1);
                event.accepted = true;
            }
        }

        Popout {
            id: calPopout

            anchorItem: clockPill
            show: (clockMouse.containsMouse && !clockMouse.suppressPopout) || calPopout.popoutHovered
            borderColor: Colors.mauve

            PopoutHeader {
                icon: "󰃭"
                iconColor: Colors.mauve
                title: Qt.formatDate(clock.currentTime, "dddd")
                subtitle: Qt.formatDateTime(clock.currentTime, "dd MMMM yyyy  ·  hh:mm")
            }

            CalendarGrid {
                id: calGrid

                today: clock.currentTime
                active: calPopout.showInternal
            }

            Text {
                text: "click swaps date  ·  wheel changes month"
                color: Colors.overlay0
                font.family: Tokens.fontFamily
                font.pixelSize: 10
            }

        }

    }

    QtObject {
        id: clock

        property date currentTime: new Date()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.currentTime = new Date()
    }

}
