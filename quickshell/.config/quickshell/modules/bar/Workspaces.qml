import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.services

Rectangle {
    id: root

    readonly property int maxWindowIcons: 2
    readonly property int wsCount: 5

    function focusWorkspace(wsId) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })");
    }

    function activeWorkspaceId() {
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace)
            return Hyprland.focusedMonitor.activeWorkspace.id;

        return 1;
    }

    function scrollWorkspaces(angleY) {
        let current = root.activeWorkspaceId();
        let next = angleY > 0 ? current - 1 : current + 1;
        next = Math.max(1, Math.min(root.wsCount, next));
        if (next !== current)
            root.focusWorkspace(next);

    }

    implicitWidth: row.implicitWidth + 12
    implicitHeight: Tokens.pillHeight
    width: implicitWidth
    height: implicitHeight
    radius: Tokens.pillRadius
    color: Colors.surface0

    Item {
        id: track

        readonly property int cellW: 28
        readonly property int cellH: 20
        readonly property int gap: 3
        readonly property int stride: cellW + gap
        readonly property int activeIndex: Math.max(0, Math.min(root.wsCount - 1, root.activeWorkspaceId() - 1))

        anchors.centerIn: parent
        width: row.implicitWidth
        height: cellH

        Rectangle {
            id: activePill

            width: track.cellW
            height: track.cellH
            radius: 10
            color: Colors.accent
            x: track.activeIndex * track.stride
            z: 0

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }

            }

        }

        Row {
            id: row

            spacing: track.gap
            z: 1

            Repeater {
                model: root.wsCount

                Item {
                    id: wsBtn

                    required property int index
                    property int wsId: index + 1
                    property var hyprWorkspace: Hyprland.workspaces.values.find((w) => {
                        return w.id === wsId;
                    })
                    property bool isActive: Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace && Hyprland.focusedMonitor.activeWorkspace.id === wsId
                    property bool isOccupied: hyprWorkspace !== undefined
                    property bool hovered: mouseArea.containsMouse
                    property var windows: Windows.collectWindows(wsId, hyprWorkspace)
                    property int extraWindows: Math.max(0, windows.length - root.maxWindowIcons)
                    property string statusLabel: isActive ? "Active" : (!isOccupied ? "Empty" : "Occupied")

                    width: track.cellW
                    height: track.cellH

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: Colors.surface1
                        opacity: wsBtn.hovered && !wsBtn.isActive ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }

                        }

                    }

                    Text {
                        anchors.centerIn: parent
                        visible: wsBtn.windows.length === 0
                        text: wsBtn.wsId
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontLabel
                        font.weight: Font.DemiBold
                        color: (wsBtn.isActive || wsBtn.hovered) ? Colors.base : Colors.overlay0

                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                            }

                        }

                    }

                    Row {
                        anchors.centerIn: parent
                        visible: wsBtn.windows.length > 0
                        spacing: 1

                        Repeater {
                            model: wsBtn.extraWindows > 0 ? root.maxWindowIcons - 1 : root.maxWindowIcons

                            IconImage {
                                required property int index

                                visible: index < wsBtn.windows.length
                                source: visible ? wsBtn.windows[index].icon : ""
                                implicitSize: wsBtn.windows.length === 1 && wsBtn.extraWindows === 0 ? 14 : 11
                                mipmap: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                        Text {
                            visible: wsBtn.extraWindows > 0
                            text: "+" + (wsBtn.extraWindows + 1)
                            font.family: Tokens.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: (wsBtn.isActive || wsBtn.hovered) ? Colors.base : Colors.subtext0
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                }

                            }

                        }

                    }

                    Popout {
                        id: wsPopout

                        anchorItem: wsBtn
                        show: wsBtn.hovered || wsPopout.popoutHovered
                        borderColor: Colors.mauve

                        PopoutTitle {
                            text: "Workspace " + wsBtn.wsId
                        }

                        PopoutHeader {
                            title: wsBtn.statusLabel
                            subtitle: {
                                let bits = [];
                                if (wsBtn.hyprWorkspace && wsBtn.hyprWorkspace.urgent)
                                    bits.push("urgent");

                                if (wsBtn.hyprWorkspace && wsBtn.hyprWorkspace.hasFullscreen)
                                    bits.push("fullscreen");

                                if (wsBtn.hyprWorkspace && wsBtn.hyprWorkspace.monitor && wsBtn.hyprWorkspace.monitor.name)
                                    bits.push(wsBtn.hyprWorkspace.monitor.name);

                                if (bits.length === 0)
                                    return wsBtn.windows.length + (wsBtn.windows.length === 1 ? " window" : " windows");

                                return bits.join("  ·  ");
                            }
                        }

                        Column {
                            visible: wsBtn.windows.length > 0
                            spacing: Tokens.rowGap
                            width: 260

                            Repeater {
                                model: wsBtn.windows

                                Row {
                                    required property var modelData

                                    spacing: 8
                                    width: 260

                                    IconImage {
                                        source: modelData.icon
                                        implicitSize: 16
                                        mipmap: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        spacing: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 24

                                        Text {
                                            width: parent.width
                                            text: modelData.title || modelData.className || "Untitled"
                                            color: Colors.text
                                            font.family: Tokens.fontFamily
                                            font.pixelSize: Tokens.fontBody
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: modelData.className.length > 0 && modelData.title.length > 0
                                            width: parent.width
                                            text: modelData.className
                                            color: Colors.overlay0
                                            font.family: Tokens.fontFamily
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }

                                    }

                                }

                            }

                        }

                        Text {
                            visible: wsBtn.windows.length === 0
                            text: "No windows on this workspace"
                            color: Colors.overlay0
                            font.family: Tokens.fontFamily
                            font.pixelSize: Tokens.fontCaption
                        }

                        Text {
                            text: "L-click focus · R-click move · scroll switch"
                            color: Colors.overlay0
                            font.family: Tokens.fontFamily
                            font.pixelSize: 10
                        }

                    }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton)
                                Hyprland.dispatch("hl.dsp.window.move({ workspace = " + wsBtn.wsId + " })");
                            else
                                root.focusWorkspace(wsBtn.wsId);
                        }
                        onWheel: (event) => {
                            root.scrollWorkspaces(event.angleDelta.y);
                            event.accepted = true;
                        }
                    }

                }

            }

        }

    }

}
