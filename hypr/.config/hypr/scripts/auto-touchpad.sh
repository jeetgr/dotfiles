#!/usr/bin/env bash

TOUCHPAD="elan0718:00-04f3:30fd-touchpad"
EXTERNAL_MOUSE="instant-usb-gaming-mouse-"

set_touchpad() {
    hyprctl keyword "device[$TOUCHPAD]:enabled" "$1" >/dev/null
}

toggle() {
    if hyprctl devices -j | jq -e \
        '.mice[] | select(.name == "'"$EXTERNAL_MOUSE"'")' >/dev/null; then
        set_touchpad false
    else
        set_touchpad true
    fi
}

# Initial state
toggle

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - UNIX-CONNECT:"$SOCKET" | while read -r event; do
    case "$event" in
    deviceAdded* | deviceRemoved*)
        toggle
        ;;
    esac
done
