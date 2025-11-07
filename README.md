# AutoBackup

## A. Project Overview

**AutoBackup** is a simple, portable Linux shell script that creates compressed backups of a source directory, generates SHA256 checksums, rotates old backups, and logs actions. It supports a dry-run mode for testing and is easy to schedule via `cron`.

---

## B. Features

* Create compressed `.tar.gz` backups named with timestamp
* Generate `.sha256` checksum files for integrity verification
* Automatic rotation (keep the last `N` backups)
* Dry-run mode to preview actions without making changes
* Logging of success / errors
* Small, dependency-free Bash script (works on most Linux systems)

---

## C. Prerequisites

* Linux / UNIX-like system
* Bash shell
* `tar`, `gzip` (usually installed)
* `sha256sum` (from coreutils)
* (Optional) `cron` for scheduling

---

## D. Repository files

* `backup.sh` — main backup script
* `backup.config` — configuration file (defaults used by script)
* `README.md` — this file

---

## E. Quick installation 

1. Clone the repository:

```bash
git clone https://github.com/sivapidathala/AutoBackup.git
cd AutoBackup
```

2. Make the script executable:

```bash
chmod +x backup.sh
```

3. (Optional) Inspect and edit `backup.config` to change defaults (see section F).

---

## F. Configuration (`backup.config`)

Open `backup.config` and edit values to suit your environment. Typical variables:

```bash
# Directory where backups are stored
BACKUP_DIR="$HOME/backups"

# How many backups to keep (rotation)
MAX_BACKUPS=5

# Logging file
LOG_FILE="$HOME/backups/backup.log"

# Whether to remove temporary files on failure (true/false)
CLEANUP_ON_ERROR=true
```

Save changes and make sure the `BACKUP_DIR` exists or the script can create it.

---

## G. Usage 

### 1) Basic usage — make a backup of `~/Documents`

```bash
./backup.sh ~/Documents
```

What happens:

* Script verifies source exists
* Ensures backup directory exists
* Creates timestamped archive: `backup-YYYY-MM-DD-HHMM.tar.gz`
* Generates checksum file: `backup-...tar.gz.sha256`
* Removes oldest backup if more than `MAX_BACKUPS`
* Logs all actions to `LOG_FILE`

### 2) Dry run — preview without writing files

```bash
./backup.sh --dry-run ~/Documents
```

The script will print what it would do, but won't create archives or modify backups.

### 3) Custom backup directory

```bash
./backup.sh --dest /mnt/backup_drive ~/Projects
```

(If script supports a `--dest` flag — otherwise change `BACKUP_DIR` in `backup.config`.)

---

## H. Scheduling with cron 

1. Open your crontab:

```bash
crontab -e
```

2. Add a cron entry to run backup every day at 2:30 AM:

```cron
30 2 * * * /path/to/AutoBackup/backup.sh /home/youruser/Documents >> /path/to/AutoBackup/backup.log 2>&1
```

3. Save and exit. Cron will now run backups automatically.

---

## I. Verify backup integrity

To verify a backup's checksum file:

```bash
cd $BACKUP_DIR
sha256sum -c backup-YYYY-MM-DD-HHMM.tar.gz.sha256
```

If the output shows `OK`, the file is intact.

---

## J. Restore a backup

1. Choose the backup file you want to restore, for example `backup-2025-11-03-1120.tar.gz`.

2. Extract it to a restore location:

```bash
mkdir -p /tmp/restore
tar -xzf backup-2025-11-03-1120.tar.gz -C /tmp/restore
```

3. Verify files in `/tmp/restore` and move them to the desired location.

---

## K. Logs

The script appends messages to `LOG_FILE` configured in `backup.config`. Typical log entries include timestamps, created archives, deleted old backups, and error messages.

---

## L. Troubleshooting

* **`ERROR: Source directory does not exist`** — Ensure the path you passed is correct.
* **Permissions issues** — Make sure the script has execute permission and the user has write access to `BACKUP_DIR`.
* **Disk full** — Check `df -h` and free up space or move `BACKUP_DIR` to a larger disk.
* **Cron runs but no backups** — Use absolute paths in cron and direct output to a logfile to capture errors.

---

## M. Suggested improvements

* Upload backups to remote storage (AWS S3, Google Drive) using `aws cli` or `rclone`.
* Add email or webhook notifications on success/failure.
* Add encryption support (e.g., `gpg`) for sensitive data.
* Add unit tests or linting for the script.

---

## N. Contribution & Development

1. Fork the repo
2. Create a feature branch
3. Make changes and test locally
4. Submit a pull request with a clear message

---

## O. License

Add a license file (e.g., `LICENSE`) if you want to make this project open-source. MIT is a common permissive choice.

---

## P. Author

Pidathala Siva — (repo owner)



