# ============================================================
# Powerlevel10k instant prompt
# Must stay near the top of ~/.zshrc
# ============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# XDG base directories (keep $HOME clean)
# ============================================================
export XDG_CACHE_HOME="$HOME/.dev/cache"
export XDG_CONFIG_HOME="$HOME/.dev/config"
export XDG_DATA_HOME="$HOME/.dev/share"

# ============================================================
# LS_COLORS
# ============================================================
LS_COLORS_FILE="$HOME/.ls_colors"
VIVID_THEME="one-dark"

if [[ -r "$LS_COLORS_FILE" ]]; then
  export LS_COLORS="$(< "$LS_COLORS_FILE")"
elif command -v vivid >/dev/null 2>&1; then
  export LS_COLORS="$(vivid generate "$VIVID_THEME")"
  print -r -- "$LS_COLORS" >| "$LS_COLORS_FILE"
fi

# ============================================================
# Oh My Zsh
# ============================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

ENABLE_CORRECTION="true"

plugins=(
  ubuntu
  colored-man-pages
  colorize
  command-not-found
  extract
  docker
  docker-compose
  git
  vim-interaction
  systemd
  ufw
  history-substring-search
  autojump
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ============================================================
# Autosuggestions configuration
# ============================================================
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=208'

# ============================================================
# PATH helper 
# ============================================================
path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  case ":$PATH:" in
    *":$dir:"*) ;;
    *) export PATH="$dir:$PATH" ;;
  esac
}

# ============================================================
# Dev hub root
# ============================================================
export DEV_HOME="$HOME/.dev"

# ============================================================
# Node.js 
# ============================================================
export NVM_DIR="$DEV_HOME/node/nvm"
path_prepend "$DEV_HOME/node/npm-global/bin"

[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"

# ============================================================
# Python
# ============================================================
export PYENV_ROOT="$DEV_HOME/python/pyenv"
path_prepend "$PYENV_ROOT/bin"

command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - zsh)"

export PIPX_HOME="$DEV_HOME/python/pipx"
export PIPX_BIN_DIR="$DEV_HOME/python/pipx/bin"
path_prepend "$PIPX_BIN_DIR"

# ============================================================
# direnv
# ============================================================
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# ============================================================
# Faster completion with cache
# ============================================================
autoload -Uz compinit
_compdump="${XDG_CACHE_HOME}/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${_compdump:h}" 2>/dev/null

if [[ ! -f "$_compdump" || "$(find "$_compdump" -mtime +1 2>/dev/null)" != "" ]]; then
  compinit -d "$_compdump"
else
  compinit -C -d "$_compdump"
fi
unset _compdump

# Completion UX improvements
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"
mkdir -p "${XDG_CACHE_HOME}/zsh" 2>/dev/null

# ============================================================
# History configuration
# ============================================================
export HISTFILE="${XDG_DATA_HOME}/zsh/history"
mkdir -p "${HISTFILE:h}" 2>/dev/null
export HISTSIZE=200000
export SAVEHIST=200000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY

# ============================================================
# Keep common tool caches out of $HOME
# ============================================================
export LESSHISTFILE="-"

export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"

export GOPATH="${XDG_DATA_HOME}/go"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export PIP_CACHE_DIR="${XDG_CACHE_HOME}/pip"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/python"

# ============================================================
# Editor and pager defaults
# ============================================================
export EDITOR="vim"
export VISUAL="vim"
export PAGER="less"
export LESS="-FRX"

# ============================================================
# Zsh behavior tweaks
# ============================================================
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# ============================================================
# Alias
# ============================================================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'
alias cd..='cd ..'

alias ff='clear && fastfetch'

# ============================================================
# cmd-HELPER integration (alias)
# ============================================================

if command -v helper >/dev/null 2>&1; then
  alias ch='helper'
  alias cha='helper --all'
  alias chh='helper --help'
fi

# ============================================================
# LSDU integration (alias)
# ============================================================

if command -v lsdu >/dev/null 2>&1; then
  alias ls='lsdu'
  alias l='lsdu'
  alias ll='lsdu'
  alias la='lsdu -a'
  alias lla='lsdu -a'
  alias lst='lsdu --tree'
  alias lt='lsdu --sort time --reverse'
  alias ltr='lsdu --sort time'
  alias lsS='lsdu --sort size --reverse'
  alias lss='lsdu --sort size'
  alias le='lsdu --sort ext'
  alias lr='lsdu --reverse'
  alias lsd='lsdu --only-dirs'
  alias lsf='lsdu --only-files'
  alias lsda='lsdu -a --only-dirs'
  alias lsfa='lsdu -a --only-files'
  alias tree='lsdu --tree --level 3'
  alias treea='lsdu -a --tree --level 3'
  alias lg='lsdu --grid --columns 4'
  alias lga='lsdu -a --grid --columns 4'
  alias li='lsdu --interactive'
  alias lia='lsdu -a --interactive'
  alias lsr='lsdu --filter "*.rs"'
  alias lspy='lsdu --filter "*.py"'
  alias lsdot='lsdu --filter ".*"'
  alias lsbig='lsdu --min-size 100M'
  alias lssmall='lsdu --max-size 100K'
  alias lsg='lsdu --git'
  alias lsgS='lsdu --git --sort size --reverse'
  alias lsgt='lsdu --git --sort time --reverse'
  alias du='lsdu --bytes'
  alias du1='lsdu --bytes --max-depth 1'
  alias duh='lsdu --max-depth 1'
  alias dud='lsdu --only-dirs --max-depth 1'
fi

# ============================================================
# SSH shortcuts
# ============================================================
ssh41() { ssh pi@192.168.1.252 }
ssh42() { ssh pi@192.168.1.250 }
ssh8()  { ssh pi@192.168.1.251 }
sshv1(){ ssh -4 debian@vps1.xernex.fr }
sshv2(){ ssh -4 root@vps2.xernex.fr }

# ============================================================
# Apt maintenance helper
# ============================================================
aa() {
  sudo apt update \
    && sudo apt full-upgrade -y \
    && sudo apt autoremove --purge -y
}

# ============================================================
# Debug helper: measure shell startup time (run manually)
# ============================================================
zsh_bench() {
  for i in {1..5}; do
    /usr/bin/time -p zsh -i -c exit
  done
}

# ============================================================
# Powerlevel10k configuration
# ============================================================
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
