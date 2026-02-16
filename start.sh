#!/bin/sh
set -e

echo "=== Emby + rclone Startup Script ==="

# --- 1. Build rclone config from environment variables ---
RCLONE_CONFIG_DIR="/root/.config/rclone"
RCLONE_CONFIG_FILE="${RCLONE_CONFIG_DIR}/rclone.conf"

if [ -z "$GDRIVE_TOKEN" ]; then
    echo "ERROR: GDRIVE_TOKEN environment variable is not set!"
    exit 1
fi

mkdir -p "$RCLONE_CONFIG_DIR"

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
export RCLONE_CONFIG="$RCLONE_CONFIG_FILE"

# --- 2. Mount Google Drive via rclone ---
MOUNT_POINT="/mnt/gdrive"
mkdir -p "$MOUNT_POINT"

# Check if FUSE is available
if [ ! -e /dev/fuse ]; then
    echo "WARNING: /dev/fuse not found. Creating device node..."
    mknod /dev/fuse c 10 229 2>/dev/null || true
fi

echo "Mounting rclone remote 'gdrive:' at ${MOUNT_POINT} ..."

# Run rclone mount in background (not --daemon, which has issues on some platforms)
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
    --config "$RCLONE_CONFIG_FILE" &

RCLONE_PID=$!
echo "rclone mount started with PID $RCLONE_PID"

# Wait a moment for the mount to initialize
sleep 5

# Check if rclone is still running
if kill -0 $RCLONE_PID 2>/dev/null; then
    echo "rclone mount is running"
else
    echo "ERROR: rclone mount failed to start!"
    echo "This may be because FUSE is not available on this platform."
    echo "Checking rclone listremotes as fallback test..."
    rclone listremotes --config "$RCLONE_CONFIG_FILE"
    echo "Config is valid. But FUSE mount is not supported on this platform."
    echo "Continuing to start Emby anyway..."
fi

# Check if mount point is accessible
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "rclone mount successful at ${MOUNT_POINT}"
    ls -la "$MOUNT_POINT" || true
else
    echo "Mount point not ready. Listing files via rclone to verify config..."
    rclone lsf "gdrive:" --config "$RCLONE_CONFIG_FILE" --max-depth 1 2>&1 | head -20 || true
fi

# --- 3. Start Emby Server ---
echo "Starting Emby Server on port 8096 ..."
exec /init
