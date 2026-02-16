FROM emby/embyserver:latest
USER root
RUN wget -qO- https://downloads.rclone.org/rclone-current-linux-amd64.zip | funzip | tar x -C /usr/bin/ rclone-*-linux-amd64/rclone --strip=1 --wildcards '*' && \
    chmod +x /usr/bin/rclone && \
    printf '#!/bin/sh\nrclone mount gdrive: /media --allow-other --vfs-cache-mode writes --vfs-cache-max-size 10G --vfs-read-chunk-size 128M --daemon &\ndotnet EmbyServer.dll\n' > /start.sh && \
    chmod +x /start.sh
USER abc
CMD ["/start.sh"]
