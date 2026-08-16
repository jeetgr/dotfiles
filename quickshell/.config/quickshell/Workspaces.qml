import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// Outer surface0 chip; button size is fixed (no grow when active — avoids layout shift).
Rectangle {
    id: root

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    radius: 14
    color: Colors.surface0

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: 5

            Rectangle {
                id: wsBtn

                required property int index
                property int wsId: index + 1
                property var hyprWorkspace: Hyprland.workspaces.values.find((w) => {
                    return w.id === wsId;
                })
                property bool isActive: Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace && Hyprland.focusedMonitor.activeWorkspace.id === wsId
                property bool isOccupied: hyprWorkspace !== undefined
                property bool hovered: mouseArea.containsMouse

                Layout.preferredWidth: 28
                Layout.preferredHeight: 20
                Layout.maximumWidth: 28
                Layout.minimumWidth: 28
                radius: 10
                color: (isActive || hovered) ? Colors.accent : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: wsBtn.wsId
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: (wsBtn.isActive || wsBtn.hovered) ? Colors.base : (wsBtn.isOccupied ? Colors.green : Colors.overlay0)

                    Behavior on color {
                        ColorAnimation {
                            duration: 250
                        }
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsBtn.wsId + " })")
                }

            }

        }

    }

}
