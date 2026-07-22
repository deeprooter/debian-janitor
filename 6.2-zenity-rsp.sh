#!/bin/bash
#===============================================================
# Script Name:    6.2-zenity-rsp.sh
# Description:    Automates package repair, cleanup, and tuning for Debian.
# Author:         Kamal K. Chhoker halides@live.com
# Ownership:      Kamal K. Chhoker
# License:        MIT License
# Version:        1.0.0
# Date Created:   2026-07-18
# Last Modified:  2026-07-21
#===============================================================

# quick sanity check for root
if [ "$EUID" -ne 0 ]; then
  echo "Error: run this with sudo context."
  read -p "Press Enter to quit..." -r
  exit 1
fi

# pull actual desktop user variables
current_user=$SUDO_USER
if [ -z "$current_user" ]; then
  current_user=$(whoami)
fi

user_home_dir=$(eval echo "~$current_user")
user_trash_path="$user_home_dir/.local/share/Trash"
target_uid=$(id -u "$current_user")
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$target_uid/bus"

# make sure zenity is ready
if ! command -v zenity &> /dev/null; then
  echo "Missing zenity UI wrapper. Grabbing it real quick..."
  apt-get update && apt-get install zenity -y
fi

# ----------------------------------------------------
# Present User Checklist Menu
# ----------------------------------------------------
selected_tasks=$(sudo -u "$current_user" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  zenity --list --checklist \
  --title="System Cleanup & Maintenance" \
  --text="Tweak options below and hit OK:" \
  --column="Run" --column="ID" --column="Action Summary" \
  FALSE "1" "Purge Package Cache & Broken Dependencies" \
  FALSE "2" "Wipe Local Recycle Bin" \
  FALSE "3" "Run Full System Software Updates" \
  --width=480 --height=320 2>/dev/null)

# exit cleanly if window is canceled
if [ $? -ne 0 ] || [ -z "$selected_tasks" ]; then
  echo "User canceled execution loop."
  exit 0
fi

initial_space=$(df / | awk 'NR==2 {print $4}')

# ----------------------------------------------------
# Operations Loop Pipeline
# ----------------------------------------------------
do_maintenance_work() {
  if [[ "$selected_tasks" == *"1"* ]]; then
    echo "=================================================="
    echo " [STEP 1] Running Dpkg Verification & Purge"
    echo "=================================================="
    echo "--> Running dependency fixups..."
    apt-get install -f -y 2>&1
    echo "--> Dropping unneeded system dependencies..."
    apt-get autoremove --purge -y 2>&1
    
    residual_configs=$(dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$residual_configs" ]; then
      echo "--> Scraping old config profiles..."
      dpkg --purge $residual_configs 2>&1
    fi
    
    echo "--> Emptying dynamic apt storage trees..."
    apt-get autoclean -y 2>&1
    apt-get clean 2>&1
  fi

  if [[ "$selected_tasks" == *"2"* ]]; then
    echo "=================================================="
    echo " [STEP 2] Scraping Trash Storage Trees"
    echo "=================================================="
    if [ -d "$user_trash_path" ]; then
      rm -rf "$user_trash_path/files"/* "$user_trash_path/info"/* "$user_trash_path/expunged"/* 2>/dev/null
      echo "--> Trash folders wiped."
    else
      echo "--> Directory path skipped (already blank or absent)."
    fi
  fi

  if [[ "$selected_tasks" == *"3"* ]]; then
    echo "=================================================="
    echo " [STEP 3] Synchronizing Distribution Registries"
    echo "=================================================="
    echo "--> Querying remote repositories..."
    apt-get update 2>&1
    echo "--> Deploying upgraded local binary layers..."
    apt-get dist-upgrade -y 2>&1
  fi

  echo ""
  echo "Done processing background tasks. Generating reports..."
  
  echo "This window can be closed now"
}

# Pipe direct command data straight into auto-scrolling log canvas
do_maintenance_work | sudo -u "$current_user" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  zenity --text-info \
  --title="dpkg and system cleaner" \
  --width=720 --height=480 \
  --font="Monospace 10" \
  --auto-scroll

# ----------------------------------------------------
# Process Results & Draw Alerts
# ----------------------------------------------------
final_space=$(df / | awk 'NR==2 {print $4}')
freed_blocks=$((final_space - initial_space))

if [ "$freed_blocks" -gt 0 ]; then
  if command -v bc &> /dev/null; then
    mb_freed=$(echo "scale=2; $freed_blocks / 1024" | bc)
  else
    mb_freed=$((freed_blocks / 1024))
  fi
  final_summary_msg="Maintenance completed successfully! Cleared up about ${mb_freed} MB."
else
  final_summary_msg="All selected cleanups finished smoothly. No extra disk files needed removing."
fi

# Visual popups
sudo -u "$current_user" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  zenity --info --title="Job Complete" --text="$final_summary_msg" --width=350

sudo -u "$current_user" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  notify-send "Maintenance Complete" "$final_summary_msg" --icon=system-software-update
