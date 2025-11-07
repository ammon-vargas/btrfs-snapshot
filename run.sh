#!/bin/bash

set -euo pipefail

# Requires: dialog or whiptail
DIALOG=${DIALOG:-whiptail}

trap '[[ -n "${MOUNT:-}" ]] && sudo umount "$MOUNT" 2>/dev/null || true' EXIT

function get_partitions() {
  lsblk -rno NAME,SIZE,FSTYPE | grep -E '^[a-zA-Z0-9]+[0-9]+' | while read -r name size fstype; do
    echo "/dev/$name - $size - $fstype"
  done
}

function select_partition() {
  local options=()
  while IFS= read -r line; do
    options+=("$line" "")
  done < <(get_partitions)

  PART=$($DIALOG --title "Select Partition" --menu "Choose a partition to mount:" 20 60 10 "${options[@]}" 3>&1 1>&2 2>&3) || exit 0
  PART=$(echo "$PART" | awk '{print $1}')
}

function choose_mountpoint() {
  MOUNT=$($DIALOG --inputbox "Enter mount point (e.g., /mnt/SNAPSHOTS):" 10 60 3>&1 1>&2 2>&3) || select_partition
  sudo mkdir -p "$MOUNT"
}

function mount_partition() {
  sudo mount "$PART" "$MOUNT" || {
    $DIALOG --msgbox "❌ Failed to mount $PART to $MOUNT" 10 40
    choose_mountpoint
  }
}

function check_btrfs() {
  if ! blkid "$PART" | grep -q 'TYPE="btrfs"'; then
    $DIALOG --msgbox "❌ Partition is not Btrfs. Cannot create subvolume." 10 50
    return 1
  fi
  return 0
}

function list_subvolumes() {
  SUBS=$(sudo btrfs subvolume list "$MOUNT" | awk '{print $NF}')
  $DIALOG --msgbox "📂 Existing subvolumes:\n$SUBS" 15 50
}

function ask_subvolume() {
  $DIALOG --yesno "Do you want to create a Btrfs subvolume?" 10 40
  [[ $? -eq 0 ]] && name_subvolume
}

function name_subvolume() {
  check_btrfs || return
  list_subvolumes
  SUBVOL=$($DIALOG --inputbox "Enter subvolume name (e.g., @):" 10 40 3>&1 1>&2 2>&3) || ask_subvolume
  sudo btrfs subvolume create "$MOUNT/$SUBVOL"
  $DIALOG --msgbox "✅ Subvolume '$SUBVOL' created at $MOUNT/$SUBVOL" 10 50
}

function main_menu() {
  $DIALOG --msgbox "🚀 Btrfs Interactive Mount & Subvolume Tool\nCreated by Ammon" 10 50
  while true; do
    select_partition
    choose_mountpoint
    mount_partition
    ask_subvolume
    $DIALOG --yesno "Do you want to perform another operation?" 10 40 || break
  done
}

main_menu
