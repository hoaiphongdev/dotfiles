# Environment Variables
export TERM=xterm-256color
export CLICOLOR=1
export ZSH="$HOME/.oh-my-zsh"
export PNPM_HOME="$HOME/Library/pnpm"

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

# Path Updates
# export PATH="$ASDF_DATA_DIR/shims:$PNPM_HOME:/opt/homebrew/bin:$PATH"

# ZSH Core Configuration
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
plugins=(git docker)
ZSH_THEME=""
source "$ZSH/oh-my-zsh.sh"

# Shell Completions
autoload -Uz compinit && compinit -i

# Tool Configurations
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"

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
alias gitlog="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias gitgraph="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias cls="clear"
alias copydir='pwd | pbcopy'
alias ls='lsd'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias llt='ls --tree'
alias zj='zellij'

# Clear terminal on startup
clear