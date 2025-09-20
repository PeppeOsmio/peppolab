#!/bin/bash

if [ -z "$1" ]; then
    echo "Provide compose name as first argument"
    exit 1
fi

COMPOSE_NAME="$1"

set -x

btrfs subvolume delete /docker_snapshots/${COMPOSE_NAME}
