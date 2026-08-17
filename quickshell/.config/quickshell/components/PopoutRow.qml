import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string label: ""
    property string value: "—"
    property color valueColor: Colors.text
    property bool rowVisible: true

    width: parent ? parent.width : Tokens.popoutWidthWide
    visible: rowVisible
    spacing: 8

    Text {
        text: root.label
        color: Colors.overlay0
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.fontCaption
    }

    Text {
        Layout.fillWidth: true
        text: root.value
        color: root.valueColor
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.fontCaption
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
    }

}
