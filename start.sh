#!/bin/bash
set -e

echo "=== Emby + rclone Startup Script ==="

# --- 1. Write rclone config from environment variable ---
RCLONE_CONFIG_DIR="/root/.config/rclone"
RCLONE_CONFIG_FILE="${RCLONE_CONFIG_DIR}/rclone.conf"

if [ -z "$RCLONE_CONFIG" ]; then
    echo "ERROR: RCLONE_CONFIG environment variable is not set!"
    echo "Set it to the base64-encoded contents of your rclone.conf file."
    exit 1
fi

mkdir -p "$RCLONE_CONFIG_DIR"

# Decode the base64-encoded rclone config
echo "$RCLONE_CONFIG" | base64 -d > "$RCLONE_CONFIG_FILE"
echo "rclone config written to $RCLONE_CONFIG_FILE"

# --- 2. Mount Google Drive via rclone ---
MOUNT_POINT="/mnt/gdrive"
REMOTE_NAME="gdrive"   # Must match the remote name in your rclone.conf

mkdir -p "$MOUNT_POINT"

echo "Mounting rclone remote '${REMOTE_NAME}:' at ${MOUNT_POINT} ..."

rclone mount "${REMOTE_NAME}:" "$MOUNT_POINT" \
    --allow-other \
    --allow-non-empty \
    --vfs-cache-mode full \
    --vfs-cache-max-size 2G \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 256M \
    --buffer-size 64M \
    --dir-cache-time 72h \
    --poll-interval 15s \
    --log-level INFO \
    --log-file /var/log/rclone.log \
    --daemon

# Wait for the mount to become available
echo "Waiting for rclone mount..."
RETRIES=0
MAX_RETRIES=30
while ! mountpoint -q "$MOUNT_POINT" && [ $RETRIES -lt $MAX_RETRIES ]; do
    sleep 1
    RETRIES=$((RETRIES + 1))
done

if mountpoint -q "$MOUNT_POINT"; then
    echo "rclone mount successful at ${MOUNT_POINT}"
else
    echo "WARNING: rclone mount may not be ready yet. Proceeding anyway..."
fi

# --- 3. Start Emby Server ---
echo "Starting Emby Server on port 8096 ..."

# The official emby/embyserver image uses this entrypoint
exec /init
