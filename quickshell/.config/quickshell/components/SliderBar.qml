import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string icon: ""
    property color accent: Colors.sky
    property real value: 0
    property string valueText: ""
    property int barWidth: Tokens.popoutWidth

    signal iconClicked()
    signal setFromX(real x, real width)
    signal wheeled(var event)

    width: barWidth
    spacing: 10

    Text {
        text: root.icon
        color: root.accent
        font.family: Tokens.fontFamily
        font.pixelSize: 18
        Layout.alignment: Qt.AlignVCenter

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }

    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter

        MeterBar {
            anchors.verticalCenter: parent.verticalCenter
            barWidth: parent.width
            value: root.value
            fill: root.accent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: (mouse) => {
                return root.setFromX(mouse.x, width);
            }
            onPositionChanged: (mouse) => {
                if (pressed)
                    root.setFromX(mouse.x, width);

            }
            onWheel: (event) => {
                return root.wheeled(event);
            }
        }

    }

    Text {
        text: root.valueText
        color: root.accent === Colors.overlay0 ? Colors.overlay0 : Colors.text
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.fontBody
        font.weight: Font.DemiBold
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
    }

}
