FROM emby/embyserver:latest
USER root
# Use wget (often present) or download binary
RUN wget -qO- https://downloads.rclone.org/rclone-current-linux-amd64.zip | funzip | tar x -C /usr/bin/ rclone-*-linux-amd64/rclone --strip=1 --wildcards '*' && \
    chmod +x /usr/bin/rclone && \
    echo '#!/bin/sh
rclone mount gdrive: /media \
  --allow-other \
  --vfs-cache-mode writes \
  --vfs-cache-max-size 10G \
  --vfs-read-chunk-size 128M \
  --daemon &
dotnet EmbyServer.dll' > /start.sh && \
    chmod +x /start.sh
USER abc
CMD ["/start.sh"]
