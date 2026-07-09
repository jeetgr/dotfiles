#!/usr/bin/env bash

options=" Lock\n󰍃 Logout\n󰒲 Suspend\n Reboot\n⏻ Shutdown"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "" -theme ~/.config/rofi/powermenu.rasi) || pkill rofi

case "$chosen" in
*Lock) hyprlock ;;
*Logout) hyprctl dispatch exit ;;
*Suspend) systemctl suspend ;;
*Reboot) systemctl reboot ;;
*Shutdown) systemctl poweroff ;;
esac
