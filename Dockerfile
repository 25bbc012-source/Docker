# ---- Stage 1: Builder - download rclone and fuse3 from Debian ----
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    fuse3 \
    ca-certificates \
    && curl -O https://downloads.rclone.org/current/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip \
    && cp rclone-*-linux-amd64/rclone /usr/bin/rclone \
    && chmod +x /usr/bin/rclone \
    && rm -rf rclone-*

# ---- Stage 2: Final image ----
FROM emby/embyserver:latest

# Copy rclone binary from builder
COPY --from=builder /usr/bin/rclone /usr/bin/rclone

# Copy fuse3 binaries and libraries from builder
COPY --from=builder /usr/bin/fusermount3 /usr/bin/fusermount3
COPY --from=builder /usr/lib/x86_64-linux-gnu/libfuse3.so* /usr/lib/
RUN ln -sf /usr/bin/fusermount3 /usr/bin/fusermount

# Allow non-root FUSE mounts
RUN echo "user_allow_other" >> /etc/fuse.conf

# Create mount point for Google Drive
RUN mkdir -p /mnt/gdrive

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose Emby default port
EXPOSE 8096

# Start via the startup script
CMD ["/start.sh"]
