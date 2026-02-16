FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    fuse \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install Emby
RUN curl -L https://github.com/MediaBrowser/Emby.Releases/releases/latest/download/emby-server-deb_4.8.0.80_amd64.deb -o emby.deb \
    && apt-get update \
    && apt-get install -y ./emby.deb \
    && rm emby.deb

RUN mkdir -p /data /config

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8096
CMD ["/start.sh"]
