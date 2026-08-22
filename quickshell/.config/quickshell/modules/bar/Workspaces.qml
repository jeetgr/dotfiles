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

    function toggleMagic() {
        Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"magic\")");
        Qt.callLater(() => {
            Hyprland.refreshMonitors();
            Hyprland.refreshToplevels();
            Qt.callLater(root.readMagicVisible);
        });
    }

    function magicWorkspace() {
        let all = Hyprland.workspaces.values || [];
        return all.find((w) => {
            let n = w.name || "";
            return n === "special:magic" || n.indexOf("magic") >= 0;
        });
    }

    function magicWindows() {
        let _w = Hyprland.workspaces;
        let _t = Hyprland.toplevels;
        let ws = root.magicWorkspace();
        if (ws)
            return Windows.collectWindows(ws.id, ws);

        let windows = [];
        let seen = {
        };
        let all = (_t && _t.values) || [];
        for (let i = 0; i < all.length; i++) {
            let t = all[i];
            if (!t || !t.workspace)
                continue;

            let n = t.workspace.name || "";
            if (n.indexOf("magic") < 0)
                continue;

            let title = Windows.titleOf(t);
            let cls = Windows.classOf(t);
            let key = cls + "|" + title;
            if (seen[key])
                continue;

            seen[key] = true;
            windows.push({
                "title": title,
                "className": cls,
                "icon": Windows.iconForToplevel(t)
            });
        }
        return windows;
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
    property bool magicVisible: false

    function readMagicVisible() {
        let mon = Hyprland.focusedMonitor;
        let spec = mon && mon.lastIpcObject && mon.lastIpcObject.specialWorkspace;
        let name = spec && spec.name ? String(spec.name) : "";
        root.magicVisible = name.indexOf("magic") >= 0;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event || event.name !== "activespecial")
                return;

            let data = event.data || "";
            root.magicVisible = data.indexOf("magic") >= 0;
        }
    }

    Component.onCompleted: root.readMagicVisible()

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
                    property bool isUrgent: !!(hyprWorkspace && hyprWorkspace.urgent) && !isActive
                    property bool hovered: mouseArea.containsMouse
                    property var windows: Windows.collectWindows(wsId, hyprWorkspace)
                    property int extraWindows: Math.max(0, windows.length - root.maxWindowIcons)
                    property string statusLabel: isUrgent ? "Urgent" : (isActive ? "Active" : (!isOccupied ? "Empty" : "Occupied"))

                    width: track.cellW
                    height: track.cellH

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: Colors.surface1
                        opacity: {
                            if (wsBtn.hovered && !wsBtn.isActive)
                                return 1;

                            if (wsBtn.isOccupied && !wsBtn.isActive)
                                return 0.4;

                            return 0;
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }

                        }

                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "transparent"
                        border.width: 2
                        border.color: Colors.peach
                        visible: wsBtn.isUrgent
                        opacity: 0.45
                        z: 2

                        SequentialAnimation on opacity {
                            running: wsBtn.isUrgent
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 1
                                duration: 650
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 0.3
                                duration: 650
                                easing.type: Easing.InOutSine
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
                        color: wsBtn.isUrgent ? Colors.peach : ((wsBtn.isActive || wsBtn.hovered) ? Colors.base : Colors.overlay0)

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
                            color: wsBtn.isUrgent ? Colors.peach : ((wsBtn.isActive || wsBtn.hovered) ? Colors.base : Colors.subtext0)
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
                        borderColor: wsBtn.isUrgent ? Colors.peach : Colors.mauve

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

            Rectangle {
                width: 1
                height: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.surface1
            }

            Item {
                id: scratch

                property var hyprWorkspace: root.magicWorkspace()
                property var windows: {
                    let _w = Hyprland.workspaces.values;
                    let _t = Hyprland.toplevels;
                    return root.magicWindows();
                }
                property int extraWindows: Math.max(0, windows.length - root.maxWindowIcons)
                property bool hovered: scratchMouse.containsMouse
                property bool isUrgent: !!(hyprWorkspace && hyprWorkspace.urgent) && !root.magicVisible
                property bool peeking: false

                function beginPeek() {
                    if (scratch.windows.length === 0)
                        return ;

                    if (root.magicVisible) {
                        scratch.peeking = false;
                        return ;
                    }
                    scratch.peeking = true;
                    root.toggleMagic();
                }

                function endPeek() {
                    if (!scratch.peeking)
                        return ;

                    scratch.peeking = false;
                    root.toggleMagic();
                }

                width: track.cellW
                height: track.cellH

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: root.magicVisible ? Colors.lavender : Colors.surface1
                    opacity: {
                        if (root.magicVisible || scratch.hovered)
                            return 1;

                        if (scratch.windows.length > 0)
                            return 0.4;

                        return 0;
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                        }

                    }

                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"
                    border.width: 2
                    border.color: Colors.peach
                    visible: scratch.isUrgent
                    opacity: 0.45
                    z: 2

                    SequentialAnimation on opacity {
                        running: scratch.isUrgent
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 1
                            duration: 650
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 0.3
                            duration: 650
                            easing.type: Easing.InOutSine
                        }

                    }

                }

                Text {
                    anchors.centerIn: parent
                    visible: scratch.windows.length === 0
                    text: "󰘥"
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontIcon
                    color: scratch.isUrgent ? Colors.peach : ((root.magicVisible || scratch.hovered) ? Colors.base : Colors.overlay0)

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                        }

                    }

                }

                Row {
                    anchors.centerIn: parent
                    visible: scratch.windows.length > 0
                    spacing: 1

                    Repeater {
                        model: scratch.extraWindows > 0 ? root.maxWindowIcons - 1 : root.maxWindowIcons

                        IconImage {
                            required property int index

                            visible: index < scratch.windows.length
                            source: visible ? scratch.windows[index].icon : ""
                            implicitSize: scratch.windows.length === 1 && scratch.extraWindows === 0 ? 14 : 11
                            mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                    Text {
                        visible: scratch.extraWindows > 0
                        text: "+" + (scratch.extraWindows + 1)
                        font.family: Tokens.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: scratch.isUrgent ? Colors.peach : ((root.magicVisible || scratch.hovered) ? Colors.base : Colors.subtext0)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Popout {
                    id: magicPopout

                    anchorItem: scratch
                    show: scratch.hovered || magicPopout.popoutHovered
                    borderColor: scratch.isUrgent ? Colors.peach : Colors.lavender
                    onShowInternalChanged: {
                        if (showInternal)
                            scratch.beginPeek();
                        else
                            scratch.endPeek();

                    }

                    PopoutTitle {
                        text: "Scratchpad"
                    }

                    PopoutHeader {
                        title: scratch.isUrgent ? "Urgent" : (root.magicVisible ? "Showing" : (scratch.windows.length === 0 ? "Empty" : "Hidden"))
                        subtitle: scratch.windows.length + (scratch.windows.length === 1 ? " window" : " windows")
                    }

                    Column {
                        visible: scratch.windows.length > 0
                        spacing: Tokens.rowGap
                        width: 260

                        Repeater {
                            model: scratch.windows

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
                        visible: scratch.windows.length === 0
                        text: "Nothing parked · Super+Shift+S to send"
                        color: Colors.overlay0
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontCaption
                    }

                    Text {
                        text: "L-click toggle · hover peek · R-click move"
                        color: Colors.overlay0
                        font.family: Tokens.fontFamily
                        font.pixelSize: 10
                    }

                }

                MouseArea {
                    id: scratchMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            Hyprland.dispatch("hl.dsp.window.move({ workspace = \"special:magic\" })");
                            return ;
                        }
                        if (scratch.peeking) {
                            scratch.peeking = false;
                            return ;
                        }
                        root.toggleMagic();
                    }
                }

            }

        }

    }

}
