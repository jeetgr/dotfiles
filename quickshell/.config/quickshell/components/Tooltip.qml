import QtQuick
import Quickshell

PopupWindow {
    id: popup

    required property Item anchorItem
    property string text: ""
    property bool show: false
    property int delayMs: 300
    property bool showInternal: false

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
    visible: showInternal && text.length > 0
    onShowChanged: {
        if (show) {
            delayTimer.restart();
        } else {
            delayTimer.stop();
            showInternal = false;
        }
    }
    onVisibleChanged: {
        if (visible)
            reposition();

    }

    Timer {
        id: delayTimer

        interval: popup.delayMs
        onTriggered: {
            popup.reposition();
            popup.showInternal = true;
        }
    }

    Rectangle {
        id: box

        width: Math.min(420, tipLabel.implicitWidth + 24)
        height: tipLabel.implicitHeight + 16
        radius: 10
        color: Colors.mantle
        border.color: Colors.accent
        border.width: 1

        Text {
            id: tipLabel

            anchors.centerIn: parent
            width: Math.min(396, implicitWidth)
            text: popup.text
            color: Colors.text
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontBody
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignLeft
        }

    }

}
