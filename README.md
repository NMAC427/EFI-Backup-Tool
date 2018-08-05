# EFI Backup Tool
Used to backup the EFI partition of a Hackintosh to a remote smb server. It automaticaly mounts the correct EFI partition and creates a local and/or a remote backup. The local backup is just a `.zip` file containing the contents of the `/EFI` folder on the EFI partition (usefull in connection with at Time Machine Backup). A remote backup (backup to a smb volume) copies the content of the `/EFI` folder (as a `.zip` file) to a smb server and keeps the previous versions of the backup.

## Usage
```
sh main.sh -l "~/efi_backup.zip" -r "//username:password@127.0.0.1/home"
```

To automatically backup the EFI partition after every sucesfull boot, create a bash script (with file extension `.command` & `$ chmod +x your_script.command`) that calls `main.sh` with the correct arguments and attach it to your Login Items (System Preferences > Users & Groups > Login Items).
