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

# --- 2. Start rclone HTTP server (serves Google Drive files locally) ---
RCLONE_PORT=9090
STRM_DIR="/media/gdrive"

echo "Starting rclone HTTP server on port ${RCLONE_PORT} ..."

rclone serve http "gdrive:" \
    --addr "127.0.0.1:${RCLONE_PORT}" \
    --read-only \
    --buffer-size 64M \
    --vfs-cache-mode full \
    --vfs-cache-max-size 2G \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 256M \
    --dir-cache-time 72h \
    --poll-interval 15s \
    --log-level INFO \
    --config "$RCLONE_CONFIG_FILE" &

RCLONE_PID=$!
echo "rclone HTTP server started with PID $RCLONE_PID"

# Wait for rclone HTTP server to be ready
echo "Waiting for rclone HTTP server..."
RETRIES=0
MAX_RETRIES=30
while ! wget -q -O /dev/null "http://127.0.0.1:${RCLONE_PORT}/" 2>/dev/null; do
    sleep 1
    RETRIES=$((RETRIES + 1))
    if [ $RETRIES -ge $MAX_RETRIES ]; then
        echo "WARNING: rclone HTTP server may not be ready yet."
        break
    fi
done

if kill -0 $RCLONE_PID 2>/dev/null; then
    echo "rclone HTTP server is running"
else
    echo "ERROR: rclone HTTP server failed to start!"
    exit 1
fi

# --- 3. Generate .strm files from Google Drive listing ---
echo "Generating .strm files in ${STRM_DIR} ..."
mkdir -p "$STRM_DIR"



# Use rclone lsf for simpler, more reliable file listing
generate_strm_simple() {
    echo "Scanning Google Drive for media files..."

    # List all files recursively
    rclone lsf "gdrive:" --recursive --config "$RCLONE_CONFIG_FILE" 2>/dev/null | while IFS= read -r filepath; do
        # Check if it ends with / (directory)
        case "$filepath" in
            */) continue ;;
        esac

        # Check if it's a media file
        ext=$(echo "$filepath" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')
        case "$ext" in
            mkv|mp4|avi|mov|wmv|flv|webm|m4v|mpg|mpeg|ts|m2ts|3gp|ogv|mp3|flac|aac|ogg|wma|wav|m4a|opus)
                # Get directory part and create it
                dir_part=$(dirname "$filepath")
                if [ "$dir_part" != "." ]; then
                    mkdir -p "${STRM_DIR}/${dir_part}"
                fi

                # Create .strm file
                strm_name=$(echo "$filepath" | sed 's/\.[^.]*$//')
                encoded_path=$(echo "$filepath" | sed 's/ /%20/g; s/\[/%5B/g; s/\]/%5D/g')
                echo "http://127.0.0.1:${RCLONE_PORT}/${encoded_path}" > "${STRM_DIR}/${strm_name}.strm"
                echo "  STRM: ${strm_name}.strm"
                ;;
        esac
    done

    echo "STRM file generation complete!"
    echo "Total .strm files: $(find "$STRM_DIR" -name '*.strm' 2>/dev/null | wc -l)"
}

# Loop to generate .strm files every 10 minutes
(
    while true; do
        generate_strm_simple
        echo "Waiting 10 minutes before next scan..."
        sleep 600
    done
) &

# --- 4. Keep-alive ping (prevents Render free tier from sleeping) ---
PING_URL="https://docker-p5is.onrender.com"
PING_INTERVAL=300  # every 5 minutes

echo "Starting keep-alive pinger for ${PING_URL} every ${PING_INTERVAL}s ..."
(
    while true; do
        sleep "$PING_INTERVAL"
        wget -q -O /dev/null "$PING_URL" 2>/dev/null && echo "[keep-alive] pinged $PING_URL" || echo "[keep-alive] ping failed"
    done
) &

# --- 5. Start Emby Server ---
echo "Starting Emby Server on port 8096 ..."
echo "Media STRM files are in: ${STRM_DIR}"
echo "Add ${STRM_DIR} as your media library folder in Emby setup."
exec /init
