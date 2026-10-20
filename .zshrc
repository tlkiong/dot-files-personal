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

# kubectl completion needs compinit, so it comes after oh-my-zsh
(( $+commands[kubectl] )) && source <(kubectl completion zsh)

# New branch in a sibling worktree
gwtb() {
  if [[ -z $1 ]]; then echo "usage: gwtb <branch-name>"; return 1; fi
  git worktree add "../$1" -b "$1"
}

mkdircd() { mkdir -p -- "$1" && cd -- "$1"; }

# Switch AWS profile, logging in through SSO only when the session has expired
awsUse() {
  if ! (( $+commands[aws] )); then echo "aws CLI not found: brew install awscli"; return 1; fi
  if [[ -z $1 ]]; then echo "usage: awsUse <profile>"; return 1; fi
  export AWS_PROFILE="$1"
  aws sts get-caller-identity >/dev/null 2>&1 || aws sso login --profile "$1"
  aws sts get-caller-identity --output table
}
alias aws-use=awsUse

# Machine-specific overrides and secrets live in an untracked file
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

# Startup prompt: jump to work-local or stay. Runs last so Ctrl-C cannot skip the
# config above. Only in a real terminal that opened in $HOME; skipped in Claude
# Code, CI, VS Code's environment probe and nested shells.
if [[ -o interactive && -t 0 && -z $_WORK_PROMPT_SHOWN && $PWD == "$HOME" && -d ~/Desktop/work-local ]] \
  && [[ -z $CLAUDECODE && -z $CI && -z $VSCODE_RESOLVING_ENVIRONMENT ]]; then
  export _WORK_PROMPT_SHOWN=1
  print -P "%F{green}▸%f  [%Bw%b] work-local   [%BEnter%b] stay in %F{cyan}%~%f"
  if read -k 1 -t 10 "?  "; then
    print
    [[ $REPLY == [wW] ]] && cd ~/Desktop/work-local
  else
    print "\n  no answer, staying here"
  fi
  unset REPLY
fi
