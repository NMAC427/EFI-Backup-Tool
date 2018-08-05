#! /bin/bash
#
# Makes a local backup of the EFI partition

tmp_backup_file="/tmp/backup_$(uuidgen).zip"

# Create ZIP File in tmp dir
cd "$efi_mount_point"
zip -X -q -r "$tmp_backup_file" "./EFI"
zip_md5=$(md5 -q "$tmp_backup_file")
efi_backup_filename="$(date "+%Y-%m-%d_%H-%M-%S")_$zip_md5.zip"

echo "Did create EFI zip file"

# CP to Local
if [[ -n "$LOCAL_BACKUP_FILE" ]]; then
	if [[ ! -d $(dirname "$LOCAL_BACKUP_FILE") ]]; then
		mkdir -p "$(dirname "$LOCAL_BACKUP_FILE")"
	fi

	if [[ "$(md5 -q $LOCAL_BACKUP_FILE 2> /dev/null)" != "$zip_md5" ]]; then
		cp "$tmp_backup_file" "$LOCAL_BACKUP_FILE"
		echo "Did copy EFI backup to $LOCAL_BACKUP_FILE"
	fi
fi

# CP to Remote
if [[ -n "$BACKUP_DIR_MOUNT_POINT" ]]; then

	efi_backup_dir="$BACKUP_DIR_MOUNT_POINT/EFI_BACKUPS/$efi_uuid"

	if [[ -d "$BACKUP_DIR_MOUNT_POINT" ]]; then
		if [[ ! -d "$efi_backup_dir" ]]; then
			mkdir -p "$efi_backup_dir"
		fi

		IFS=', ' read -r -a backups <<< "$(findBackups $efi_backup_dir)"; unset IFS
		md5_list=()

		for backup in "${backups[@]}"; do
			md5=$(echo ${backup##*_}| cut -d"." -f1)
			md5_list+=("$md5")
		done

		if ! elementIn "$zip_md5" "${md5_list[@]}" ; then
			cp "$tmp_backup_file" "$efi_backup_dir/$efi_backup_filename"
		fi

	else
		echo "BACKUP_DIR_MOUNT_POINT \"$BACKUP_DIR_MOUNT_POINT\" not found."
	fi

fi



# Clean-up
rm "$tmp_backup_file"
