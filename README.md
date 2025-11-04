# AutoBackup
#Automated Backup Script with Checksum Verification

##  Overview
This project provides a **bash-based backup automation script** that creates compressed tarball backups, verifies their integrity with a **checksum**, and supports **dry-run**, **logging**, and **rotation logic** (upcoming step).

---

## Features
 Argument parsing for source directories 
 Automatic backup folder creation 
 Exclude patterns (optional) 
 Dry-run mode for testing without file creation 
 SHA256 checksum generation and verification 
 Logging of all actions 
 (Coming soon) Backup rotation – daily/weekly/monthly retention 

---

##  Project Structure
```
backup.sh
README.md
backups/
└── backup-YYYY-MM-DD-HHMM.tar.gz
└── backup-YYYY-MM-DD-HHMM.tar.gz.sha256
└── backup.log
```

---

##  How to Use

### 1️⃣Script Executable
```bash
chmod +x backup.sh
```

---

### 2️⃣ Dry Run (Test Mode)
Simulates backup without creating any files.

```bash
./backup.sh --dry-run ~/test_backup/src
```

 **Expected Output:**
```
DRY RUN: Would create tarball /home/youruser/backups/backup-2025-11-03-1120.tar.gz
DRY RUN: Would create checksum /home/youruser/backups/backup-2025-11-03-1120.tar.gz.sha256
```

---

### 3️⃣ Backup
Creates a `.tar.gz` backup and a `.sha256` checksum file.

```bash
./backup.sh ~/test_backup/src
```

 **Result:**
```bash
ls -lh ~/backups
```

You should see:
```
backup-2025-11-03-1120.tar.gz
backup-2025-11-03-1120.tar.gz.sha256
backup.log
```

---

### 4️⃣The Checksum Manually (Optional)
To ensure file integrity:
```bash
sha256sum -c ~/backups/backup-2025-11-03-1120.tar.gz.sha256
```

Output:
```
backup-2025-11-03-1120.tar.gz: OK
```

---

##  Step 8 – Create and Verify Checksum (Code)
```bash
# --- Create and Verify Checksum ---
CHECKSUM_FILE="$BACKUP_PATH.sha256"

if [ "$DRY_RUN" = true ]; then
  log "DRY RUN: Would create checksum $CHECKSUM_FILE"
else
  sha256sum "$BACKUP_PATH" > "$CHECKSUM_FILE"
  log "INFO: Created checksum file $CHECKSUM_FILE"

  if sha256sum -c "$CHECKSUM_FILE" >/dev/null 2>&1; then
    log "SUCCESS: Checksum verified"
  else
    log "ERROR: Checksum verification failed"
  fi
fi
```

---

##  Step 9 – Testing the Script
```bash
mkdir -p ~/test_backup/src
echo "hello world" > ~/test_backup/src/file1.txt

# Dry run
./backup.sh --dry-run ~/test_backup/src

# Real backup
./backup.sh ~/test_backup/src
```

---

##  Log Example (`~/backups/backup.log`)
```
INFO: Starting backup for /home/user/test_backup/src
INFO: Created backup /home/user/backups/backup-2025-11-03-1120.tar.gz
INFO: Created checksum file /home/user/backups/backup-2025-11-03-1120.tar.gz.sha256
SUCCESS: Checksum verified
```

---

##  Upcoming Step (Step 10)
Add rotation logic to automatically manage:
- Daily backups (keep 7 days)
- Weekly backups (keep 4 weeks)
- onthly backups (keep 12 months)

---

## Author
**PIDATHALA SIVA
ASSOCIATE ENGINEER

---

##  License
This project is open-source under the **MIT License**.

1) Create project folder & initialize repo
mkdir -p ~/backup-system
cd ~/backup-system
git init

2) Create the config file backup.config

Create backup.config with your editor (nano, vim, etc.):

backup.config

#=== Backup Configuration ===
BACKUP_DESTINATION="$HOME/backups"
EXCLUDE_PATTERNS=".git,node_modules,.cache"
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
EMAIL="admin@example.com"        # optional; simulated
LOG_FILE="$BACKUP_DESTINATION/backup.log"


Save and close.

3) Create the main script backup.sh (skeleton + sections)

Create backup.sh and make it executable:

nano backup.sh
chmod +x backup.sh


Paste this skeleton into backup.sh (you’ll expand each section in next steps):

#!/bin/bash
set -euo pipefail

CONFIG_FILE="./backup.config"
LOCK_FILE="/tmp/backup.lock"

# ---load config ---
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  echo "Error: $CONFIG_FILE not found"; exit 1
fi

mkdir -p "$BACKUP_DESTINATION"
touch "$LOG_FILE"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

 #Lock
if [ -f "$LOCK_FILE" ]; then
  log "ERROR: locking file exists — another run in progress"; exit 1
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

*# parse options (dry-run, list, restore) ... (expand later)

# main flow:
# 1. validate source
# 2. build exclude args
# 3. create backup tar.gz
# 4. checksum (sha256)
# 5. verify checksum
# 6. test extract a file
# 7. rotate/delete old backups (daily/weekly/monthly)
# 8. clean up & exit


Save and close.

4) Implement argument parsing (dry-run, list, restore)

Edit backup.sh to support:

--dry-run (no changes)

--list (show backups)

--restore <file> --to <dir>

Add after config load (example snippet):

DRY_RUN=false; LIST_MODE=false; RESTORE_MODE=false

# simple parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --list) LIST_MODE=true; shift ;;
    --restore) RESTORE_MODE=true; BACKUP_FILE="$2"; shift 2 ;;
    --to) RESTORE_TO="$2"; shift 2 ;;
    *) SOURCE_DIR="$1"; shift ;;
  esac
done

5) Validate input and pre-checks

Add checks:

Source dir exists and is readable

Destination exists (create it)

Disk space check (optional, simple)

Snippet:

if [ "${LIST_MODE:-false}" = true ]; then
  ls -lh "$BACKUP_DESTINATION"/backup-*.tar.gz 2>/dev/null || echo "No backups"
  exit 0
fi

if [ "${RESTORE_MODE:-false}" = true ]; then
  # restore flow (validate file and extract)
  mkdir -p "$RESTORE_TO"
  tar -xzf "$BACKUP_DESTINATION/$BACKUP_FILE" -C "$RESTORE_TO"
  log "SUCCESS: restored $BACKUP_FILE -> $RESTORE_TO"
  exit 0
fi

if [ -z "${SOURCE_DIR:-}" ]; then
  echo "Usage: $0 [--dry-run] <source_dir>  or --list or --restore <file> --to <dir>"
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  log "ERROR: Source folder not found: $SOURCE_DIR"; exit 1
fi

if [ ! -r "$SOURCE_DIR" ]; then
  log "ERROR: Cannot read source folder: permission denied"; exit 1
fi

6) Build exclude args from EXCLUDE_PATTERNS

Add:

IFS=',' read -ra EXCLUDES <<< "$EXCLUDE_PATTERNS"
EXCLUDE_ARGS=()
for e in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(--exclude="$e")
done


These are passed to tar.

7) Create the backup (tar + timestamp)

Use timestamp format backup-YYYY-MM-DD-HHMM.tar.gz. Example code:

TIMESTAMP=$(date +%Y-%m-%d-%H%M)
BACKUP_NAME="backup-$TIMESTAMP.tar.gz"
BACKUP_PATH="$BACKUP_DESTINATION/$BACKUP_NAME"

if [ "$DRY_RUN" = true ]; then
  log "DRY RUN: Would create: tar -czf $BACKUP_PATH ${EXCLUDE_ARGS[*]} $SOURCE_DIR"
else
  log "INFO: Creating backup $BACKUP_NAME"
  tar -czf "$BACKUP_PATH" "${EXCLUDE_ARGS[@]}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
  log "SUCCESS: Created $BACKUP_PATH"
fi


Notes: -C used so tar entries are cleaner (no leading /home/...).

8) Create and verify checksum (sha256)

After creation:

CHECKSUM_FILE="$BACKUP_PATH.sha256"

if [ "$DRY_RUN" = true ]; then
  log "DRY RUN: Would create checksum $CHECKSUM_FILE"
else
  sha256sum "$BACKUP_PATH" > "$CHECKSUM_FILE"
  log "INFO: Created checksum file $CHECKSUM_FILE"
  # verify
  if sha256sum -c "$CHECKSUM_FILE" >/dev/null 2>&1; then
    log "SUCCESS: Checksum verified"
  else
    log "ERROR: Checksum verification failed"
  fi
fi

9) Test extract — verify real archive integrity

Extract a single small file (or list) to a temp dir and check success:

if [ "$DRY_RUN" = false ]; then
  TMPDIR=$(mktemp -d)
  if tar -tzf "$BACKUP_PATH" >/dev/null 2>&1; then
    # optionally extract small file to test:
    tar -xzf "$BACKUP_PATH" -C "$TMPDIR" --wildcards --no-anchored "$(basename "$SOURCE_DIR")" 2>/dev/null || true
    log "INFO: Archive list OK"
  else
    log "ERROR: Archive appears corrupted"
  fi
  rm -rf "$TMPDIR"
fi


If both checksum and test extract pass → print SUCCESS.

10) Retention / Rotation (daily, weekly, monthly)

This is the trickiest piece. Approach:

Store backups with timestamped names (we already do).

For rotation, select candidate backups for each period:

Daily: choose last backup per day (keep DAILY_KEEP days)

Weekly: choose one backup per week for last WEEKLY_KEEP weeks (use date +%Y-%V week number)

Monthly: choose one per month for last MONTHLY_KEEP months (use date +%Y-%m)

Implementation approach (simpler algorithm):

Build lists keyed by day/week/month and pick newest in each group; mark those to KEEP.

Any backup not in KEEP set → delete.

Example pseudo-code (bash-ish):

cd "$BACKUP_DESTINATION"
mapfile -t all_backups < <(ls -1 backup-*.tar.gz 2>/dev/null | sort)

declare -A keep_map

# pick daily
for f in "${all_backups[@]}"; do
  ts=${f#backup-}; ts=${ts%.tar.gz}  # e.g., 2024-11-03-1430
  day=$(date -d "${ts:0:10}" +%F)
  if [ -z "${keep_map["daily_$day"]+x}" ]; then
    keep_map["daily_$day"]="$f"
  fi
done
# keep last DAILY_KEEP days
# (collect last DAILY_KEEP daily entries by sorting days descending)
# repeat method for weekly and monthly (use date -d "$ts" +%Y-%V and +%Y-%m)
# After computing keep_set, delete files not in keep_set (and their .sha256)


If that seems complex, implement a simpler heuristic first: keep last N backups overall (for passing tests), then iterate to exact daily/weekly/monthly logic.

11) Dry-run mode behavior

When DRY_RUN=true, do not create files or delete. Replace operations with logs prefixed DRY RUN:. We added checks in create/delete steps. Ensure rotation also honors DRY_RUN.

12) Prevent multiple runs (lock file)

We already used /tmp/backup.lock and trap to remove on exit. Make sure to clean up partial files if the script is interrupted (trap 'cleanup' EXIT).

Example cleanup():

cleanup() {
  rm -f "$LOCK_FILE"
  # optionally remove partial backup (if incomplete)
}
trap cleanup EXIT

13) Logging format

We set LOG_FILE in config. Use log() function to append lines. Example log lines:

[2024-11-03 14:30:15] INFO: Starting backup of /home/user/documents
[2024-11-03 14:30:45] SUCCESS: Backup created: backup-2024-11-03-1430.tar.gz

14) Bonus: Implement --list and --restore

We added --list earlier. For restore:

# ./backup.sh --restore backup-2024-11-03-1430.tar.gz --to /tmp/restore
tar -xzf "$BACKUP_DESTINATION/$BACKUP_FILE" -C "$RESTORE_TO"


Always validate target path and existence.

15) Testing the script (step-by-step)

Create a test source folder:

mkdir -p ~/test_backup/src
echo "hello world" > ~/test_backup/src/file1.txt
mkdir -p ~/test_backup/src/.git
echo "ignore" > ~/test_backup/src/.git/ignore


Dry run:

./backup.sh --dry-run ~/test_backup/src
# Confirm messages: "Would create..." and nothing in $BACKUP_DESTINATION


Create real backup:

./backup.sh ~/test_backup/src
ls -lh ~/backups


Verify log:

tail -n 50 ~/backups/backup.log


Create multiple backups (simulate different timestamps):
You can fake timestamps by temporarily overriding date substitution in the script for tests, or create backups while changing system clock (not recommended). Simpler: copy existing backups and rename their filenames to simulate older dates:

cp ~/backups/backup-2025-11-03-1200.tar.gz ~/backups/backup-2025-11-02-1200.tar.gz
cp ~/backups/backup-2025-11-03-1200.tar.gz ~/backups/backup-2025-10-27-1200.tar.gz
# Then run rotation to see deletion behavior


Test restore:

./backup.sh --restore backup-2025-11-03-1200.tar.gz --to ~/restored
ls -R ~/restored


Test error cases:

Non-existent source:

./backup.sh /nonexistent/path
# Expect "ERROR: Source folder not found"


Permission denied: create folder with no read perms and attempt backup.

16) Cron / Automation

To run daily at 02:00 AM, edit crontab:

crontab -e
# Add:
0 2 * * * /home/youruser/backup-system/backup.sh /home/youruser/my_documents >> /home/youruser/backups/cron-run.log 2>&1


Ensure full paths are used inside the script (or source the config that uses absolute paths).
