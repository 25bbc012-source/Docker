FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    fuse \
    ca-certificates \
    unzip \
    gnupg \
    wget \
    apt-transport-https \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install Emby via official repo
RUN wget -qO - https://repo.emby.media/emby.asc | gpg --dearmor -o /usr/share/keyrings/emby.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/emby.gpg] https://repo.emby.media/ubuntu jammy main" > /etc/apt/sources.list.d/emby.list \
    && apt-get update \
    && apt-get install -y emby-server

RUN mkdir -p /data /config

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8096
CMD ["/start.sh"]
