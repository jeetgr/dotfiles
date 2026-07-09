# =========================================================
# Required directories
# =========================================================
# Must exist before HISTFILE/compinit try to write into them.
mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"

# =========================================================
# History
# =========================================================
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

# Initialize zoxide
eval "$(zoxide init zsh)"

# =========================================================
# Completion
# =========================================================

# Load completion system
autoload -Uz compinit

# Only run the full (slower) security check once every 24h; use the
# fast path otherwise. Cache dir is guaranteed to exist (see above).
if [[ -n "$XDG_CACHE_HOME/zsh/zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
else
  compinit -C -d "$XDG_CACHE_HOME/zsh/zcompdump"
fi

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# =========================================================
# Fuzzy finder
# =========================================================

source <(fzf --zsh)

export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'  # strip-cwd-prefix removes the leading ./ from results

# Ctrl-T uses fd
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt=" "
  --pointer=" "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# Ctrl+F: file picker excluding hidden files
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # LBUFFER is the text left of the cursor
  zle reset-prompt
}
zle -N _fzf_file_no_hidden

# Aliases

alias ls='eza --icons'
alias ll='eza -lh --icons --git'
alias la='eza -lah --icons --git'
alias tree='eza --tree --icons'

compdef eza=ls

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

alias -- -='cd -'

alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'

alias c='clear'
alias cx='clear -x'
alias zed='zeditor'

# Custom keybindings

# Cursor shape per vi mode
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

# Disable command mode line highlight
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# zsh-vi-mode resets all bindings on init, so custom bindings
# must be registered via this hook to survive.
zvm_after_init() {
  # Ctrl+Right -> move forward one word (^[[1;5C is the terminal escape code)
  bindkey '^[[1;5C' forward-word

  # Ctrl+Left -> move backward one word (^[[1;5D is the terminal escape code)
  bindkey '^[[1;5D' backward-word

  # Ctrl+F -> fzf file picker (no hidden files)
  bindkey '^F' _fzf_file_no_hidden

  # Ctrl+\ -> toggle autosuggestions (useful for screen recordings)
  bindkey '^\' autosuggest-toggle

  # Up/Down -> history search by substring (^[[A/^[[B are up/down arrow escape codes)
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}

# Plugins and plugin manager
ZPLUGINDIR="${XDG_DATA_HOME}/zsh/plugins"

_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${2}..."
    git clone --depth=1 "https://github.com/${1}/${2}" "$plugin_path" \
      || { echo "ERROR: failed to install ${2}" >&2; return 1; }
  fi
  if [[ ! -f "${plugin_path}/${2}.plugin.zsh" ]]; then
    echo "ERROR: missing plugin file for ${2}" >&2
    return 1
  fi
  source "${plugin_path}/${2}.plugin.zsh"
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
  echo "Done. Restart the shell to rebuild syntax-highlighting cache."
}

_zplugin_load zsh-users zsh-autosuggestions
_zplugin_load zsh-users zsh-history-substring-search
_zplugin_load jeffreytse zsh-vi-mode
_zplugin_load zdharma-continuum fast-syntax-highlighting

# Prompt/theme
# Prevent Python virtualenv from polluting the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

eval "$(starship init zsh)"

# =========================================================
# Mise
# =========================================================

eval "$(/usr/bin/mise activate zsh)"
