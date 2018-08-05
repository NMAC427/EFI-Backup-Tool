#! /bin/bash
#
# File containing multiple helper functions

plread() {
	# Reads a value from a plist
	/usr/libexec/PlistBuddy -c "Print $1" /dev/stdin 2> /dev/null <<< $2
}

findBackups() {
	local path="$(pwd -P)"
	cd "$1"
	echo "$( (sort <<< $(IFS=" " find "$(pwd -P)" -iname "*.zip")) | xargs)"
	unset IFS
	cd "$path"
}

elementIn () {
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}

minimum() {
	echo $(($1>$2?$2:$1))
}

maximum() {
	echo $(($1>$2?$1:$2))
}