# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
fi

# ---------- GPG ----------
# Guard tty call: .zshenv loads for every invocation, including
# non-interactive/cron shells where `tty` has nothing to attach to.
[[ -t 0 ]] && export GPG_TTY=$(tty)

# ---------- PATH ----------
# Personal binaries/scripts. Use the `path` array + typeset -U so
# repeated sourcing (nested shells, subshells) doesn't duplicate entries.
typeset -U path
path=("$HOME/.local/bin" $path)
export PATH
