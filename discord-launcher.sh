#!/usr/bin/env bash

# Directory where Discord is installed
DISCORD_DIR="/usr/share/discord"

# URL to fetch the latest .deb package
DISCORD_DOWNLOAD_URL="https://discord.com/api/download/stable?platform=linux&format=deb"

# Temporary directory for downloading the latest package
TEMP_DIR="/tmp/discord_update"

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

function show_error_message() {
    if command -v zenity &> /dev/null; then
        zenity --info --title="Error updating Discord" --text="$1"
    else
        echo "$1" >&2
    fi
}

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"
if [[ $? -ne 0 ]]; then
    show_error_message "Failed to make temp directory"
    exit 1
fi

# Get current installed version
if [[ -f "$DISCORD_DIR/resources/build_info.json" ]]; then
    INSTALLED_VERSION=$(jq -r '.version' "$DISCORD_DIR/resources/build_info.json")
else
    INSTALLED_VERSION="none"
fi

# Download latest package
curl -s "$DISCORD_DOWNLOAD_URL" -L -o "$TEMP_DIR/discord.deb"
if [[ $? -ne 0 ]]; then
    show_error_message "Failed to download latest Discord package"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Get latest available version
LATEST_VERSION=$(dpkg-deb -f "$TEMP_DIR/discord.deb" Version)
if [[ $? -ne 0 ]]; then
    show_error_message "Failed to get version info."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Compare versions and update if needed
if [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
    echo "Updating Discord from version $INSTALLED_VERSION to $LATEST_VERSION"

    # Update Discord
    pkexec bash -c "dpkg -i \"$TEMP_DIR/discord.deb\" && mv \"$DISCORD_DIR/Discord\" \"$DISCORD_DIR/Discord.orig\" && ln -frs \"$DISCORD_DIR/discord-launcher.sh\" \"$DISCORD_DIR/Discord\" || exit 1"
    if [[ $? -ne 0 ]]; then
        show_error_message "Failed to update Discord."
        rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    echo "Discord is already up-to-date (version $INSTALLED_VERSION)"
fi

rm -rf "$TEMP_DIR"  

# Launch Discord
/usr/share/discord/Discord.orig "$@"
