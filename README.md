# HomeVault Backup Docker Image

![Build](https://img.shields.io/github/actions/workflow/status/thedebuggedlife/homevault-backup/build_backup_image.yml?logo=githubactions&logoColor=%232088FF)
![Version](https://img.shields.io/github/v/tag/thedebuggedlife/homevault-backup?sort=semver&logo=docker&logoColor=%232496ED&label=image)

A Docker container that performs regular backups using restic with support for LVM snapshots and Docker Compose integration.

This container is used by the [HomeVault](https://thedebugged.life/homevault/introduction/) project to perform scheduled background backups of all the files installed on the server.


## Features

- Scheduled backups using cron
- LVM snapshot support for consistent backups
- Docker Compose integration for stopping/starting services
- Flexible retention policies
- Pre/post backup hooks

## Usage

```yaml
version: '3'

volumes:
  restic-cache:

secrets:
  restic_password:
    file: ${APPDATA_LOCATION}/secrets/restic_password

services:
  backup:
    image: ghcr.io/thedebuggedlife/homevault-backup:latest
    volumes:
      # Required for LVM access
      - /dev:/dev:rw
      - /run:/run:rw
      - /etc/lvm:/etc/lvm:ro
      # For Docker container operations
      - /var/run/docker.sock:/var/run/docker.sock
      # Custom hooks and config
      - /srv/appdata/backup/config:/config:ro
      - /srv/appdata/backup/hooks:/hooks:ro
      # Cache volume for better restic performance
      - restic-cache:/root/.cache/restic
      # Backup locations
      - /srv/appdata:/data/srv/appdata:ro
    # You can send repository variables using an .env file
    env_file: /srv/appdata/backup/restic.env
    environment:
      - TZ
      - CRON_SCHEDULE=0 2 * * *
      # Remove the password from the environment in case it is set in restic.env
      - RESTIC_PASSWORD=
      # Use the docker secret instead
      - RESTIC_PASSWORD_FILE=/run/secrets/restic_password
      - BACKUP_PATHS=/data
      - RESTIC_OPTS=--verbose --tag homevault
      - ENABLE_FORGET=${ENABLE_FORGET:-true}
      # Format: [#h][#d][#w][#m][#y]
      # Default: Keep 7 daily, 4 weekly, 6 monthly, 1 yearly
      - RETENTION_POLICY=${RETENTION_POLICY:-7d4w6m1y}
      # LVM Snapshot configuration
      - USE_LVM_SNAPSHOT=false              # Set to true to enable LVM snapshots
      - LVM_VOLUME_GROUP=vg0                # Your volume group name
      - LVM_LOGICAL_VOLUME=data             # Your logical volume name
      - LVM_SNAPSHOT_SIZE=2G                # Size of the snapshot
      - LVM_SNAPSHOT_NAME=restic_snapshot   # Name for the snapshot
      - LVM_MOUNT_PATH=/mnt/snapshot        # Where to mount the snapshot
      - REPLACE_BACKUP_PATH=true            # Replace backup path with snapshot path
      # Enable Docker operations
      - USE_DOCKER=true
      # Project and services to stop/start as part of the backup operation
      - DOCKER_COMPOSE_PROJECT=${DOCKER_COMPOSE_PROJECT}
      - DOCKER_COMPOSE_SERVICES=${DOCKER_COMPOSE_SERVICES}
```

## References

- [Deployment](https://github.com/thedebuggedlife/homevault-deployment): Repository with the scripts used to deploy HomeVault on a server
- [Documentation](https://thedebugged.life/homevault/introduction/): In-depth documentation for the HomeVault project# Homevault Backup