#!/usr/bin/env bash

set -e

# Directory where Discord is installed
DISCORD_DIR="/usr/share/discord"

if [[ ! -f "$DISCORD_DIR/Discord" || -h "$DISCORD_DIR/Discord" ]] && [[ ! -f "$DISCORD_DIR/Discord.orig" ]]; then
    echo "Discord installation not found in $DISCORD_DIR. Please ensure Discord is installed." >&2
    exit 1
fi

# Detect package manager
if command -v apt-get &>/dev/null; then
    PACKAGE_MANAGER="apt-get"
    INSTALL_CMD="sudo apt-get install -y"
elif command -v pacman &>/dev/null; then
    PACKAGE_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
else
    echo "Unsupported package manager. Please use a system with APT or Pacman." >&2
    exit 1
fi

echo "Installing required tools..."

# Ensure necessary tools are installed
$INSTALL_CMD jq curl
if [[ $? -ne 0 ]]; then
    echo "Failed to install required tools." >&2
    exit 1
fi

# Wrapper script URL
WRAPPER_SCRIPT_URL="https://raw.githubusercontent.com/rune-scape/Discord-Auto-Updater-For-Linux/master/discord-launcher.sh"

# Download the wrapper script
sudo curl -L "$WRAPPER_SCRIPT_URL" -o "$DISCORD_DIR/discord-launcher.sh"
if [[ $? -ne 0 || ! -f "$DISCORD_DIR/discord-launcher.sh" ]]; then
    echo "Discord launcher script failed to download." >&2
    exit 1
fi

sudo chmod +x "$DISCORD_DIR/discord-launcher.sh"
if [[ $? -ne 0 ]]; then
    echo "Failed to make discord launcher script executable." >&2
    exit 1
fi

if [[ -f "$DISCORD_DIR/Discord" && ! -h "$DISCORD_DIR/Discord" ]]; then
    # Backup the original Discord launcher
    sudo mv -f "$DISCORD_DIR/Discord" "$DISCORD_DIR/Discord.orig"
    if [[ $? -ne 0 ]]; then
        echo "Failed to move Discord executable." >&2
        exit 1
    fi
fi

sudo ln -frs "$DISCORD_DIR/discord-launcher.sh" "$DISCORD_DIR/Discord"
if [[ $? -ne 0 ]]; then
    echo "Failed to replace Discord executable." >&2

    if [[ -f "$DISCORD_DIR/Discord.orig" ]]; then
        sudo mv -f "$DISCORD_DIR/Discord.orig" "$DISCORD_DIR/Discord"
    fi

    exit 1
fi

echo "Setup complete. Discord will now be updated automatically when launched.";
