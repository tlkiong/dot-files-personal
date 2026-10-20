# ~/.zshrc is a symlink to dot-files-personal/.zshrc. That repo is public, so
# secrets and machine-specific settings go in ~/.zshrc.local, which is not tracked.

typeset -U path fpath   # no duplicate entries, even after `sourcezsh`

# Homebrew: PATH, MANPATH, HOMEBREW_* and its completions on fpath
eval "$(/opt/homebrew/bin/brew shellenv)"

# asdf 0.16+ has no asdf.sh: shims on PATH and completions on fpath are enough
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
fpath=($ASDF_DATA_DIR/completions(N-/) $fpath)

# PATH, highest precedence first. (N-/) skips directories that do not exist.
path=(
  $HOME/.local/bin(N-/)                # claude
  $HOME/.bun/bin(N-/)                  # bun add -g binaries
  $HOME/.npm-global/bin(N-/)           # npm i -g binaries
  $ASDF_DATA_DIR/shims(N-/)            # node, bun and ruby from .tool-versions
  $HOMEBREW_PREFIX/opt/libpq/bin(N-/)  # psql, pg_dump
  $path
)

# Oh My Zsh runs compinit itself, so fpath must be final before it loads.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="daveverwer"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting   # must stay last
)

source $ZSH/oh-my-zsh.sh

# Aliases
  alias be='bundle exec'
  alias gchm='git checkout main'
  alias gps='git push'
  alias gpl='git pull'
  alias gpso='gps origin'
  alias gplo='gpl origin'
  alias gpsm='gpso main'
  alias gplm='gplo main'
  alias gs='git status'
  alias glog='git log'
  alias glg='git lg'
  alias gcm='git commit -m'
  alias ga='git add'
  alias gclearmain='git branch | grep -v "main" | xargs git branch -D'

  alias zshrc='code ~/.zshrc'
  alias sourcezsh='source ~/.zshrc'

  alias work='cd ~/Desktop/work-local'

  alias br='bun run'

  alias bid='bun add -D'
  alias bi='bun add'
  alias cld='claude'
  alias cldebug='claude --debug'
# End: Aliases

# Highlight the current autocomplete option
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Better SSH/Rsync/SCP Autocomplete
zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Allow for autocomplete to be case insensitive
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
  '+l:|?=** r:|?=**'

# Machine-specific overrides and secrets live in an untracked file
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
