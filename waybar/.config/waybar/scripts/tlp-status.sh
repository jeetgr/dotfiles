#!/usr/bin/env bash
ac_path=$(find /sys/class/power_supply -maxdepth 1 -iname "A*" | head -n1)

if [ -n "$ac_path" ] && [ "$(cat "$ac_path/online" 2>/dev/null)" = "1" ]; then
    mode="AC"
    icon="󰚥"
else
    mode="BAT"
    icon="󰁹"
fi

echo "{\"text\": \"$icon $mode\", \"tooltip\": \"Power mode: $mode (TLP managed)\"}"
