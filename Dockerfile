version: '3.8'
services:
  rclone:
    image: rclone/rclone:latest
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    devices:
      - /dev/fuse
    volumes:
      - media:/data:shared
    command: >
      mount gdrive: /data
      --allow-other
      --vfs-cache-mode writes
      --vfs-cache-max-size 10G
      --vfs-read-chunk-size 128M
      --daemon
    restart: unless-stopped

  emby:
    image: emby/embyserver:latest
    user: 1000:1000
    ports:
      - 8096:8096
    volumes:
      - config:/config
      - media:/data:ro
    depends_on:
      - rclone
    restart: unless-stopped

volumes:
  config:
  media:
