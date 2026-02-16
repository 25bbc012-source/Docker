# Use official Emby server as base image
FROM emby/embyserver:latest

# Install rclone and required dependencies (Alpine uses apk)
RUN apk add --no-cache \
    bash \
    curl \
    unzip \
    fuse3 \
    ca-certificates \
    && curl -O https://downloads.rclone.org/current/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip \
    && cp rclone-*-linux-amd64/rclone /usr/bin/ \
    && chmod +x /usr/bin/rclone \
    && rm -rf rclone-* \
    && apk del unzip

# Allow non-root FUSE mounts
RUN sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf 2>/dev/null || \
    echo "user_allow_other" >> /etc/fuse.conf

# Create mount point for Google Drive
RUN mkdir -p /mnt/gdrive

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose Emby default port
EXPOSE 8096

# Start via the startup script
CMD ["/start.sh"]
