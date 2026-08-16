import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

// Active window title pill — capped width so it never collides with the clock.
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
    readonly property string winTitle: {
        if (!toplevel)
            return "";

        return toplevel.title || (toplevel.wayland && toplevel.wayland.title) || (toplevel.lastIpcObject && toplevel.lastIpcObject.title) || "";
    }
    readonly property string winClass: {
        if (!toplevel)
            return "";

        if (toplevel.lastIpcObject && toplevel.lastIpcObject.class)
            return String(toplevel.lastIpcObject.class);

        if (toplevel.wayland && toplevel.wayland.appId)
            return String(toplevel.wayland.appId);

        return "";
    }
    readonly property bool isFloating: !!(toplevel && toplevel.lastIpcObject && toplevel.lastIpcObject.floating)
    readonly property bool isFullscreen: !!(toplevel && (toplevel.lastIpcObject && (toplevel.lastIpcObject.fullscreen || toplevel.lastIpcObject.fullscreenClient)))
    readonly property string iconSource: iconForClass(winClass)
    readonly property bool hovered: hoverHandler.hovered
    readonly property real labelMax: Math.max(40, maxWidth - 24 - 18 - 6)
    readonly property bool usable: !!toplevel && winTitle.length > 0 && maxWidth > 64

    function iconForClass(cls) {
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

    visible: usable
    height: 28
    width: Math.min(contentRow.width + 24, maxWidth)
    radius: 14
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
        spacing: 6

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
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 14
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

        Text {
            text: "Active window"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
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
                width: 220

                Text {
                    width: parent.width
                    text: root.winTitle || "Untitled"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.winClass || "unknown"
                    color: Colors.mauve
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

            }

        }

        Column {
            spacing: 6
            width: 268

            RowLayout {
                width: parent.width

                Text {
                    text: "Workspace"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: root.toplevel && root.toplevel.workspace ? String(root.toplevel.workspace.id) : "—"
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                }

            }

            RowLayout {
                width: parent.width

                Text {
                    text: "State"
                    color: Colors.overlay0
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        let bits = [];
                        if (root.isFullscreen)
                            bits.push("fullscreen");
                        else if (root.isFloating)
                            bits.push("floating");
                        else
                            bits.push("tiled");
                        return bits.join(" · ");
                    }
                    color: Colors.text
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                }

            }

        }

        Row {
            spacing: 8

            Rectangle {
                width: 84
                height: 28
                radius: 8
                color: floatHover.hovered ? Colors.surface1 : Colors.surface0

                HoverHandler {
                    id: floatHover
                }

                Text {
                    anchors.centerIn: parent
                    text: root.isFloating ? "Tile" : "Float"
                    color: Colors.mauve
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.window.float({ action = \"toggle\" })")
                }

            }

            Rectangle {
                width: 84
                height: 28
                radius: 8
                color: fullHover.hovered ? Colors.surface1 : Colors.surface0

                HoverHandler {
                    id: fullHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "Full"
                    color: Colors.mauve
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.window.fullscreen()")
                }

            }

            Rectangle {
                width: 84
                height: 28
                radius: 8
                color: closeHover.hovered ? Colors.surface1 : Colors.surface0

                HoverHandler {
                    id: closeHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    color: Colors.red
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.window.close()")
                }

            }

        }

    }

}
