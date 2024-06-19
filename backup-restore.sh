#!/bin/bash
# Deffn/Not-MyNumbness Simple Backup Script

set -e  # Exit immediately if a command returns a non-zero status

# Prompt user for label name
read -p "Enter the label name of the backup drive: " backup_label

# Prompt user for backup folder name
read -p "Enter the folder name for the backup: " backup_folder
root="/"
backup_location="/run/media/$whoami/$backup_label/$backup_folder"
backup_media="/run/media/$whoami/$backup_label"
#logic="rsync -aAXH --info=progress2 --delete --exclude='/boot/*' --exclude='/efi' --exclude='/swap/*' --exclude='/dev/*' --exclude='/proc/*' --exclude='/sys/*' --exclude='/tmp/*' --exclude='/run/*' --exclude='/mnt/*' --exclude='/media/*' --exclude='/lost+found/' "
logic="rsync -aAXH --info=progress2 --delete --exclude={'/boot','/efi','/swap','/dev','/proc','/sys','/tmp','/run','/mnt','/media','/lost+found/'} "


# Logging function
log() {
    echo "$(date +"%Y-%m-%d %T") - $1" >> backup_log.txt
}

# Check if script is running with root permissions
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root permissions. Please enter your password to continue:"
    sudo -v
    if [ $? -ne 0 ]; then
        echo "Sorry, you must have sudo privileges to run this script."
        exit 1
    fi
fi

# Check if the drive with the specified label is present
if lsblk -o LABEL | grep -q "$backup_label"; then
    echo "Drive with label $backup_label is present."
    if grep -qs "$backup_media" /proc/mounts; then
        echo "Drive is already mounted at $backup_media"
    else
        echo "Drive is not mounted but present, mounting the drive at $backup_media"
        # Add logic here to mount the drive
        udisksctl mount -b /dev/disk/by-label/$backup_label
    fi
else
    echo "Drive with label $backup_label is not present."
fi

# Check if the directory exists, if not create it
if [ ! -d "$backup_location" ]; then
    echo "Backup location $backup_location does not exist. Creating directory..."
    mkdir -p "$backup_location"
    echo "Directory created at $backup_location"
fi

# Confirmation prompt
read -p "Do you want to back up or restore? (Type 'backup' or 'restore'): " action

if [ "$action" == "backup" ]; then
    echo "Starting backup process to $backup_location..."
    log "Backup process started to $backup_location"
    $logic $root $backup_location
    log "Backup command executed: $logic $root $backup_location"
elif [ "$action" == "restore" ]; then
    echo "Starting restore process from $backup_location..."
    log "Restore process started from $backup_location"
    $logic $backup_location $root
    log "Restore command executed: $logic $backup_location $root"
else
    echo "Invalid input. Please type 'backup' or 'restore'."
    log "Invalid input received: $action"
fi

# Testing comment
# Remember to test this script thoroughly on sample data before using it for critical backups

