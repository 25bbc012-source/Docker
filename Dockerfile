FROM emby/embyserver:latest
USER root
RUN apt-get update && apt-get install -y curl && \
    curl https://rclone.org/install.sh | bash && \
    echo '#!/bin/sh\nrclone mount gdrive: /media --allow-other --vfs-cache-mode writes --vfs-cache-max-size 10G --daemon &\ndotnet EmbyServer.dll' > /start.sh && \
    chmod +x /start.sh
USER abc
CMD ["/start.sh"]
