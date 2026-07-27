#!/bin/bash

DOTFILES_DIR="/Users/mac/dotfiles"
CONFIG_DIR="/Users/mac/.config"

CONFIGS_TO_MOVE=(
    "aerospace"
    "btop" 
    "ghostty"
    "mise"
    "raycast"
    "zellij"
    "karabiner"
    "mise"
)

echo "🚀 Moving configs into dotfiles..."
mkdir -p "$DOTFILES_DIR/.config"

for config in "${CONFIGS_TO_MOVE[@]}"; do
    echo ""
    echo "📁 Processing: $config"
    
    SOURCE_PATH="$CONFIG_DIR/$config"
    DEST_PATH="$DOTFILES_DIR/.config/$config"
    
    if [ -e "$SOURCE_PATH" ]; then
        echo "  ✅ Found: $SOURCE_PATH"
        
        # Backup if dest already exists (not symlink)
        if [ -e "$DEST_PATH" ] && [ ! -L "$DEST_PATH" ]; then
            echo "  ⚠️  Destination exists, backing up..."
            mv "$DEST_PATH" "$DEST_PATH.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        # Remove old symlink if exists at source
        if [ -L "$SOURCE_PATH" ]; then
            echo "  🔗 Removing old symlink at $SOURCE_PATH"
            rm "$SOURCE_PATH"
        fi
        
        # Move only if source is not already symlink
        if [ ! -L "$SOURCE_PATH" ]; then
            echo "  📦 Moving $SOURCE_PATH -> $DEST_PATH"
            mv "$SOURCE_PATH" "$DEST_PATH"
        fi
        
        # Create symlink
        echo "  🔗 Creating symlink: $DEST_PATH -> $SOURCE_PATH"
        ln -sf "$DEST_PATH" "$SOURCE_PATH"
        
        echo "  ✅ Done: $config"
    else
        echo "  ❌ Not found: $SOURCE_PATH"
    fi
done

echo ""
echo "🎉 All done! Verifying symlinks..."
for config in "${CONFIGS_TO_MOVE[@]}"; do
    LINK_PATH="$CONFIG_DIR/$config"
    if [ -L "$LINK_PATH" ]; then
        TARGET=$(readlink "$LINK_PATH")
        echo "✅ $config -> $TARGET"
    else
        echo "❌ $config: not a symlink or missing"
    fi
done
