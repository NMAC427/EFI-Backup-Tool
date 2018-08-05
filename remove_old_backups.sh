#! /bin/bash
#
# Removes old / dupliacte backups from remote.

IFS=', ' read -r -a backups <<< "$(findBackups $efi_backup_dir)"; unset IFS

current_time=$(date +%s)
backups_age=()
backups_md5=()

for backup in "${backups[@]}"; do
	eval $(stat -s "$backup")

	age=$(expr $current_time - $st_ctime)
	md5=$(echo ${backup##*_}| cut -d"." -f1)
	backups_age+=("$age")
	backups_md5+=("$md5")
done

getBackupAge() {
	for ((i=0;i<"${#backups[@]}";i++)); do
		if [[ "$1" == "${backups[$i]}" ]]; then
			echo "${backups_age[$i]}"
			return
		fi
	done
}

getBackupMD5() {
	for ((i=0;i<"${#backups[@]}";i++)); do
		if [[ "$1" == "${backups[$i]}" ]]; then
			echo "${backups_md5[$i]}"
			return
		fi
	done
}

# Filter

b_this_hour=()
b_today=()
b_yesterday=()
b_this_week=()
b_this_month=()
b_last_month=()
b_this_year=()
b_older=()

for ((i=0;i<"${#backups[@]}";i++)); do
	backup="${backups[$i]}"
	md5="${backups_md5[$i]}"
	age="${backups_age[$i]}"

	# Remove duplicate files with same MD5
	if ! elementIn "$md5" "${__md5_set[@]}"; then
		__md5_set+=("$md5")
	else
		backups_to_remove+=("${backups[$i]}")
		continue
	fi

	# Age
	if [[ "$age" -gt "31556736" ]]; then
		b_older+=("$backup")
	elif [[ "$age" -gt "5259456" ]]; then
		b_this_year+=("$backup")
	elif [[ "$age" -gt "2629728" ]]; then
		b_last_month+=("$backup")
	elif [[ "$age" -gt "604000" ]]; then
		b_this_month+=("$backup")
	elif [[ "$age" -gt "172800" ]]; then
		b_this_week+=("$backup")
	elif [[ "$age" -gt "86400" ]]; then
		b_yesterday+=("$backup")
	elif [[ "$age" -gt "3600" ]]; then
		b_today+=("$backup")
	else
		b_this_hour+=("$backup")
	fi
done

# echo "TH: ${b_this_hour[@]}"
# echo "T:  ${b_today[@]}"
# echo "Y:  ${b_yesterday[@]}"
# echo "TW: ${b_this_week[@]}"
# echo "TM: ${b_this_month[@]}"
# echo "LM: ${b_last_month[@]}"
# echo "TY: ${b_this_year[@]}"
# echo "O:  ${b_older[@]}"

# Choose which backups to remove

keep_count="$(( ${#b_this_hour[@]} + ${#b_today[@]} ))" # Keeps all backups made this hour and day

for array_name in b_yesterday b_this_week b_this_month; do # Keeps at least one backup made yesterday, this week and this month 
	IFS=', ' read -r -a array <<< "$(eval "echo \${$array_name[@]}")"; unset IFS
	keep_count="$(( $keep_count + $(minimum ${#array[@]} 1) ))"
done

for array_name in b_yesterday b_this_week b_this_month; do
	IFS=', ' read -r -a array <<< "$(eval "echo \${$array_name[@]}")"; unset IFS

	for backup in "${array[@]:1}"; do
		if [[ "$keep_count" -lt "$KEEP_OLD_BACKUPS" ]]; then
			keep_count="$(( $keep_count + 1 ))"
		else
			backups_to_remove+=("$backup")
		fi
	done
done

for array_name in b_last_month b_this_year b_older; do
	IFS=', ' read -r -a array <<< "$(eval "echo \${$array_name[@]}")"; unset IFS
	keep_count="$(( $keep_count + $(minimum ${#array[@]} 1) ))"

	for backup in "${array[@]}"; do
		if [[ "$keep_count" -lt "$KEEP_OLD_BACKUPS" ]]; then
			keep_count="$(( $keep_count + 1 ))"
		else
			backups_to_remove+=("$backup")
		fi
	done
done

if [[ "$DRY_RUN" != true ]]; then
	# Delete Backups
	for backup in "${backups_to_remove[@]}"; do
		rm "$backup"
	done

	echo "Did delete backups: ${backups_to_remove[@]}"
else
	echo "Would delete backups: ${backups_to_remove[@]}"
fi
