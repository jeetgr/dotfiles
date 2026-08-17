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

        let focusedWs = Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace;
        if (focusedWs && t.workspace && t.workspace.id !== focusedWs.id)
            return null;

        return t;
    }
    readonly property string winTitle: Windows.titleOf(toplevel)
    readonly property string winClass: Windows.classOf(toplevel)
    readonly property bool isFloating: !!(toplevel && toplevel.lastIpcObject && toplevel.lastIpcObject.floating)
    readonly property bool isFullscreen: !!(toplevel && toplevel.lastIpcObject && (toplevel.lastIpcObject.fullscreen || toplevel.lastIpcObject.fullscreenClient))
    readonly property string iconSource: Windows.iconForClass(winClass)
    readonly property bool hovered: hoverHandler.hovered
    readonly property real labelMax: Math.max(40, maxWidth - 24 - 18 - 6)
    readonly property bool usable: !!toplevel && winTitle.length > 0 && maxWidth > 64

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

    }

    Popout {
        id: winPopout

        anchorItem: root
        show: root.hovered || winPopout.popoutHovered
        borderColor: Colors.mauve

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
                value: root.toplevel && root.toplevel.workspace ? String(root.toplevel.workspace.id) : "—"
            }

            PopoutRow {
                label: "State"
                value: root.isFullscreen ? "fullscreen" : (root.isFloating ? "floating" : "tiled")
            }

        }

        Row {
            spacing: 8

            PopoutButton {
                text: root.isFloating ? "Tile" : "Float"
                accent: Colors.mauve
                buttonWidth: 84
                onClicked: Hyprland.dispatch("hl.dsp.window.float({ action = \"toggle\" })")
            }

            PopoutButton {
                text: "Full"
                accent: Colors.mauve
                buttonWidth: 84
                onClicked: Hyprland.dispatch("hl.dsp.window.fullscreen()")
            }

            PopoutButton {
                text: "Close"
                accent: Colors.red
                buttonWidth: 84
                onClicked: Hyprland.dispatch("hl.dsp.window.close()")
            }

        }

    }

}
