export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="daveverwer"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# Aliases
  alias be='bundle exec'
  alias gps='git push'
  alias gpl='git pull'
  alias gpso='gps origin'
  alias gplo='gpl origin'
  alias gs='git status'
  alias glog='git log'
  alias glg='git lg'
  alias gcm='git commit -m'
  alias ga='git add'
  alias gclearmain='git branch | grep -v "main" | xargs git branch -D'

  alias zshrc='code ~/.zshrc'
  alias sourcezsh='source ~/.zshrc'

  alias work='cd ~/Desktop/work-local'

  alias ws='windsurf'
  alias kiro='open -a "kiro"'

  alias br='bun run'
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

# Initialize the autocompletion
autoload -Uz compinit && compinit -i

export PATH=/opt/homebrew/bin:$PATH

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Added by Windsurf
export PATH="/Users/kiong/.codeium/windsurf/bin:$PATH"


export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
# append completions to fpath
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

export PATH="$HOME/.npm-global/bin:$PATH"
