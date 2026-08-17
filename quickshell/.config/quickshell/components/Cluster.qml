import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    default property alias contentData: row.data

    implicitWidth: row.implicitWidth + 20
    implicitHeight: Tokens.pillHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    radius: Tokens.pillRadius
    color: Colors.surface0

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 8
    }

}
