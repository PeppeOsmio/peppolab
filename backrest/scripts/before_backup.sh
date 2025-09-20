#!/bin/bash

if [ -z "$1" ]; then
    echo "Provide compose name as first argument"
    exit 1
fi

if [ "$2" == "--stop" ]; then
    STOP=true
else
    STOP=false
fi

COMPOSE_NAME="$1"

set -x

if [ "$STOP" = true ]; then
    docker compose -p "${COMPOSE_NAME}" stop
fi

btrfs subvolume delete /docker_snapshots/${COMPOSE_NAME}
btrfs subvolume snapshot /docker_data/${COMPOSE_NAME} /docker_snapshots/

if [ "$STOP" = true ]; then
    docker compose -p "${COMPOSE_NAME}" start
fi

