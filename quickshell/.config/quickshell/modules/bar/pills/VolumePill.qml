import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.services

Pill {
    id: volumePill

    property var sink: Pipewire.defaultAudioSink
    property int volumePercent: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    property bool isMuted: sink && sink.audio ? sink.audio.muted : false
    property bool isHeadphone: {
        if (!sink)
            return false;

        let label = ((sink.nickname || "") + " " + (sink.name || "") + " " + (sink.description || "")).toLowerCase();
        return label.includes("headphone") || label.includes("headset");
    }
    property string volumeIcon: {
        if (isMuted || volumePercent === 0)
            return "󰝟";

        if (isHeadphone)
            return "󰋋";

        let icons = ["󰕿", "󰖀", "󰕾"];
        return icons[Math.min(icons.length - 1, Math.floor(volumePercent / 100 * icons.length))];
    }
    property bool osdReady: false
    property string sinkLabel: {
        if (!sink)
            return "No output device";

        return sink.description || sink.nickname || sink.name || "Output";
    }

    function showOsd() {
        Osd.pushVolume(volumePercent, isMuted, isHeadphone);
    }

    function setVolumeFromX(x, width) {
        if (!sink || !sink.audio || width <= 0)
            return ;

        sink.audio.volume = Math.max(0, Math.min(1, x / width));
    }

    function nudge(delta) {
        if (!sink || !sink.audio)
            return ;

        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta));
    }

    icon: volumeIcon
    text: isMuted ? "muted" : volumePercent + "%"
    textColor: isMuted ? Colors.overlay0 : Colors.sky
    iconColor: textColor
    Component.onCompleted: Qt.callLater(() => {
        volumePill.osdReady = true;
    })

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        function onVolumeChanged() {
            if (volumePill.osdReady)
                volumePill.showOsd();

        }

        function onMutedChanged() {
            if (volumePill.osdReady)
                volumePill.showOsd();

        }

        target: volumePill.sink && volumePill.sink.audio ? volumePill.sink.audio : null
    }

    Popout {
        id: volumePopout

        anchorItem: volumePill
        show: volumePill.hovered || volumePopout.popoutHovered
        borderColor: Colors.sky

        PopoutTitle {
            text: "Volume"
        }

        Text {
            width: Tokens.popoutWidth
            text: volumePill.sinkLabel
            color: Colors.text
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.fontBody
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        SliderBar {
            icon: volumePill.volumeIcon
            accent: volumePill.isMuted ? Colors.overlay0 : Colors.sky
            value: volumePill.isMuted ? 0 : volumePercent / 100
            valueText: volumePill.isMuted ? "mute" : (volumePill.volumePercent + "%")
            onIconClicked: {
                if (volumePill.sink && volumePill.sink.audio)
                    volumePill.sink.audio.muted = !volumePill.sink.audio.muted;

            }
            onSetFromX: (x, width) => {
                return volumePill.setVolumeFromX(x, width);
            }
            onWheeled: (event) => {
                return volumePill.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05);
            }
        }

        PopoutButton {
            text: "Open mixer"
            accent: Colors.sky
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
            if (volumePill.sink && volumePill.sink.audio)
                volumePill.sink.audio.muted = !volumePill.sink.audio.muted;

        }
        onWheel: (event) => {
            return volumePill.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05);
        }
    }

}
