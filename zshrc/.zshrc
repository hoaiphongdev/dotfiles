# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

export LESS='-R'
export GIT_PAGER='less -+F -R'

# Environment Variables
export TERM=xterm-256color
export CLICOLOR=1
export ZSH="$HOME/.oh-my-zsh"
# export PNPM_HOME="$HOME/Library/pnpm"

# MacOS-specific configurations
if [[ "$(uname -s)" = "Darwin" ]]; then
  # Homebrew
  [[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Android SDK
  if [[ -d "$HOME/Library/Android/sdk" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export ANDROID_AVD_HOME="$ANDROID_SDK_ROOT/tools/emulator"
    export PATH="$ANDROID_HOME/emulator:$PATH"
  fi
fi

# ZSH Core Configuration
# typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Startup warnings are buffered, not printed inline: the `clear` further down would
# wipe them before they are ever seen. Flushed after that clear instead.
typeset -ga ZSHRC_WARNINGS=()

plugins=(git docker)
ZSH_THEME=""
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  ZSHRC_WARNINGS+=("oh-my-zsh not found at $ZSH — aliases from the git/docker plugins (gco, gpr, gst, ...) are unavailable. Fix: run \`just sync\` in the dotfiles repo.")
fi

# Shell Completions
autoload -Uz compinit && compinit -i

# Tool Configurations
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# SSH Agent
if [[ -d "$HOME/.ssh" ]]; then
  eval "$(ssh-agent)" > /dev/null 2>&1
  # Add all private keys in ~/.ssh (excluding known_hosts, config, etc.)
  for key in "$HOME"/.ssh/*; do
    # Check if file is a private key (not a directory, not .pub, not known_hosts or config)
    if [[ -f "$key" && ! "$key" =~ "\.pub$|known_hosts|config" ]]; then
      ssh-add "$key" > /dev/null 2>&1
    fi
  done
fi

# Aliases
alias killport='function _killport(){ lsof -ti :$1 | xargs kill -9; }; _killport'
alias gitlog="git log --pretty=format:'%C(yellow)%h%C(reset) - %C(green)%an%C(reset), %C(blue)%ar%C(reset) : %s'"
alias gitgraph="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias cls="clear"
alias copydir='pwd | pbcopy'
alias ls='lsd'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias llt='ls --tree'
alias reset-cursor='tput cnorm'
alias reload-zsh='exec zsh -l'

# Zellij
alias zj='zellij'

# Git Local Ignore Helpers
gitlocal() {
    if [ -z "$1" ]; then
        echo "📁 Local excludes (.git/info/exclude):"
        if [ -f .git/info/exclude ]; then
            cat .git/info/exclude | grep -v '^#' | grep -v '^$' | sed 's/^/  /'
        else
            echo "  (empty or not a git repo)"
        fi
    else
        if [ ! -d .git ]; then
            echo "❌ Not a git repository"
            return 1
        fi
        echo "$1" >> .git/info/exclude
        echo "✅ Added '$1' to local excludes"
    fi
}

gitlocal-edit() {
    if [ ! -d .git ]; then
        echo "❌ Not a git repository"
        return 1
    fi
    ${EDITOR:-vim} .git/info/exclude
}

gitlocal-init() {
    if [ ! -d .git ]; then
        echo "❌ Not a git repository"
        return 1
    fi
    
    if [ -f ".gitignore.local.template" ]; then
        cat .gitignore.local.template >> .git/info/exclude
        echo "✅ Initialized from .gitignore.local.template"
    else
        echo "❌ No .gitignore.local.template found"
    fi
}

gitlocal-clear() {
    if [ ! -d .git ]; then
        echo "❌ Not a git repository"
        return 1
    fi
    
    echo "# Local exclude patterns" > .git/info/exclude
    echo "✅ Cleared local excludes"
}

# clear

zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
export PATH="$HOME/.local/bin:$PATH"

# Must run after every PATH prepend above: ~/.local/bin ships a Hermes-bundled
# node that otherwise shadows the mise-pinned toolchain. Inherited mise paths are
# stripped first because `mise activate` skips prepending a path it already sees,
# which would leave it behind ~/.local/bin in a nested shell.
path=(${path:#*/mise/installs/*})
eval "$(mise activate zsh)"



clear
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# Flush buffered startup warnings (see ZSHRC_WARNINGS near the top).
if (( ${#ZSHRC_WARNINGS} )); then
  print -u2
  for _w in $ZSHRC_WARNINGS; do print -u2 "⚠️  $_w"; done
  print -u2
  unset _w
fi


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
