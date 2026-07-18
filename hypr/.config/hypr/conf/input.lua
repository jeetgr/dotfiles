---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "us",

		repeat_rate = 25,
		repeat_delay = 300,

		follow_mouse = 1,

		sensitivity = 0,

		touchpad = {
			natural_scroll = false,
			disable_while_typing = true,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
