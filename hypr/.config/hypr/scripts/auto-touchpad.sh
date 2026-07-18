#!/usr/bin/env bash
# Automatically disables the touchpad while the external gaming mouse is
# connected, and re-enables it otherwise. Shares STATE_FILE and the hyprctl
# method with toggle-touchpad.sh so a manual toggle never desyncs; the automatic
# logic re-asserts on the next device add/remove event.

TOUCHPAD="elan0718:00-04f3:30fd-touchpad"
EXTERNAL_MOUSE="instant-usb-gaming-mouse-"

STATE_FILE="/tmp/touchpad_enabled"

set_touchpad() {
    hyprctl keyword "device[$TOUCHPAD]:enabled" "$1" >/dev/null
    echo "$1" >"$STATE_FILE"
}

mouse_present() {
    hyprctl devices -j | jq -e \
        '.mice[] | select(.name == "'"$EXTERNAL_MOUSE"'")' >/dev/null
}

apply_auto() {
    if mouse_present; then
        set_touchpad false
    else
        set_touchpad true
    fi
}

# Initial state
apply_auto

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - UNIX-CONNECT:"$SOCKET" | while read -r event; do
    case "$event" in
    deviceAdded* | deviceRemoved*)
        apply_auto
        ;;
    esac
done
