#!/bin/bash
#===============================================================
# Script Name:    7-whiptail.sh
# Description:    Automates package repair, cleanup, and tuning for Debian.
# Author:         Kamal K. Chhoker halides@live.com
# Ownership:      Kamal K. Chhoker
# License:        MIT License
# Version:        1.0.0
# Date Created:   2026-07-18
# Last Modified:  2026-07-21
#===============================================================

# check for administrative permission rules
if [ "$EUID" -ne 0 ]; then
  echo "Error: elevated administrative privileges needed."
  read -p "Hit [Enter] to terminate runtime..." -r
  exit 1
fi

# map targeting configurations for standard shell environment paths
active_user=$SUDO_USER
if [ -z "$active_user" ]; then
  active_user=$(whoami)
fi
user_home_dir=$(eval echo "~$active_user")
trash_folder_location="$user_home_dir/.local/share/Trash"

# ----------------------------------------------------
# Run Terminal Menu Checkboxes (Whiptail TUI)
# ----------------------------------------------------
chosen_operations=$(whiptail --title "System Optimization Core" \
  --checklist "Toggle options using [Spacebar] and confirm via [Enter]:" 16 65 3 \
  "1" "Scrape Package Caches & Fix Dependencies" OFF \
  "2" "Flush Local User Recycle Bin" OFF \
  "3" "Fetch & Apply Upstream Updates" OFF \
  3>&1 1>&2 2>&3)

# ensure safe bubble drop if cancelled out entirely
if [ $? -ne 0 ] || [ -z "$chosen_operations" ]; then
  clear
  echo "Execution scope skipped by client."
  exit 0
fi

clear
echo "Initializing maintenance sequence..."
echo "--------------------------------------------------"
starting_block_count=$(df / | awk 'NR==2 {print $4}')

# ----------------------------------------------------
# Action Evaluation Trees
# ----------------------------------------------------
if [[ "$chosen_operations" == *"1"* ]]; then
  echo ""
  echo "=================================================="
  echo " Running Task 1: Package System Optimizations"
  echo "=================================================="
  echo "--> Solving outstanding file dependency conflicts..."
  apt-get install -f -y
  echo "--> Removing abandoned development dependencies..."
  apt-get autoremove --purge -y
  
  stale_packages=$(dpkg -l | grep "^rc" | awk '{print $2}')
  if [ -n "$stale_packages" ]; then
    echo "--> Scrubbing lingering config artifacts..."
    dpkg --purge $stale_packages
  fi
  
  echo "--> Flushing cached distribution archives..."
  apt-get autoclean -y
  apt-get clean
fi

if [[ "$chosen_operations" == *"2"* ]]; then
  echo ""
  echo "=================================================="
  echo " Running Task 2: Emptying System Trash Folders"
  echo "=================================================="
  echo "Targeting mount frame: $trash_folder_location"
  if [ -d "$trash_folder_location" ]; then
    rm -rf "$trash_folder_location/files"/* "$trash_folder_location/info"/* "$trash_folder_location/expunged"/* 2>/dev/null
    echo "--> Subdirectories flushed out."
  else
    echo "--> Local trash configuration is clear."
  fi
fi

if [[ "$chosen_operations" == *"3"* ]]; then
  echo ""
  echo "=================================================="
  echo " Running Task 3: Package System Core Updates"
  echo "=================================================="
  echo "--> Syncing changes from main repositories..."
  apt-get update
  echo "--> Updating base distribution packages safely..."
  apt-get dist-upgrade -y
fi

# ----------------------------------------------------
# Evaluate Results & Form Message
# ----------------------------------------------------
ending_block_count=$(df / | awk 'NR==2 {print $4}')
blocks_saved=$((ending_block_count - starting_block_count))

if [ "$blocks_saved" -gt 0 ]; then
  if command -v bc &> /dev/null; then
    calculated_mb=$(echo "scale=2; $blocks_saved / 1024" | bc)
  else
    calculated_mb=$((blocks_saved / 1024))
  fi
  alert_message="All tasks finalized!\n\nYour filesystem recovered roughly ${calculated_mb} MB of data storage blocks."
else
  alert_message="All actions finalized successfully. No extra filesystem blocks required pruning."
fi

# show nice clean modal screen layout
whiptail --title "System Operations Complete" --msgbox "$alert_message" 11 55

clear
echo "Cleanup script completed successfully."
