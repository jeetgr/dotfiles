import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

// Outer surface0 chip; button size is fixed (no grow when windows appear).
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

    function iconForToplevel(t) {
        let cls = "";
        if (t.lastIpcObject && t.lastIpcObject.class)
            cls = String(t.lastIpcObject.class);
        else if (t.wayland && t.wayland.appId)
            cls = String(t.wayland.appId);
        if (!cls)
            return Quickshell.iconPath("application-x-executable");

        if (Quickshell.hasThemeIcon(cls))
            return Quickshell.iconPath(cls);

        let lower = cls.toLowerCase();
        if (Quickshell.hasThemeIcon(lower))
            return Quickshell.iconPath(lower);

        let shortName = lower.split(".").pop();
        if (shortName && Quickshell.hasThemeIcon(shortName))
            return Quickshell.iconPath(shortName);

        return Quickshell.iconPath(cls, "application-x-executable");
    }

    function collectWindows(wsId, hyprWorkspace) {
        function addWindow(t) {
            if (!t)
                return ;

            let title = t.title || (t.wayland && t.wayland.title) || (t.lastIpcObject && t.lastIpcObject.title) || "";
            let cls = (t.lastIpcObject && t.lastIpcObject.class) || (t.wayland && t.wayland.appId) || "";
            let key = (cls || "") + "|" + (title || "");
            if (seen[key])
                return ;

            seen[key] = true;
            windows.push({
                "title": title,
                "className": cls,
                "icon": root.iconForToplevel(t)
            });
        }

        let windows = [];
        let seen = {
        };
        if (hyprWorkspace && hyprWorkspace.toplevels) {
            let list = hyprWorkspace.toplevels.values || [];
            for (let i = 0; i < list.length; i++) addWindow(list[i])
        }
        if (windows.length === 0 && Hyprland.toplevels) {
            let all = Hyprland.toplevels.values || [];
            for (let i = 0; i < all.length; i++) {
                let t = all[i];
                if (t.workspace && t.workspace.id === wsId)
                    addWindow(t);

            }
        }
        return windows;
    }

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
            model: root.wsCount

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
                property var windows: root.collectWindows(wsId, hyprWorkspace)
                property int extraWindows: Math.max(0, windows.length - root.maxWindowIcons)
                property string statusLabel: {
                    if (isActive)
                        return "Active";

                    if (!isOccupied)
                        return "Empty";

                    return "Occupied";
                }

                // Fixed width so empty (number) vs occupied (icons) doesn't shift layout.
                Layout.preferredWidth: 28
                Layout.preferredHeight: 20
                Layout.maximumWidth: 28
                Layout.minimumWidth: 28
                radius: 10
                color: (isActive || hovered) ? Colors.accent : "transparent"

                // Empty → number only. Occupied → icons only (no number + icon clutter).
                Text {
                    anchors.centerIn: parent
                    visible: wsBtn.windows.length === 0
                    text: wsBtn.wsId
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: (wsBtn.isActive || wsBtn.hovered) ? Colors.base : Colors.overlay0

                    Behavior on color {
                        ColorAnimation {
                            duration: 250
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
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: (wsBtn.isActive || wsBtn.hovered) ? Colors.base : Colors.subtext0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Popout {
                    id: wsPopout

                    anchorItem: wsBtn
                    show: wsBtn.hovered || wsPopout.popoutHovered
                    borderColor: Colors.mauve

                    Text {
                        text: "Workspace " + wsBtn.wsId
                        color: Colors.subtext0
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Row {
                        spacing: 10

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 8
                            color: wsBtn.isActive ? Colors.accent : Colors.surface0

                            Text {
                                anchors.centerIn: parent
                                text: wsBtn.wsId
                                color: wsBtn.isActive ? Colors.base : Colors.text
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                        }

                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: wsBtn.statusLabel
                                color: Colors.text
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: {
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
                                color: Colors.subtext0
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 11
                            }

                        }

                    }

                    Column {
                        visible: wsBtn.windows.length > 0
                        spacing: 6
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
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: modelData.className.length > 0 && modelData.title.length > 0
                                        width: parent.width
                                        text: modelData.className
                                        color: Colors.overlay0
                                        font.family: "JetBrainsMono Nerd Font Propo"
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
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                    }

                    Text {
                        text: "L-click focus · R-click move · scroll switch"
                        color: Colors.overlay0
                        font.family: "JetBrainsMono Nerd Font Propo"
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

                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }

                }

            }

        }

    }

}
