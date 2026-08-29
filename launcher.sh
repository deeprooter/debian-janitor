#!/bin/bash
#===============================================================
# Script Name:   launcher.sh
# Description:   Automates package repair, cleanup, and tuning for Debian.
# Author:        Kamal K. Chhoker <halides@live.com>
# Ownership:     Kamal K. Chhoker
# License:       MIT License
# Version:       1.0.12
# Date Created:  2026-07-19
# Last Modified: 2026-08-29
#===============================================================

# Locate the directory where this script sits
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REAL_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE}")

# Use the real session Xauthority, not GDM's
if [ -f "$HOME/.Xauthority" ]; then
    export XAUTHORITY="$HOME/.Xauthority"
fi

# =====================================================================
# 1. GRAPHICAL ELEVATION
# =====================================================================
if [ "$EUID" -ne 0 ]; then
    if [ -n "$_ALREADY_ELEVATED" ]; then
        echo "Error: Elevation failed. Try: sudo $0" >&2
        exit 1
    fi

    if command -v pkexec &> /dev/null; then
        echo "Elevating privileges graphically via pkexec..."
        export _ALREADY_ELEVATED=1
        exec env _ALREADY_ELEVATED=1 pkexec env \
            DISPLAY="$DISPLAY" \
            XAUTHORITY="$XAUTHORITY" \
            WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
            _ALREADY_ELEVATED=1 \
            /bin/bash "$REAL_SCRIPT_PATH" "$@"

    elif command -v sudo &> /dev/null; then
        read -rsp "Password: " PASSWORD
        echo
        if [ -z "$PASSWORD" ]; then
            echo "Error: Authentication canceled by user." >&2
            exit 1
        fi
        echo "$PASSWORD" | sudo -S env \
            DISPLAY="$DISPLAY" \
            XAUTHORITY="$XAUTHORITY" \
            WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
            /bin/bash "$REAL_SCRIPT_PATH" "$@"
    else
        echo "Error: Neither pkexec nor sudo available." >&2
        exit 1
    fi
fi

# =====================================================================
# EVERYTHING BELOW RUNS AS ROOT
# =====================================================================

# Recover the original user
if [ -z "$SUDO_USER" ] || [ "$SUDO_USER" = "root" ]; then
    SUDO_USER=$(logname 2>/dev/null || echo "$USER")
fi

# Authorize root to connect to the user's X display
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ] && command -v xhost &> /dev/null; then
    sudo -u "$SUDO_USER" xhost +si:localuser:root &>/dev/null
fi

# =====================================================================
# 2. LAUNCH GUI
# =====================================================================
if command -v zenity &> /dev/null && [ -f "$SCRIPT_DIR/zenity.sh" ]; then
    echo "--> Zenity detected. Launching GUI layout..."
    exec env \
        DISPLAY="$DISPLAY" \
        XAUTHORITY="$XAUTHORITY" \
        WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
        SUDO_USER="$SUDO_USER" \
        USER="$SUDO_USER" \
        bash "$SCRIPT_DIR/zenity.sh"
else
    echo "--> Zenity missing or script unavailable. Falling back to Whiptail..."
    if [ -f "$SCRIPT_DIR/whiptail.sh" ]; then
        exec env SUDO_USER="$SUDO_USER" bash "$SCRIPT_DIR/whiptail.sh"
    else
        echo "Error: Neither zenity.sh nor whiptail.sh found in $SCRIPT_DIR."
        exit 1
    fi
fi
