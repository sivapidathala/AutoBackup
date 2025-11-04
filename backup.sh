#!/bin/bash
# ==================================================
# SMART BACKUP SYSTEM - ADVANCED VERSION
# ==================================================
CONFIG_FILE="./backup.config"
LOG_FILE="./backup.log"
LOCK_FILE="/tmp/backup.lock"
EMAIL_FILE="./email.txt"

# -----------------------------
# Utility Functions
# -----------------------------
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $message" | tee -a "$LOG_FILE"
}

send_email() {
    local subject="$1"
    local body="$2"
    echo -e "To: $EMAIL_NOTIFICATION\nSubject: $subject\n\n$body\n" >> "$EMAIL_FILE"
}

cleanup_lock() {
    rm -f "$LOCK_FILE"
}
trap cleanup_lock EXIT

# -----------------------------
#Load Config
# -----------------------------
if [ ! -f "$CONFIG_FILE" ]; then
    log "ERROR" "Config file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"
BACKUP_DESTINATION="${BACKUP_DESTINATION:-$HOME/Backups}"
EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-.git,node_modules,.cache}"
DAILY_KEEP="${DAILY_KEEP:-7}"
WEEKLY_KEEP="${WEEKLY_KEEP:-4}"
MONTHLY_KEEP="${MONTHLY_KEEP:-3}"

mkdir -p "$BACKUP_DESTINATION"

# -----------------------------
# Prevent multiple runs
# -----------------------------
if [ -f "$LOCK_FILE" ]; then
    log "ERROR" "Another backup process is already running."
    exit 1
fi
touch "$LOCK_FILE"

# -----------------------------
# Helper: Disk Space Check
# -----------------------------
check_space() {
    local required=100
    local available
    available=$(df --output=avail -k "$BACKUP_DESTINATION" | tail -1)
    if (( available < required * 1024 )); then
        log "ERROR" "Not enough disk space!"
        send_email "Backup FAILED" "Error: Not enough disk space at $BACKUP_DESTINATION"
        exit 1
    fi
}

# -----------------------------
# List Backups
# -----------------------------
if [ "$1" == "--list" ]; then
    log "INFO" "Listing all backups:"
    echo "Available backups in $BACKUP_DESTINATION:"
    echo "----------------------------------------"
    ls -lh "$BACKUP_DESTINATION"/backup-*.tar.gz 2>/dev/null || echo "No backups found."
    exit 0
fi

# -----------------------------
# Restore Mode
# -----------------------------
if [ "$1" == "--restore" ]; then
    BACKUP_FILE="$2"
    shift 2
    if [ "$1" == "--to" ]; then
        RESTORE_PATH="$2"
    else
        log "ERROR" "Usage: $0 --restore <backup-file> --to <destination-folder>"
        exit 1
    fi

    if [ ! -f "$BACKUP_DESTINATION/$BACKUP_FILE" ]; then
        log "ERROR" "Backup file not found: $BACKUP_DESTINATION/$BACKUP_FILE"
        exit 1
    fi

    mkdir -p "$RESTORE_PATH"
    log "INFO" "Restoring $BACKUP_FILE to $RESTORE_PATH..."
    tar -xzf "$BACKUP_DESTINATION/$BACKUP_FILE" -C "$RESTORE_PATH"

    if [ $? -eq 0 ]; then
        log "SUCCESS" "Restore completed successfully."
        send_email "Backup RESTORE SUCCESS" "Restored $BACKUP_FILE to $RESTORE_PATH successfully."
    else
        log "ERROR" "Restore failed."
        send_email "Backup RESTORE FAILED" "Failed to restore $BACKUP_FILE."
    fi
    exit 0
fi

# -----------------------------
# Dry-run
# -----------------------------
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    shift
    log "INFO" "Running in dry-run mode."
fi

# -----------------------------
# Validate Input
# -----------------------------
SOURCE_DIR="$1"
if [ -z "$SOURCE_DIR" ]; then
    log "ERROR" "Usage: $0 [--dry-run] /path/to/source_folder"
    exit 1
fi
if [ ! -d "$SOURCE_DIR" ]; then
    log "ERROR" "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# -----------------------------
# Create Backup
# -----------------------------
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")
BACKUP_NAME="backup-${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DESTINATION}/${BACKUP_NAME}"
CHECKSUM_PATH="${BACKUP_PATH}.sha256"

log "INFO" "Starting backup of ${SOURCE_DIR}"

IFS=',' read -r -a EXCLUDE_ARRAY <<< "$EXCLUDE_PATTERNS"
EXCLUDE_ARGS=()
for pattern in "${EXCLUDE_ARRAY[@]}"; do
    EXCLUDE_ARGS+=("--exclude=$pattern")
done

check_space

if [ "$DRY_RUN" = true ]; then
    log "INFO" "Would create backup: $BACKUP_PATH"
else
    tar -czf "$BACKUP_PATH" "${EXCLUDE_ARGS[@]}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
    if [ $? -ne 0 ]; then
        log "ERROR" "Backup creation failed."
        send_email "Backup FAILED" "Error creating backup for $SOURCE_DIR"
        exit 1
    fi
    log "SUCCESS" "Backup created: $BACKUP_PATH"
fi

# -----------------------------
# Checksum & Verification
# -----------------------------
if [ "$DRY_RUN" = false ]; then
    sha256sum "$BACKUP_PATH" > "$CHECKSUM_PATH"
    sha256sum -c "$CHECKSUM_PATH" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        tar -tzf "$BACKUP_PATH" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            log "SUCCESS" "Backup verified successfully."
            send_email "Backup SUCCESS" "Backup $BACKUP_NAME verified successfully."
        else
            log "FAILED" "Backup corrupted during compression!"
            send_email "Backup FAILED" "Archive test failed for $BACKUP_NAME"
        fi
    else
        log "FAILED" "Checksum mismatch for $BACKUP_NAME"
        send_email "Backup FAILED" "Checksum mismatch for $BACKUP_NAME"
    fi
fi

# -----------------------------
#  Retention Cleanup (Simplified)
# -----------------------------
log "INFO" "Applying retention policy (keep last $DAILY_KEEP backups)..."
mapfile -t ALL_BACKUPS < <(ls -t "$BACKUP_DESTINATION"/backup-*.tar.gz 2>/dev/null)
COUNTER=0
for file in "${ALL_BACKUPS[@]}"; do
    ((COUNTER++))
    if (( COUNTER > DAILY_KEEP )); then
        rm -f "$file" "${file}.sha256"
        log "INFO" "Deleted old backup: $file"
    fi
done

log "SUCCESS" "Backup process complete."
