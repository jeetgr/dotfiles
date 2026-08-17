import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services

Pill {
    id: micPill

    property var source: Pipewire.defaultAudioSource
    property int volumePercent: source && source.audio ? Math.round(source.audio.volume * 100) : 0
    property bool isMuted: source && source.audio ? source.audio.muted : true
    property string micIcon: (isMuted || volumePercent === 0) ? "󰍭" : "󰍬"
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

    function nudge(delta) {
        if (!source || !source.audio)
            return ;

        source.audio.volume = Math.max(0, Math.min(1, source.audio.volume + delta));
    }

    icon: micIcon
    text: ""
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

        PopoutTitle {
            text: "Microphone"
        }

        Text {
            width: Tokens.popoutWidth
            text: micPill.sourceLabel
            color: Colors.text
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontBody
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        SliderBar {
            icon: micPill.micIcon
            accent: micPill.isMuted ? Colors.overlay0 : Colors.pink
            value: micPill.isMuted ? 0 : volumePercent / 100
            valueText: micPill.isMuted ? "mute" : (micPill.volumePercent + "%")
            onIconClicked: {
                if (micPill.source && micPill.source.audio)
                    micPill.source.audio.muted = !micPill.source.audio.muted;

            }
            onSetFromX: (x, width) => {
                return micPill.setVolumeFromX(x, width);
            }
            onWheeled: (event) => {
                return micPill.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05);
            }
        }

        PopoutButton {
            text: "Open mixer"
            accent: Colors.pink
            onClicked: Quickshell.execDetached(["pwvucontrol"])
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
            return micPill.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05);
        }
    }

}
