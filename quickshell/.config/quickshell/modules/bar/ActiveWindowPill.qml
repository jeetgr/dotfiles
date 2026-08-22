import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.services

Rectangle {
    id: root

    property real maxWidth: 220
    readonly property var toplevel: {
        let t = Hyprland.activeToplevel;
        if (!t)
            return null;

        let name = t.workspace && t.workspace.name ? String(t.workspace.name) : "";
        if (name.indexOf("magic") >= 0)
            return t;

        let focusedWs = Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace;
        if (focusedWs && t.workspace && t.workspace.id !== focusedWs.id)
            return null;

        return t;
    }
    readonly property string winTitle: Windows.titleOf(toplevel)
    readonly property string winClass: Windows.classOf(toplevel)
    readonly property var ipc: toplevel && toplevel.lastIpcObject ? toplevel.lastIpcObject : null
    readonly property bool isFloating: !!(ipc && ipc.floating)
    readonly property bool isFullscreen: !!(ipc && (ipc.fullscreen || ipc.fullscreenClient))
    readonly property bool isPinned: !!(ipc && ipc.pinned)
    readonly property bool isOnScratch: {
        let n = toplevel && toplevel.workspace && toplevel.workspace.name;
        return !!(n && String(n).indexOf("magic") >= 0);
    }
    readonly property string workspaceLabel: {
        if (root.isOnScratch)
            return "scratchpad";

        if (root.toplevel && root.toplevel.workspace)
            return String(root.toplevel.workspace.id);

        return "—";
    }
    readonly property string stateLabel: {
        let bits = [];
        if (root.isFullscreen)
            bits.push("fullscreen");
        else if (root.isFloating)
            bits.push("floating");
        else
            bits.push("tiled");

        if (root.isPinned)
            bits.push("pinned");

        return bits.join(" · ");
    }
    readonly property string iconSource: Windows.iconForClass(winClass)
    readonly property bool hovered: hoverHandler.hovered
    readonly property real labelMax: Math.max(40, maxWidth - 24 - 18 - 6 - (isPinned ? 18 : 0))
    readonly property bool usable: !!toplevel && winTitle.length > 0 && maxWidth > 64

    function refresh() {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
    }

    function run(cmd) {
        Hyprland.dispatch(cmd);
        Qt.callLater(root.refresh);
    }

    function togglePin() {
        if (root.isPinned) {
            root.run("hl.dsp.window.pin({ action = \"disable\" })");
            return ;
        }
        if (!root.isFloating)
            Hyprland.dispatch("hl.dsp.window.float({ action = \"enable\" })");

        root.run("hl.dsp.window.pin({ action = \"enable\" })");
    }

    function toggleScratch() {
        if (root.isOnScratch) {
            let ws = Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace;
            let id = ws && ws.id > 0 ? ws.id : 1;
            root.run("hl.dsp.window.move({ workspace = " + id + " })");
            return ;
        }
        root.run("hl.dsp.window.move({ workspace = \"special:magic\" })");
    }

    visible: usable
    height: Tokens.pillHeight
    width: Math.min(contentRow.width + 24, maxWidth)
    radius: Tokens.pillRadius
    color: Colors.surface0
    clip: true

    HoverHandler {
        id: hoverHandler
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colors.surface1
        opacity: root.hovered ? 1 : 0
        z: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }

        }

    }

    Row {
        id: contentRow

        z: 2
        anchors.centerIn: parent
        spacing: Tokens.rowGap

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            source: root.iconSource
            implicitSize: 16
            mipmap: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.labelMax)
            text: root.winTitle
            color: Colors.text
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontLabel
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
            wrapMode: Text.NoWrap
            clip: true
        }

        Text {
            visible: root.isPinned
            anchors.verticalCenter: parent.verticalCenter
            text: "󰐃"
            color: Colors.peach
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontCaption
        }

    }

    Popout {
        id: winPopout

        anchorItem: root
        show: root.hovered || winPopout.popoutHovered
        borderColor: root.isPinned ? Colors.peach : (root.isOnScratch ? Colors.lavender : Colors.mauve)
        onShowInternalChanged: {
            if (showInternal)
                root.refresh();

        }

        PopoutTitle {
            text: "Active window"
        }

        Row {
            spacing: 12

            IconImage {
                source: root.iconSource
                implicitSize: 36
                mipmap: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.popoutWidth

                Text {
                    width: parent.width
                    text: root.winTitle || "Untitled"
                    color: Colors.text
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontTitle
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.winClass || "unknown"
                    color: Colors.mauve
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontBody
                    elide: Text.ElideRight
                }

            }

        }

        Column {
            spacing: Tokens.rowGap
            width: 268

            PopoutRow {
                label: "Workspace"
                value: root.workspaceLabel
            }

            PopoutRow {
                label: "State"
                value: root.stateLabel
                valueColor: root.isPinned ? Colors.peach : Colors.text
            }

        }

        Row {
            spacing: 8

            PopoutButton {
                text: root.isFloating ? "Tile" : "Float"
                accent: Colors.mauve
                buttonWidth: 84
                onClicked: root.run("hl.dsp.window.float({ action = \"toggle\" })")
            }

            PopoutButton {
                text: "Full"
                accent: Colors.mauve
                buttonWidth: 84
                onClicked: root.run("hl.dsp.window.fullscreen()")
            }

            PopoutButton {
                text: "Close"
                accent: Colors.red
                buttonWidth: 84
                onClicked: root.run("hl.dsp.window.close()")
            }

        }

        Row {
            spacing: 8

            PopoutButton {
                text: root.isOnScratch ? "Restore" : "Scratch"
                icon: "󰘥"
                accent: Colors.lavender
                buttonWidth: 130
                onClicked: root.toggleScratch()
            }

            PopoutButton {
                text: root.isPinned ? "Unpin" : "Pin"
                icon: root.isPinned ? "󰐃" : "󰤱"
                accent: root.isPinned ? Colors.peach : Colors.mauve
                buttonWidth: 130
                onClicked: root.togglePin()
            }

        }

    }

}
