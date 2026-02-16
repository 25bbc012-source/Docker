#!/bin/bash

# Start rclone mount
rclone mount gdrive: /data \
  --allow-other \
  --vfs-cache-mode writes \
  --vfs-cache-max-size 10G \
  --vfs-read-chunk-size 128M &

# Start emby
emby-server
