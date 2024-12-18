# Amazon Q pre block - Keep at top as required
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

#region Environment Variables
export TERM=xterm-256color
export CLICOLOR=1

export ZSH="$HOME/.oh-my-zsh"

#endregion Environment Variables
# MacOS-specific services
if [ "$(uname -s)" = "Darwin" ]; then
  # Add Brew to path, if it's installed
  if [[ -d /opt/homebrew/bin ]]; then
    export PATH=/opt/homebrew/bin:$PATH
  fi


  # Append the Android SDK locations to path
  if [[ -d "${HOME}/Library/Android/" ]]; then
    export PATH="${HOME}/Library/Android/sdk/emulator:${PATH}"
    export ANDROID_HOME="${HOME}/Library/Android/sdk"
    export ANDROID_SDK_ROOT="${HOME}/Library/Android/sdk"
    export ANDROID_AVD_HOME="${ANDROID_SDK_ROOT}/tools/emulator"
  fi
fi

eval $(/opt/homebrew/bin/brew shellenv)


# Add other PATH additions after Homebrew
#endregion Path Configuration

#region ZSH Core Configuration
# Oh My Zsh configuration
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Essential plugins
plugins=(
  git     # Git integration
  docker  # Docker commands
  asdf    # Version manager
)

source $ZSH/oh-my-zsh.sh
#endregion ZSH Core Configuration

#region Version Managers
# ASDF version manager (load before other tool configurations)
. "$HOME/.asdf/asdf.sh"
fpath=(${ASDF_DIR}/completions $fpath)
#endregion Version Managers

#region Tool Configurations
# FZF configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)

# zoxide (directory jumper)
eval "$(zoxide init zsh)"

# SSH Agent configuration (load after environment setup)
eval "$(ssh-agent)" > /dev/null 2>&1
for key in ~/.ssh/hoaiphong{dsv,dev,main}; do
  [ -f "$key" ] && ssh-add "$key" > /dev/null 2>&1
done
#endregion Tool Configurations

#region Shell Completions
# Initialize completions (after all tools are loaded)
autoload -Uz compinit && compinit
#endregion Shell Completions

#region Aliases
# Git aliases
alias gitlog="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias gitgraph="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"

# System aliases
alias cls="clear"
alias copydir='pwd | pbcopy'
alias clean-up='~/.config/scripts/clean.sh'

# LSD (modern ls) aliases
alias ls='lsd'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias llt='ls --tree'
#endregion Aliases

#region Prompt
# Starship prompt (load last to ensure all variables are available)
eval "$(starship init zsh)"
#endregion Prompt

clear

# Amazon Q post block - Keep at bottom as required
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
