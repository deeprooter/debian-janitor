#!/bin/bash
#===============================================================
# Script Name:   zenity.sh
# Description:   Automates package repair, cleanup, and tuning for Debian.
# Author:        Kamal K. Chhoker <halides@live.com>
# Ownership:     Kamal K. Chhoker
# License:       MIT License
# Version:       1.0.11
# Date Created:  2026-07-19
# Last Modified: 2026-08-15
#===============================================================

# ====================================================================
# Modern True-GUI Privilege Elevation Matrix
# ====================================================================
# Check if the script is already running with root permissions
if [ "$EUID" -ne 0 ]; then
    # Verify that pkexec is installed on the system
    if command -v pkexec &> /dev/null; then
        echo "Elevating privileges graphically via pkexec..."
        # Re-execute this exact script using the graphical Polkit agent
        exec pkexec "$0" "$@"
    else
        # Fallback error if running on a headless machine without PolicyKit
        echo "Error: pkexec is missing. Please run this script directly with 'sudo'." >&2
        exit 1
    fi
fi

# --------------------------------------------------------------------
# Identify Environment & Users (Must happen before elevation check)
# --------------------------------------------------------------------
# Track the non-root desktop user to correctly map graphical displays
REAL_USER="${SUDO_USER:-${PKEXEC_UID:+#$(id -un $PKEXEC_UID)}}"
REAL_USER="${REAL_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
TRASH_DIR="$USER_HOME/.local/share/Trash"

# Gather desktop session components to bridge Wayland/X11 barriers
USER_DISPLAY=$(sudo -u "$REAL_USER" printenv DISPLAY 2>/dev/null || printenv DISPLAY)
USER_WAYLAND=$(sudo -u "$REAL_USER" printenv WAYLAND_DISPLAY 2>/dev/null || printenv WAYLAND_DISPLAY)
USER_RUNTIME=$(sudo -u "$REAL_USER" printenv XDG_RUNTIME_DIR 2>/dev/null || printenv XDG_RUNTIME_DIR)
USER_DBUS=$(sudo -u "$REAL_USER" printenv DBUS_SESSION_BUS_ADDRESS 2>/dev/null || printenv DBUS_SESSION_BUS_ADDRESS)

# FALLBACK 1: If XDG_RUNTIME_DIR is empty, target the default user run directory
if [ -z "$USER_RUNTIME" ]; then
  USER_UID=$(id -u "$REAL_USER")
  if [ -d "/run/user/$USER_UID" ]; then
    USER_RUNTIME="/run/user/$USER_UID"
  fi
fi

# FALLBACK 2: If DBUS_SESSION_BUS_ADDRESS is missing, discover it from the system environment
if [ -z "$USER_DBUS" ]; then
  if [ -S "$USER_RUNTIME/bus" ]; then
    USER_DBUS="unix:path=$USER_RUNTIME/bus"
  else
    USER_DBUS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/*/environ 2>/dev/null | head -n 1 | tr '\0' '\n' | grep '^DBUS_SESSION_BUS_ADDRESS=' | cut -d= -f2-)
  fi
fi

# FALLBACK 3: If DISPLAY is missing on an X11-fallback display link
if [ -z "$USER_DISPLAY" ]; then
  USER_DISPLAY=$(grep -z DISPLAY /proc/*/environ 2>/dev/null | head -n 1 | tr '\0' '\n' | grep '^DISPLAY=' | cut -d= -f2-)
fi

# Reusable function to drop privileges and paint Zenity screens smoothly
run_as_user() {
  sudo -u "$REAL_USER" \
    DISPLAY="$USER_DISPLAY" \
    WAYLAND_DISPLAY="$USER_WAYLAND" \
    XDG_RUNTIME_DIR="$USER_RUNTIME" \
    DBUS_SESSION_BUS_ADDRESS="$USER_DBUS" \
    "$@"
}



# Authorize root to open windows on the current user's desktop screen
if command -v xhost &> /dev/null; then
  sudo -u "$REAL_USER" xhost +si:localuser:root &> /dev/null
fi

# Ensure Zenity is available before spinning up the user interface
if ! command -v zenity &> /dev/null; then
  echo "Zenity is required for the user interface. Installing it now..."
  apt-get update && apt-get install zenity -y
fi


# --------------------------------------------------------------------
# Task Selection Screen
# --------------------------------------------------------------------
CHOICES=$(run_as_user zenity --list --checklist \
  --title="Debian Destro Janitor" \
  --text="Hello! Please select the tasks you would like to run today:" \
  --column="Select" --column="ID" --column="Maintenance Task Description" \
  FALSE "1" "Clean Package Cache & Fix Broken Dependencies" \
  FALSE "2" "Scan for Failed Systemd Background Services" \
  FALSE "3" "Install System Updates & Software Patches" \
  FALSE "4" "Remove Old Snap Package Revisions (Frees Space)" \
  FALSE "5" "Vacuum Systemd Journal Logs down to 100MB" \
  FALSE "6" "Remove Leftover Unused Flatpak Runtimes" \
  FALSE "7" "Optimize Solid State Drives (Run fstrim)" \
  FALSE "8" "Empty User Recycle Bin / System Trash" \
  --width=640 --height=520)

# Capture the exit status immediately after Zenity runs
EXIT_STATUS=$?

# Exit gracefully if the user cancels or closes the window
if [ $EXIT_STATUS -ne 0 ]; then
  echo "Operation canceled by user. Have a great day!"
  exit 0
fi

# Check if the user clicked OK but selected absolutely nothing
if [ -z "$CHOICES" ]; then
  echo "No tasks were selected. Exiting."
  exit 0
fi

# Clean up the Zenity output format (removes pipes for easy looping)
CHOICES=$(echo "$CHOICES" | tr '|' ' ')

# Bookmark initial drive space to calculate savings later
BEFORE_KB=$(df / | awk 'NR==2 {print $4}')

# --------------------------------------------------------------------
# Core Maintenance Routines
# --------------------------------------------------------------------
run_tasks() {
  # Task 1: Package Management Clean up
  if [[ " $CHOICES " == *" 1 "* ]]; then
    echo "========================================================="
    echo "[TASK 1] Tidying Up Package Managers & Cache Files"
    echo "========================================================="
    echo "--> Scanning and repairing any broken dependencies..."
    apt install -f -y 2>&1
    
    echo "--> Purging orphaned packages no longer needed by the system..."
    apt autoremove --purge -y 2>&1
    
    echo "--> Sweeping away leftover setup configuration files..."
    RESIDUAL_PKGS=$(dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$RESIDUAL_PKGS" ]; then
      dpkg --purge $RESIDUAL_PKGS 2>&1
    fi
    
    echo "--> Clearing old, redundant package download archives..."
    apt autoclean -y 2>&1
    apt clean 2>&1
    echo "Task 1 completed successfully."
    echo ""
  fi

  # Task 2: Scan for Failed Services
  if [[ " $CHOICES " == *" 2 "* ]]; then
    echo "========================================================="
    echo "[TASK 2] Scanning Systemd background services for errors"
    echo "========================================================="
    if command -v systemctl &> /dev/null; then
      FAILED_COUNT=$(systemctl --failed --quiet | awk '/loaded/ {print $1}')
      if [ -n "$FAILED_COUNT" ]; then
        echo "--> WARNING: The following background services have crashed:"
        systemctl --failed --no-legend 2>&1
      else
        echo "--> Excellent! All core background system services are running fine."
      fi
    else
      echo "--> systemctl binary inaccessible."
    fi
    echo "Task 2 completed successfully."
    echo ""
  fi

  # Task 3: System Upgrades
  if [[ " $CHOICES " == *" 3 "* ]]; then
    echo "========================================================="
    echo "[TASK 3] Fetching and Installing System Updates"
    echo "========================================================="
    echo "--> Refreshing software repository manifests..."
    apt update 2>&1
    
    echo "--> Upgrading packages to their latest versions safely..."
    apt full-upgrade -y 2>&1
    echo "Task 3 completed successfully."
    echo ""
  fi

  # Task 4: Remove Old Snap Revisions
  if [[ " $CHOICES " == *" 4 "* ]]; then
    echo "========================================================="
    echo "[TASK 4] Removing Disabled Snap Package Revisions"
    echo "========================================================="
    if command -v snap &> /dev/null; then
      echo "--> Scanning for disabled applications..."
      snap list --all | awk '/disabled/{print $1, $3}' | while read snapname rev; do
        echo "----> Removing $snapname (revision $rev)..."
        snap remove "$snapname" --revision="$rev" 2>&1
      done
      echo "Snap package cleanup complete."
    else
      echo "--> snap binary inaccessible."
    fi
    echo "Task 4 completed successfully."
    echo ""
  fi

  # Task 5: Vacuum Systemd Journal Logs
  if [[ " $CHOICES " == *" 5 "* ]]; then
    echo "========================================================="
    echo "[TASK 5] Vacuuming Systemd Journal Logs down to 100MB"
    echo "========================================================="
    if command -v journalctl &> /dev/null; then
      journalctl --vacuum-size=100M 2>&1
    else
      echo "--> journalctl binary inaccessible."
    fi
    echo "Task 5 completed successfully."
    echo ""
  fi

  # Task 6: Remove Leftover Flatpak Runtimes
  if [[ " $CHOICES " == *" 6 "* ]]; then
    echo "========================================================="
    echo "[TASK 6] Removing Unused Flatpak Runtimes"
    echo "========================================================="
    if command -v flatpak &> /dev/null; then
      flatpak uninstall --unused -y 2>&1
    else
      echo "--> flatpak binary inaccessible."
    fi
    echo "Task 6 completed successfully."
    echo ""
  fi

  # Task 7: Optimize Solid State Drives
  if [[ " $CHOICES " == *" 7 "* ]]; then
    echo "========================================================="
    echo "[TASK 7] Optimizing Solid State Drives (fstrim)"
    echo "========================================================="
    if command -v fstrim &> /dev/null; then
      fstrim -va 2>&1
    else
      echo "--> fstrim binary inaccessible."
    fi
    echo "Task 7 completed successfully."
    echo ""
  fi

  # Task 8: Empty User Recycle Bin
  if [[ " $CHOICES " == *" 8 "* ]]; then
    echo "========================================================="
    echo "[TASK 8] Emptying System Trash and Recycle Bins"
    echo "========================================================="
    if [ -d "$TRASH_DIR" ]; then
      echo "--> Purging items inside $TRASH_DIR..."
      rm -rf "$TRASH_DIR/files/"* "$TRASH_DIR/info/"* 2>&1
      echo "Trash bin successfully cleared."
    else
      echo "--> No standard local user trash frames detected."
    fi
    echo "Task 8 completed successfully."
    echo ""
  fi

  echo "========================================================="
  echo "All selected maintenance operations have concluded!"
  echo "Feel free to review the log above and close this window."
  echo "========================================================="


  # ====================================================================
  # Space Statistics Finalization (Fixed Missing Syntax Tags)
  # ====================================================================
  # Calculate final space statistics
  AFTER_KB=$(df / | awk 'NR==2 {print $4}')
  SAVED_KB=$((AFTER_KB - BEFORE_KB))

  if [ "$SAVED_KB" -gt 0 ]; then
    if command -v bc &> /dev/null; then
      SAVED_MB=$(echo "scale=2; $SAVED_KB / 1024" | bc)
    else
      SAVED_MB=$((SAVED_KB / 1024))
    fi
    MSG="All wrapped up! Your selected optimization tasks finished perfectly. You reclaimed roughly ${SAVED_MB} MB of storage space."
  else
    MSG="All wrapped up! Your selected optimization tasks finished cleanly, though no measurable storage space was changed."
  fi # FIXED: Missing conditional block closure

  # Present the final processing metrics window alerts to the user
  run_as_user zenity --info --title="Maintenance Complete" --text="$MSG" --width=380
  run_as_user notify-send "Maintenance Complete" "$MSG" --icon=system-software-update
  
  # Ensure the log folder and file belong to root but are readable by standard users
chmod 755 "$LOG_DIR" 2>/dev/null
chmod 644 "$LOG_FILE" 2>/dev/null

# System resource garbage collection
unset PULSE_SERVER USER_DISPLAY USER_WAYLAND USER_RUNTIME USER_DBUS REAL_USER

}

# --------------------------------------------------------------------
# Execution Pipeline Wrapper (Natively Processes foreground commands)
# --------------------------------------------------------------------
# Silences background sound server warnings
export PULSE_SERVER=unix:/run/user/$UID/pulse/native

# Stream tasks straight to the live view component
run_tasks | run_as_user zenity --text-info \
  --title="Maintenance Processing Log" \
  --width=750 --height=500 \
  --font="Monospace 10" \
  --auto-scroll

# System resource garbage collection
unset PULSE_SERVER USER_DISPLAY USER_WAYLAND USER_RUNTIME USER_DBUS REAL_USER

# Clean environment exit
exit 0


