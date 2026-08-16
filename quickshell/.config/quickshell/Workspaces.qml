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
                property string tooltipText: {
                    let tip = "Workspace " + wsId;
                    if (isActive)
                        tip += "  ·  active";
                    else if (!isOccupied)
                        tip += "  ·  empty";

                    if (hyprWorkspace) {
                        if (hyprWorkspace.urgent)
                            tip += "\nUrgent window";
                        if (hyprWorkspace.hasFullscreen)
                            tip += "\nFullscreen";
                        if (hyprWorkspace.monitor && hyprWorkspace.monitor.name)
                            tip += "\nMonitor: " + hyprWorkspace.monitor.name;
                    }

                    let titles = wsBtn.collectTitles();
                    if (titles.length > 0)
                        tip += "\n\n" + titles.join("\n");
                    else if (isOccupied)
                        tip += "\n\n(no window titles)";

                    return tip;
                }

                function collectTitles() {
                    let titles = [];
                    let seen = {};

                    function addTitle(raw) {
                        if (!raw || raw.length === 0)
                            return;
                        let title = raw.length > 42 ? raw.substring(0, 42) + "…" : raw;
                        if (seen[title])
                            return;
                        seen[title] = true;
                        titles.push("•  " + title);
                    }

                    if (hyprWorkspace && hyprWorkspace.toplevels) {
                        let list = hyprWorkspace.toplevels.values || [];
                        for (let i = 0; i < list.length; i++) {
                            let t = list[i];
                            addTitle(t.title || (t.wayland && t.wayland.title) || (t.lastIpcObject && t.lastIpcObject.title) || "");
                        }
                    }

                    if (titles.length === 0 && Hyprland.toplevels) {
                        let all = Hyprland.toplevels.values || [];
                        for (let i = 0; i < all.length; i++) {
                            let t = all[i];
                            if (t.workspace && t.workspace.id === wsId)
                                addTitle(t.title || (t.wayland && t.wayland.title) || (t.lastIpcObject && t.lastIpcObject.title) || "");
                        }
                    }

                    return titles;
                }

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

                Tooltip {
                    anchorItem: wsBtn
                    text: wsBtn.tooltipText
                    show: wsBtn.hovered
                    delayMs: 250
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
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsBtn.wsId + " })");
                    }
                }

            }

        }

    }

}
