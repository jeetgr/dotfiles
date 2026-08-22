import QtQuick
import Quickshell

// Hover popout anchored under a bar pill. Stays open while the cursor is on the
// pill or the popout itself (close delay bridges the gap when moving between).
PopupWindow {
    id: popup

    required property Item anchorItem
    property bool show: false
    property int openDelayMs: Tokens.popoutOpenDelayMs
    property int closeDelayMs: Tokens.popoutCloseDelayMs
    property color borderColor: Colors.accent
    property bool showInternal: false
    property bool popoutHovered: hoverHandler.hovered
    default property alias contentData: body.data

    function reposition() {
        if (!anchorItem || !anchorItem.QsWindow || !anchorItem.QsWindow.window)
            return ;

        let pos = anchorItem.QsWindow.contentItem.mapFromItem(anchorItem, 0, 0);
        anchor.rect.x = pos.x + anchorItem.width / 2 - width / 2;
        anchor.rect.y = pos.y + anchorItem.height + 6;
    }

    anchor.window: anchorItem && anchorItem.QsWindow ? anchorItem.QsWindow.window : null
    anchor.rect.width: 1
    anchor.rect.height: 1
    implicitWidth: box.width
    implicitHeight: box.height
    color: "transparent"
    visible: showInternal
    onShowChanged: {
        if (show) {
            closeTimer.stop();
            openTimer.restart();
        } else {
            openTimer.stop();
            closeTimer.restart();
        }
    }
    onVisibleChanged: {
        if (visible)
            reposition();

    }
    onWidthChanged: {
        if (visible)
            reposition();

    }

    Timer {
        id: openTimer

        interval: popup.openDelayMs
        onTriggered: {
            popup.reposition();
            popup.showInternal = true;
        }
    }

    Timer {
        id: closeTimer

        interval: popup.closeDelayMs
        onTriggered: {
            if (!popup.show)
                popup.showInternal = false;

        }
    }

    Rectangle {
        id: box

        width: Math.max(180, body.implicitWidth + 28)
        height: body.implicitHeight + 24
        radius: Tokens.popoutRadius
        color: Colors.mantle
        border.color: popup.borderColor
        border.width: 1

        HoverHandler {
            id: hoverHandler
        }

        Column {
            id: body

            anchors.centerIn: parent
            spacing: Tokens.popoutGap
        }

    }

}
