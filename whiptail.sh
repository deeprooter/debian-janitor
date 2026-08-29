#!/bin/bash
#===============================================================
# Script Name:   whiptail.sh
# Description:   Automates package repair, cleanup, and tuning for Debian.
# Author:        Kamal K. Chhoker <halides@live.com>
# Ownership:     Kamal K. Chhoker
# License:       MIT License
# Version:       1.0.0
# Date Created:  2026-07-19
# Last Modified: 2026-08-02
#===============================================================


# Automatically create the dedicated log directory if it doesn't exist
if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR"
  chmod 755 "$LOG_DIR"
fi


# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  read -p "Press [Enter] to exit..."
  exit 1
fi


# --------------------------------------------------------------------
# Automatic Lock Cleanup on Exit / Cancellation
# --------------------------------------------------------------------
cleanup() {
  echo ""
  echo "Cleaning up package manager locks..."
  # Safely release dpkg/apt locks if they exist
  rm -f /var/lib/dpkg/lock-frontend
  rm -f /var/lib/dpkg/lock
  rm -f /var/cache/apt/archives/lock
  rm -f /var/lib/apt/lists/lock
  # Configure broken packages if left in an unconfigured state
  dpkg --configure -a >/dev/null 2>&1
  
  echo -e "\n[!] Script interrupted or exiting. Cleaning up processes..."
  
  # Terminate all background processes sharing this script's Process Group ID (PGID)
  # Negative PID (-$$) targets the entire process group
  kill -TERM -$$ 2>/dev/null
  
  # Give them a brief moment to terminate gracefully, then force-kill if needed
  sleep 0.5
  kill -KILL -$$ 2>/dev/null
  
  exit 0
}
#-------------------------------------------------------------
#code for abrut process kill
#-------------------------------------------------------------
# Trap SIGINT (Ctrl+C), SIGTERM (Kill), and EXIT
trap cleanup SIGINT SIGTERM


# Detect the real user to find their home directory
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
  REAL_USER=$(whoami)
fi
USER_HOME=$(eval echo "~$REAL_USER")
TRASH_DIR="$USER_HOME/.local/share/Trash"


# --------------------------------------------------------------------
# TUI Selection Menu (Whiptail Checkbox Window)
# --------------------------------------------------------------------
CHOICES=$(whiptail --title "Debian Destro Janitor" \
  --checklist "Use [Spacebar] to select tasks, then press [Enter]:" 18 65 8 \
  "1" "Clean Package Cache & Fix Broken Dependencies" OFF \
  "2" "Scan for Failed Systemd Background Services" OFF \
  "3" "Install System Updates & Software Patches" OFF \
  "4" "Remove Old Snap Package Revisions (Frees Space)" OFF \
  "5" "Vacuum Systemd Journal Logs down to 100MB" OFF \
  "6" "Remove Leftover Unused Flatpak Runtimes" OFF \
  "7" "Optimize Solid State Drives (Run fstrim)" OFF \
  "8" "Empty User Recycle Bin / System Trash" OFF \
  3>&1 1>&2 2>&3)

# Replace your current cancel block with this debug code:
if [ $? -ne 0 ] || [ -z "$CHOICES" ]; then
  clear
  echo "Operation canceled by user."
  exit 0
fi


if [ $EXIT_STATUS -ne 0 ] || [ -z "$CHOICES" ]; then
  clear
  echo "Operation canceled by user."
  exit 0
fi

clear
echo "=== Starting Selected Maintenance Tasks ==="
BEFORE_KB=$(df / | awk 'NR==2 {print $4}')

# --------------------------------------------------------------------
# Task 1: Dpkg Clean
# --------------------------------------------------------------------
  if [[ " $CHOICES " == *"1"* ]]; then
    echo ""
    echo "========================================================="
    echo "[TASK 1] Tidying Up Package Managers & Cache Files"
    echo "========================================================="
    echo "--> Scanning and repairing any broken dependencies..."
    apt install -f -y #2>&1
    
    echo "--> Purging orphaned packages no longer needed by the system..."
    apt autoremove --purge -y #2>&1
    
    echo "--> Sweeping away leftover setup configuration files..."
    RESIDUAL_PKGS=$(dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$RESIDUAL_PKGS" ]; then
      dpkg --purge $RESIDUAL_PKGS #2>&1
    fi
    
    echo "--> Clearing old, redundant package download archives..."
    apt autoclean -y #2>&1
    apt clean #2>&1
    echo "Task 1 completed successfully."
    echo ""
  fi

   # Task 2: Scan for Failed Services
  if [[ " $CHOICES " == *"2"* ]]; then
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
  if [[ " $CHOICES " == *"3"* ]]; then
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
  if [[ " $CHOICES " == *"4"* ]]; then
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
      echo "--> Snap infrastructure is not installed on this machine."
    fi
    echo "Task 4 completed successfully."
    echo ""
  fi

  # Task 5: Vacuum Systemd Logs
  if [[ " $CHOICES " == *"5"* ]]; then
    echo "========================================================="
    echo "[TASK 5] Trimming Systemd Journal Logs to 100MB"
    echo "========================================================="
    if command -v journalctl &> /dev/null; then
      echo "--> Current journal log utilization:"
      journalctl --disk-usage 2>&1
      echo "--> Compacting logs down to 100M threshold..."
      journalctl --vacuum-size=100M 2>&1
    else
      echo "--> systemd-journald utility not found."
    fi
    echo "Task 5 completed successfully."
    echo ""
  fi

  # Task 6: Flatpak Unused Runtime Purge
  if [[ " $CHOICES " == *"6"* ]]; then
    echo "========================================================="
    echo "[TASK 6] Purging Leftover Flatpak App Runtimes"
    echo "========================================================="
    if command -v flatpak &> /dev/null; then
      echo "--> Querying unused runtimes..."
      flatpak uninstall --unused -y 2>&1
    else
      echo "--> Flatpak framework is not installed on this machine."
    fi
    echo "Task 6 completed successfully."
    echo ""
  fi

  # Task 7: SSD Optimization (fstrim)
  if [[ " $CHOICES " == *"7"* ]]; then
    echo "========================================================="
    echo "[TASK 7] Optimizing Storage Blocks (fstrim)"
    echo "========================================================="
    if command -v fstrim &> /dev/null; then
      echo "--> Dispatched trim command to all supported file systems..."
      fstrim -av 2>&1
    else
      echo "--> fstrim tool missing from system environment."
    fi
    echo "Task 7 completed successfully."
    echo ""
  fi

# Task 8: Trash Disposal
  if [[ " $CHOICES " == *"8"* ]]; then
    echo "========================================================="
    echo "[TASK 8] Emptying the System Recycle Bin"
    echo "========================================================="
    if [ -d "$TRASH_DIR" ]; then
      echo "--> Deleting files inside: $TRASH_DIR"
      # FIX 3: Target subdirectories explicitly without throwing glob errors
      rm -rf "$TRASH_DIR/files"/* "$TRASH_DIR/info"/* "$TRASH_DIR/expunged"/* 2>/dev/null
      echo "Your recycle bin has been emptied."
    else
      echo "--> Checked trash folder: Already clear or not configured."
    fi
    echo "Task 8 completed successfully."
    echo ""
  fi

  echo "========================================================="
  echo "All selected maintenance operations have concluded!"
  echo "Feel free to review the log above and close this window."
  echo "========================================================="

# --------------------------------------------------------------------
# Final Summary Box
# --------------------------------------------------------------------
AFTER_KB=$(df / | awk 'NR==2 {print $4}')

# FIX 2: Check safely if free space actually increased to prevent negative calculations
if [ "$AFTER_KB" -gt "$BEFORE_KB" ]; then
  SAVED_KB=$((AFTER_KB - BEFORE_KB))
  if command -v bc &> /dev/null; then
    SAVED_MB=$(echo "scale=2; $SAVED_KB / 1024" | bc)
  else
    SAVED_MB=$((SAVED_KB / 1024))
  fi
  MSG="Success! Tasks finished.\n\nYou recovered roughly ${SAVED_MB} MB of space."
else
  MSG="Success! Selected maintenance tasks finished cleanly.\n\n(No additional storage space was freed)."
fi

# Display final completion message box via whiptail
whiptail --title "Maintenance Complete" --msgbox "$MSG" 10 50

clear
echo "=== Script finished cleanly ==="

