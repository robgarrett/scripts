#!/bin/bash

# cleanup-kernels.sh — Remove old linux-image packages except the current kernel

set -e

CURRENT_KERNEL=$(uname -r)
LOGFILE="/var/log/kernel_cleanup.log"
DRY_RUN=false

echo "Starting kernel cleanup..." | tee -a "$LOGFILE"
echo "Current kernel: $CURRENT_KERNEL" | tee -a "$LOGFILE"

# Parse optional --dry-run flag
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "Dry run mode enabled. No packages will be removed." | tee -a "$LOGFILE"
fi

# Get list of installed linux-image packages excluding the current kernel
PACKAGES=$(dpkg -l | grep linux-image | awk '{print $2}' | grep -v "$CURRENT_KERNEL")

if [[ -z "$PACKAGES" ]]; then
  echo "No old kernels found to remove." | tee -a "$LOGFILE"
  exit 0
fi

for pkg in $PACKAGES; do
  echo "Found: $pkg" | tee -a "$LOGFILE"
  if $DRY_RUN; then
    echo "Would remove: $pkg" | tee -a "$LOGFILE"
  else
    echo "Removing: $pkg" | tee -a "$LOGFILE"
    sudo apt remove --purge -y "$pkg" >> "$LOGFILE" 2>&1
  fi
done

if ! $DRY_RUN; then
  echo "Running autoremove and cleanup..." | tee -a "$LOGFILE"
  sudo apt autoremove --purge -y >> "$LOGFILE" 2>&1
  sudo apt clean >> "$LOGFILE" 2>&1
  sudo update-grub >> "$LOGFILE" 2>&1
fi

echo "Kernel cleanup complete." | tee -a "$LOGFILE"

