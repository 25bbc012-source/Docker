#!/bin/sh
set -e

echo "=== Emby + rclone Startup Script ==="

# --- 1. Build rclone config from environment variables ---
RCLONE_CONFIG_DIR="/root/.config/rclone"
RCLONE_CONFIG_FILE="${RCLONE_CONFIG_DIR}/rclone.conf"

if [ -z "$GDRIVE_TOKEN" ]; then
    echo "ERROR: GDRIVE_TOKEN environment variable is not set!"
    echo "Set it to the token JSON from your rclone config."
    exit 1
fi

mkdir -p "$RCLONE_CONFIG_DIR"

# Build rclone.conf from individual environment variables
cat > "$RCLONE_CONFIG_FILE" << EOF
[gdrive]
type = drive
client_id = ${GDRIVE_CLIENT_ID}
client_secret = ${GDRIVE_CLIENT_SECRET}
scope = drive
token = ${GDRIVE_TOKEN}
team_drive = 
EOF

echo "rclone config written to $RCLONE_CONFIG_FILE"

# Tell rclone where to find its config file
export RCLONE_CONFIG="$RCLONE_CONFIG_FILE"

# --- 2. Mount Google Drive via rclone ---
MOUNT_POINT="/mnt/gdrive"

mkdir -p "$MOUNT_POINT"

echo "Mounting rclone remote 'gdrive:' at ${MOUNT_POINT} ..."

rclone mount "gdrive:" "$MOUNT_POINT" \
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
