import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Pill {
    id: micPill

    property var source: Pipewire.defaultAudioSource
    property int volumePercent: source && source.audio ? Math.round(source.audio.volume * 100) : 0
    property bool isMuted: source && source.audio ? source.audio.muted : true
    property string micIcon: {
        if (isMuted || volumePercent === 0)
            return "󰍭";

        let icons = ["󰍬", "󰍬", "󰍬"];
        return icons[Math.min(2, Math.floor(volumePercent / 100 * icons.length))];
    }
    property string sourceLabel: {
        if (!source)
            return "No input device";

        return source.description || source.nickname || source.name || "Microphone";
    }

    function setVolumeFromX(x, width) {
        if (!source || !source.audio || width <= 0)
            return ;

        source.audio.volume = Math.max(0, Math.min(1, x / width));
    }

    icon: micIcon
    text: isMuted ? "mute" : volumePercent + "%"
    textColor: isMuted ? Colors.overlay0 : Colors.pink
    iconColor: textColor

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }

    Popout {
        id: micPopout

        anchorItem: micPill
        show: micPill.hovered || micPopout.popoutHovered
        borderColor: Colors.pink

        Text {
            text: "Microphone"
            color: Colors.subtext0
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Text {
            width: 220
            text: micPill.sourceLabel
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        RowLayout {
            width: 220
            spacing: 10

            Text {
                text: micPill.micIcon
                color: micPill.isMuted ? Colors.overlay0 : Colors.pink
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (micPill.source && micPill.source.audio)
                            micPill.source.audio.muted = !micPill.source.audio.muted;

                    }
                }

            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Colors.surface0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (micPill.isMuted ? 0 : (micPill.volumePercent / 100))
                        radius: parent.radius
                        color: micPill.isMuted ? Colors.overlay0 : Colors.pink
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => {
                        return micPill.setVolumeFromX(mouse.x, width);
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed)
                            micPill.setVolumeFromX(mouse.x, width);

                    }
                    onWheel: (event) => {
                        if (!micPill.source || !micPill.source.audio)
                            return ;

                        let step = 0.05;
                        if (event.angleDelta.y > 0)
                            micPill.source.audio.volume = Math.min(1, micPill.source.audio.volume + step);
                        else
                            micPill.source.audio.volume = Math.max(0, micPill.source.audio.volume - step);
                    }
                }

            }

            Text {
                text: micPill.isMuted ? "mute" : (micPill.volumePercent + "%")
                color: micPill.isMuted ? Colors.overlay0 : Colors.text
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }

        }

        Rectangle {
            width: 220
            height: 28
            radius: 8
            color: mixerHover.hovered ? Colors.surface1 : Colors.surface0

            HoverHandler {
                id: mixerHover
            }

            Text {
                anchors.centerIn: parent
                text: "Open mixer"
                color: Colors.pink
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["pwvucontrol"])
            }

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }

            }

        }

    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["pwvucontrol"]);
                return ;
            }
            if (micPill.source && micPill.source.audio)
                micPill.source.audio.muted = !micPill.source.audio.muted;

        }
        onWheel: (event) => {
            if (!micPill.source || !micPill.source.audio)
                return ;

            let step = 0.05;
            if (event.angleDelta.y > 0)
                micPill.source.audio.volume = Math.min(1, micPill.source.audio.volume + step);
            else
                micPill.source.audio.volume = Math.max(0, micPill.source.audio.volume - step);
        }
    }

}
