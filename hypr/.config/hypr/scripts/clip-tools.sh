#!/usr/bin/env bash
set -euo pipefail

cmd=${1:-}
shift || true

is_image_preview() {
	printf '%s' "$1" | grep -qiE '\[\[ binary data .*(png|jpe?g|webp|gif|bmp)'
}

case "$cmd" in
thumbs)
	dir=${1:-}
	mkdir -p "$dir"
	n=0
	while IFS= read -r line; do
		preview=${line#*$'\t'}
		if ! is_image_preview "$preview"; then
			continue
		fi
		n=$((n + 1))
		id=${line%%$'\t'*}
		out="$dir/$id"
		if [[ ! -f $out ]]; then
			printf '%s\n' "$line" | cliphist decode >"$out" || true
		fi
		if [[ $n -ge 24 ]]; then
			break
		fi
	done < <(cliphist list)
	;;
save)
	line=${1:-}
	file=${2:-}
	mkdir -p "$(dirname "$file")"
	printf '%s\n' "$line" | cliphist decode >"$file"
	;;
delete)
	printf '%s\n' "${1:-}" | cliphist delete
	;;
*)
	echo "usage: clip-tools.sh thumbs DIR | save LINE FILE | delete LINE" >&2
	exit 2
	;;
esac
