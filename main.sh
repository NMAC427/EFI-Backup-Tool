#! /bin/bash
#
# Main file that call the individual subroutines for backing up the EFI partition.

readonly SCRIPT_PATH="$(cd "$(dirname "$0")"; pwd -P)"
source "$SCRIPT_PATH/helper_functions.sh"

# Get Arguments
KEEP_OLD_BACKUPS=15
DRY_RUN=false

while true; do
	case "$1" in
		-h | --help ) HELP=true; shift ;;
		-p | --partition ) EFI_PARTITION="$2"; shift; shift ;;
		-n | --efi-name ) EFI_NAME="$2"; shift; shift ;;
		-u | --uuid ) DISK_UUID="$2"; shift; shift ;;
		-k | --keep ) KEEP_OLD_BACKUPS="$2"; shift; shift ;;
		-l | --local ) LOCAL_BACKUP_FILE="$2"; shift; shift ;;
		-r | --remote ) REMOTE_SERVER="$2"; shift; shift ;;
		--dry-run ) DRY_RUN=true; shift ;;
		-- ) shift; break ;;
		* )
			if [[ -n "$1" ]]; then
				echo "Unknown argument \"$1\""
				exit
			fi
			
			break ;;
	esac
done

if [[ $HELP == true ]]; then

	echo \
"$(basename "$0") [-h] [-p device | [-n name | -u id] [-k n] [-r server] [--dry-run] -- backup your EFI partition

where:
	-h, --help
		Show this help text.
	-p device, --partition device
		Manually set the EFI partition device (eg. disk0s1).
	-n name, --efi-name name
		Set the name of your EFI partition (eg. EFI) to search for.
	-u id, -uuid id
		Set the UUID of the EFI partition to search for (Disk / Partition UUID).
	-k n, --keep n
		Specify how many backups should be kept on the remote server.
	-l path, --local path
		Set the path for the local backup file.
	-r server, --remote server
		The smbfs server to mount. See mount_smbfs for more information.
	--dry-run
		Show which backups would have been removed.

EXAMPLE:
	sh main.sh -l \"$HOME/efi_backup.zip\" -r \"//username:password@127.0.0.1/home\" -k 15"
	exit
fi



# Find EFI Partition
source "$SCRIPT_PATH/get_efi.sh"

# Mount EFI Partition
efi_info=$(diskutil info -plist $EFI_PARTITION)
efi_mount_point=$(plread ":MountPoint" "$efi_info")
diskutil mount "$EFI_PARTITION" 1> /dev/null

if [[ -z "$efi_mount_point" ]]; then
	UNMOUNT_AFTER_BACKUP=true
fi

efi_info=$(diskutil info -plist $EFI_PARTITION)
efi_mount_point=$(plread ":MountPoint" "$efi_info")
efi_uuid=$(plread ":DiskUUID" "$efi_info")

echo "Did mount EFI partition ($EFI_PARTITION) at $efi_mount_point"

# Mount remote disk
if [[ -n "$REMOTE_SERVER" ]]; then
	BACKUP_DIR_MOUNT_POINT="$HOME/.smb_efi"
	mkdir "$BACKUP_DIR_MOUNT_POINT"
	mount_smbfs "$REMOTE_SERVER" "$BACKUP_DIR_MOUNT_POINT"

	echo "Did mount remote server"
fi

clean_up_remote() {
	if [[ -n "$BACKUP_DIR_MOUNT_POINT" ]]; then
		umount "$BACKUP_DIR_MOUNT_POINT"
		rm -rf "$BACKUP_DIR_MOUNT_POINT"
	fi
}

# Make Backup
source "$SCRIPT_PATH/make_backup.sh"
cd $HOME

if [[ $UNMOUNT_AFTER_BACKUP == true ]]; then
	diskutil umount "$EFI_PARTITION" 1> /dev/null
fi

# Remove old Backups
if [[ ! -d "$efi_backup_dir" ]]; then
	clean_up_remote
	exit
fi

if elementIn "$zip_md5" "${md5_list[@]}"; then
	clean_up_remote
	exit
fi

source "$SCRIPT_PATH/remove_old_backups.sh"

# Clean-up
clean_up_remote
