---------------------
---- KEYBINDINGS ----
---------------------

local progs = require("conf/programs")

local mainMod = "SUPER"
local secondMod = "SUPER + SHIFT"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(progs.terminal .. " zsh -l"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(progs.fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(progs.browser))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(progs.launcher))
hl.bind(secondMod .. " + Space", hl.dsp.exec_cmd(progs.runner))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs ipc call powermenu toggle"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-touchpad.sh"))

hl.bind(
	mainMod .. " + V",
	hl.dsp.exec_cmd("qs ipc call launcher openClip")
)

hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copy area"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grimblast --notify copy screen"))
hl.bind(secondMod .. " + Print", hl.dsp.exec_cmd("grimblast --notify save area"))
hl.bind(mainMod .. " + ALT + Print", hl.dsp.exec_cmd("grimblast --notify copysave area - | swappy -f -"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(secondMod .. " + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(secondMod .. " + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(secondMod .. " + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(secondMod .. " + L", hl.dsp.window.move({ direction = "right" }))

hl.bind(secondMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(secondMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-----------------------
---- RESIZE SUBMAP ----
-----------------------

local resizeStep = 40

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
	-- vim-style: h/l width, j/k height (arrow keys mirror them)
	hl.bind("H", hl.dsp.window.resize({ x = -resizeStep, y = 0, relative = true }), { repeating = true })
	hl.bind("L", hl.dsp.window.resize({ x = resizeStep, y = 0, relative = true }), { repeating = true })
	hl.bind("J", hl.dsp.window.resize({ x = 0, y = resizeStep, relative = true }), { repeating = true })
	hl.bind("K", hl.dsp.window.resize({ x = 0, y = -resizeStep, relative = true }), { repeating = true })

	hl.bind("left", hl.dsp.window.resize({ x = -resizeStep, y = 0, relative = true }), { repeating = true })
	hl.bind("right", hl.dsp.window.resize({ x = resizeStep, y = 0, relative = true }), { repeating = true })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = resizeStep, relative = true }), { repeating = true })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -resizeStep, relative = true }), { repeating = true })

	-- Exit the submap.
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("Return", hl.dsp.submap("reset"))
end)

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

---------------------------
---- LAPTOP LID SWITCH ----
---------------------------

-- Lock on lid close. logind may also handle the lid (suspend); this ensures the
-- session is locked before that happens.
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })
