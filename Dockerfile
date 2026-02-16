FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    fuse \
    ca-certificates \
    unzip \
    gnupg \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install Emby
RUN wget https://repo.emby.media/emby-server-deb_4.8.0.80_amd64.deb -O emby.deb \
    && apt-get update \
    && apt-get install -y ./emby.deb \
    && rm emby.deb

RUN mkdir -p /data /config

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8096
CMD ["/start.sh"]
