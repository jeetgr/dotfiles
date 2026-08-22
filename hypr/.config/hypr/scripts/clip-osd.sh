#!/usr/bin/env bash
# Print one line for the current clipboard. Used by `wl-paste --watch`.
types=$(wl-paste -l 2>/dev/null || true)
if printf '%s\n' "$types" | grep -q '^image/'; then
	printf 'image\n'
	exit 0
fi
text=$(wl-paste -n -t text 2>/dev/null | tr '\n\t' '  ' | cut -c1-90)
printf 'text:%s\n' "$text"
