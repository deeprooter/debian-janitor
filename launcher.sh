#!/bin/bash
#===============================================================
# Script Name:    launcher.sh
# Description:    Automates package repair, cleanup, and tuning for Debian.
# Author:         Kamal K. Chhoker halides@live.com
# Ownership:      Kamal K. Chhoker
# License:        MIT License
# Version:        1.0.0
# Date Created:   2026-07-19
# Last Modified:  2026-07-21
#===============================================================
# explicit administrative checking guard rails
if [ "$EUID" -ne 0 ]; then
  echo "Fatal error: You must call this file context utilizing sudo execution."
  read -p "Press [Enter] to terminate process execution..." -r
  exit 1
fi

#resolve absolute execution base path dynamically
working_directory="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")"

echo "Evaluating desktop capabilities..."

# check path structure for existing zenity graphical instances
if command -v zenity &> /dev/null; then
  echo "--> UI architecture active. Loading desktop interface tools..."
  echo "--------------------------------------------------"
  target_gui_script="$working_directory/6.2-zenity-rsp.sh"
  if [ -f "$target_gui_script" ]; then
    bash "$target_gui_script"
  else
    echo "System Error: Missing script dependency target: $target_gui_script"
    read -p "Press [Enter] to continue..." -r
  fi

else
  echo "--> No desktop engine detected. Reverting to console mode interfaces..."
  echo "--------------------------------------------------"
  
  target_tui_script="$working_directory/7-whiptail.sh"
  if [ -f "$target_tui_script" ]; then
    bash "$target_tui_script"
  else
    echo "System Error: Missing script dependency target: $target_tui_script"
    read -p "Press [Enter] to continue..." -r
  fi
fi
