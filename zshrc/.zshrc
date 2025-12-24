
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

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
eval $(thefuck --alias)

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
alias zj-lumin-dev='zellij -l lumin-dev'

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

alias git-sage='docker run --rm -it \
  -v $(pwd):/workspace/project \
  -v ~/.gitconfig:/root/.gitconfig:ro \
  -v ~/.ssh:/root/.ssh:ro \
  --network host \
  -w /workspace/project \
  git-sage:latest /workspace/git-sage'
# Clear terminal on startup
clear

. "/Users/mac/.deno/env"
# Added by Windsurf
export PATH="/Users/mac/.codeium/windsurf/bin:$PATH"

export DOCKER_HOST='unix:///var/folders/pv/bm2crw6j3tn7wrv_37n8f7cm0000gn/T/podman/podman-machine-default-api.sock'

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)