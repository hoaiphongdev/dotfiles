#!/usr/bin/env bash

set -u

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

log() {
  local level="$1"
  shift
  printf "[%s] %s\n" "$level" "$*"
}

is_installed() {
  command -v "$1" >/dev/null 2>&1
}

create_symlink() {
  local app="$1"
  local source_path="$2"
  local target_path="$3"
  local target_parent
  target_parent="$(dirname "$target_path")"

  if [ ! -e "$source_path" ]; then
    log "WARN" "$app: source missing -> $source_path"
    return 0
  fi

  mkdir -p "$target_parent"

  if [ -L "$target_path" ]; then
    local linked_to=""
    linked_to="$(readlink "$target_path")"
    if [ "$linked_to" = "$source_path" ]; then
      log "SKIP" "$app: already linked -> $target_path"
      return 0
    fi
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    local backup_path="${target_path}.backup.${TIMESTAMP}"
    mv "$target_path" "$backup_path"
    log "INFO" "$app: backed up existing target -> $backup_path"
  fi

  ln -s "$source_path" "$target_path"
  log "OK" "$app: linked $target_path -> $source_path"
}

resolve_aerospace_target() {
  local legacy_target="$HOME/.aerospace.toml"
  local xdg_target="$HOME/.config/aerospace/aerospace.toml"

  if [ -e "$legacy_target" ] && [ -e "$xdg_target" ]; then
    log "WARN" "aerospace: both config locations exist; skipping to avoid ambiguity"
    log "WARN" "aerospace: keep one of these paths only: $legacy_target or $xdg_target"
    echo ""
    return 0
  fi

  if [ -e "$xdg_target" ] || [ -L "$HOME/.config/aerospace" ]; then
    echo "$xdg_target"
    return 0
  fi

  echo "$legacy_target"
}

declare -a APPS=(
  "aerospace"
  "cursor"
  "espanso"
  "git"
  "kitty"
  "neofetch"
  "zellij"
  "mise"
  "zshrc"
)

for app in "${APPS[@]}"; do
  case "$app" in
    aerospace)
      if ! is_installed "aerospace"; then
        log "WARN" "aerospace: not installed, please install first"
        continue
      fi
      source_path="$DOTFILES_DIR/.config/aerospace/aerospace.toml"
      target_path="$(resolve_aerospace_target)"
      if [ -z "$target_path" ]; then
        continue
      fi
      create_symlink "$app" "$source_path" "$target_path"
      ;;
    cursor)
      source_path="$DOTFILES_DIR/cursor/settings.json"
      target_path="$HOME/Library/Application Support/Cursor/User/settings.json"
      create_symlink "$app" "$source_path" "$target_path"
      ;;
    espanso)
      if ! is_installed "espanso"; then
        log "WARN" "espanso: not installed, please install first"
        continue
      fi
      source_path="$DOTFILES_DIR/.config/espanso"
      target_path="$HOME/Library/Application Support/espanso"
      create_symlink "$app" "$source_path" "$target_path"
      ;;
    git)
      # Symlink the whole directory so includeIf "path = profile-*.inc" resolves next to
      # ~/.config/git/config (XDG). A lone ~/.gitconfig -> file symlink breaks relative includes.
      source_path="$DOTFILES_DIR/.config/git"
      target_path="$HOME/.config/git"
      create_symlink "$app" "$source_path" "$target_path"
      legacy_gitconfig="$HOME/.gitconfig"
      if [ -L "$legacy_gitconfig" ]; then
        legacy_target=""
        legacy_target="$(readlink "$legacy_gitconfig")"
        if [ "$legacy_target" = "$DOTFILES_DIR/.config/git/config" ]; then
          rm -f "$legacy_gitconfig"
          log "INFO" "git: removed legacy ~/.gitconfig symlink (global config is ~/.config/git/config)"
        fi
      fi
      ;;
    kitty)
      if ! is_installed "kitty"; then
        log "WARN" "kitty: not installed, please install first"
        continue
      fi
      source_path="$DOTFILES_DIR/.config/kitty"
      target_path="$HOME/.config/kitty"
      create_symlink "$app" "$source_path" "$target_path"
      ;;
    neofetch)
      if ! is_installed "neofetch"; then
        log "WARN" "neofetch: not installed, please install first"
        continue
      fi
      source_path="$DOTFILES_DIR/.config/neofetch"
      target_path="$HOME/.config/neofetch"
      create_symlink "$app" "$source_path" "$target_path"
      ;;
    zellij)
      if ! is_installed "zellij"; then
        log "WARN" "zellij: not installed, please install first"
        continue
      fi
      source_path="$DOTFILES_DIR/.config/zellij"
      target_path="$HOME/.config/zellij"
      create_symlink "$app" "$source_path" "$target_path"
      ;;
    mise)
      if ! is_installed "mise"; then
        log "WARN" "mise: not installed, please install first"
        continue
      fi
      source_path="$DOTFILES_DIR/.config/mise"
      target_path="$HOME/.config/mise"
      create_symlink "$app" "$source_path" "$target_path"
      ;;
    zshrc)
      if ! is_installed "zsh"; then
        log "WARN" "zsh: not installed, please install first"
        continue
      fi
      source_path="$DOTFILES_DIR/zshrc/.zshrc"
      target_path="$HOME/.zshrc"
      create_symlink "$app" "$source_path" "$target_path"
      ;;
    *)
      log "WARN" "unknown app key: $app"
      ;;
  esac
done
