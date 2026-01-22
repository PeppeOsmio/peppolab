#!/bin/bash

set -e

if [ -z "${1:-}" ]; then
    echo "Provide compose name as first argument"
    exit 1
fi

COMPOSE_NAME="${1}"

SNAPSHOT_PATH="/docker_snapshots/${COMPOSE_NAME}"

set -x

# Delete snapshot only if it exists
if btrfs subvolume show "$SNAPSHOT_PATH" &>/dev/null; then
    btrfs subvolume delete "$SNAPSHOT_PATH"
else
    echo "Snapshot $SNAPSHOT_PATH does not exist, nothing to delete"
fi
