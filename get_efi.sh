#! /bin/bash
#
# Tries to locate the correct EFI partition to backup and saves it
# in the EFI_PARTITION variable.

if [[ -z "$EFI_PARTITION" ]]; then

	partitions=$(plread ":AllDisks" "$(diskutil list -plist)" | sed -e 1d -e '$d' | grep -E "disk[0-9]+s" | xargs)
	efi_partitions=()

	for part in $partitions; do
		part_info=$(diskutil info -plist $part)
		content=$(plread ":Content" "$part_info")
		volume_name=$(plread ":VolumeName" "$part_info")
		disk_uuid=$(plread ":DiskUUID" "$part_info")
		is_internal=$(plread ":Internal" "$part_info")

		# Check if partition is EFI partition and append to efi_partitions
		if [[ $content == "EFI" ]]; then
			if (([[ -z "$EFI_NAME" ]] || [[ "$EFI_NAME" == "$volume_name" ]]) && \
				([[ -z "$DISK_UUID" ]] || [[ "$DISK_UUID" == "$disk_uuid" ]]) && \
				([[ "$is_internal" == "true" ]])); then
				efi_partitions+=("$part")
			fi
		fi

	done

	num_found_efi=${#efi_partitions[@]}

	if (( num_found_efi  == 0 )); then
		echo "Error: No matching EFI partition found."
		exit
	elif (( num_found_efi != 1 )); then
		echo "Error: $num_found_efi EFI partitions found (${efi_partitions[@]})."
		exit
	fi

	EFI_PARTITION="${efi_partitions[0]}"

	echo "Found EFI Partition $EFI_PARTITION"
fi
