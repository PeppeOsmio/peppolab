#!/bin/bash

set -e

if [ -z "${1:-}" ]; then
    echo "Provide compose name as first argument"
    exit 1
fi

STOP="false"
if [ "${2:-}" == "--stop" ]; then
    STOP="true"
fi

COMPOSE_NAME="${1}"

SOURCE="/docker_data/${COMPOSE_NAME}"
SNAPSHOT_PATH="/docker_snapshots/${COMPOSE_NAME}"

set -x

if [ "${STOP}" = true ]; then
    echo "Stopping docker compose stack"
    docker compose -p "${COMPOSE_NAME}" stop
fi

# Delete snapshot only if it exists
if btrfs subvolume show "${SNAPSHOT_PATH}" &>/dev/null; then
    echo "Deleting old snapshot ${SNAPSHOT_PATH}..."
    btrfs subvolume delete "$SNAPSHOT_PATH"
    echo "Delete old snapshot ${SNAPSHOT_PATH}"
fi

# Create snapshot with custom name
echo "Creating snapshot ${SNAPSHOT_PATH}..."
btrfs subvolume snapshot "${SOURCE}" "${SNAPSHOT_PATH}"
echo "Created snapshot ${SNAPSHOT_PATH}"

if [ "$STOP" = true ]; then
    echo "Starting docker compose stack"
    docker compose -p "${COMPOSE_NAME}" start
fi
