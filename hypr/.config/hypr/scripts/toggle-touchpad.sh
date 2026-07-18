#!/usr/bin/env bash
# Manually toggle the touchpad on/off. Shares STATE_FILE and the hyprctl method
# with auto-touchpad.sh so the two never desync: it reads the last applied state,
# flips it, and writes it back. The automatic logic re-asserts on the next device
# add/remove event.

TOUCHPAD="elan0718:00-04f3:30fd-touchpad"

STATE_FILE="/tmp/touchpad_enabled"

CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo true)
NEW=$([[ "$CURRENT" == "true" ]] && echo false || echo true)

hyprctl keyword "device[$TOUCHPAD]:enabled" "$NEW" >/dev/null
echo "$NEW" >"$STATE_FILE"
