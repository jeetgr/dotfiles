import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.services

Rectangle {
    id: root

    required property var modelData
    property bool compact: false

    readonly property var n: modelData
    readonly property color accent: Notifications.accent(n)
    readonly property string iconSrc: Notifications.iconSource(n)
    readonly property bool hasIcon: iconSrc.length > 0

    width: parent ? parent.width : 380
    implicitHeight: bodyCol.implicitHeight + 20
    radius: 12
    color: hover.hovered ? Colors.surface0 : Colors.base
    border.color: Colors.surface0
    border.width: 1
    clip: true

    HoverHandler {
        id: hover
    }

    Rectangle {
        width: 3
        height: parent.height - 12
        radius: 2
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        color: root.accent
    }

    ColumnLayout {
        id: bodyCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        anchors.topMargin: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                IconImage {
                    anchors.fill: parent
                    visible: root.hasIcon
                    source: root.iconSrc
                    mipmap: true
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !root.hasIcon
                    radius: 8
                    color: Colors.surface0

                    Text {
                        anchors.centerIn: parent
                        text: "󰂚"
                        color: root.accent
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontIcon
                    }

                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: Notifications.appLabel(root.n)
                    color: Colors.overlay0
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontCaption
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: (root.n && root.n.summary) || ""
                    color: Colors.text
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.fontTitle
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

            }

            Text {
                text: "󰅖"
                color: hover.hovered ? Colors.red : Colors.overlay0
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.fontIcon
                Layout.alignment: Qt.AlignTop

                MouseArea {
                    z: 2
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.dismiss(root.n)
                }

            }

        }

        Text {
            Layout.fillWidth: true
            visible: !!(root.n && root.n.body && root.n.body.length)
            text: (root.n && root.n.body) || ""
            color: Colors.subtext0
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontBody
            wrapMode: Text.WordWrap
            maximumLineCount: root.compact ? 2 : 6
            elide: Text.ElideRight
            textFormat: Text.StyledText
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: root.n && root.n.actions && root.n.actions.length > 0

            Repeater {
                model: root.n ? root.n.actions : []

                Rectangle {
                    required property var modelData

                    implicitWidth: actionLabel.implicitWidth + 16
                    implicitHeight: 24
                    radius: 8
                    color: actionHover.hovered ? Colors.surface1 : Colors.surface0

                    HoverHandler {
                        id: actionHover
                    }

                    Text {
                        id: actionLabel

                        anchors.centerIn: parent
                        text: modelData.text || "Open"
                        color: root.accent
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.fontCaption
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        z: 2
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData && modelData.invoke)
                                modelData.invoke();
                        }
                    }

                }

            }

        }

    }

}
