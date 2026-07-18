-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("xsettingsd")
	hl.exec_cmd("hyprpolkitagent")
	hl.exec_cmd("waybar")
	hl.exec_cmd("mako")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("~/.config/hypr/scripts/auto-touchpad.sh")
end)
