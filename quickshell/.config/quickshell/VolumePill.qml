import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

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
        // All Material Design Icons — same optical size (mixing FA+MD made some look tiny/huge).
        if (isMuted || volumePercent === 0)
            return "󰝟";

        if (isHeadphone)
            return "󰋋";

        let icons = ["󰕿", "󰖀", "󰕾"];
        let index = Math.min(icons.length - 1, Math.floor(volumePercent / 100 * icons.length));
        return icons[index];
    }

    icon: volumeIcon
    text: isMuted ? "muted" : volumePercent + "%"
    textColor: isMuted ? Colors.overlay0 : Colors.sky

    iconColor: textColor

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
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
            if (!volumePill.sink || !volumePill.sink.audio)
                return ;

            let step = 0.05;
            if (event.angleDelta.y > 0)
                volumePill.sink.audio.volume = Math.min(1, volumePill.sink.audio.volume + step);
            else
                volumePill.sink.audio.volume = Math.max(0, volumePill.sink.audio.volume - step);
        }
    }

}
