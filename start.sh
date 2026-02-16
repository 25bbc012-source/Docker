#!/bin/sh
curl https://rclone.org/install.sh | bash
rclone mount gdrive: /media \
  --allow-other \
  --vfs-cache-mode writes \
  --vfs-cache-max-size 10G \
  --vfs-read-chunk-size 128M \
  --buffer-size 256M \
  --dir-cache-time 72h \
  --timeout 1h \
  --daemon &
dotnet EmbyServer.dll
