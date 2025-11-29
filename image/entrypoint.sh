#!/bin/bash
set -e

# Function to log messages with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Initializing container"

# Create hooks directory if it doesn't exist
mkdir -p /hooks

# Set up cron job based on CRON_SCHEDULE
if [ "${CRON_SCHEDULE}" = "disabled" ]; then
    log "CRON_SCHEDULE is disabled."
    if [ "${RUN_ON_STARTUP:-false}" = "true" ]; then
        log "RUN_ON_STARTUP is true, running backup once."
        /backup-scripts/backup.sh
        BACKUP_EXIT_CODE=$?
        log "Backup finished. Exiting with code ${BACKUP_EXIT_CODE}."
        exit ${BACKUP_EXIT_CODE}
    else
        log "Error: CRON_SCHEDULE is disabled and RUN_ON_STARTUP is not true. Nothing to do."
        exit 1
    fi
fi

if [ -n "$CRON_SCHEDULE" ]; then
    log "Setting up cron schedule: $CRON_SCHEDULE"
    echo "$CRON_SCHEDULE /backup-scripts/backup.sh" > /etc/crontabs/root
else
    log "Using default cron schedule: 0 2 * * * (2 AM daily)"
    echo "0 2 * * * /backup-scripts/backup.sh" > /etc/crontabs/root
fi

# Run backup immediately if requested
if [ "${RUN_ON_STARTUP:-false}" = "true" ]; then
    log "RUN_ON_STARTUP is enabled, running backup now"
    /backup-scripts/backup.sh
fi

# Start cron daemon in foreground
log "Starting crond in foreground"
exec crond -f -l 5