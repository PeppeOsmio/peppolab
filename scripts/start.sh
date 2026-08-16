#!/usr/bin/env bash
#
# Starts every stack's docker compose project in this repo, in order.
#
# Order: tailscale, traefik, pihole, portainer, dozzle, tig_stack, backrest,
# then everything else, in the order listed in ORDER below. Note that traefik
# creates the external traefik_global network that pihole, portainer, dozzle,
# tig_stack, and backrest all join, so it must stay ahead of those.
#
# Any stack directory found in the repo but not listed in ORDER is started
# last, after a warning, so new stacks are never silently skipped.
#
# Usage: ./scripts/start.sh [--dry-run]

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

ORDER=(
  tailscale
  traefik
  pihole
  portainer
  dozzle
  tig_stack
  backrest
  wireguard
  nextcloud
  immich
  navidrome
  ghostfolio
  gitlab
  vaultwarden
  sftp
  lockate
)

compose_file_for() {
  local stack="$1"
  for ext in yml yaml; do
    local candidate="$REPO_ROOT/$stack/docker-compose.$ext"
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

FAILED=()
STARTED=()

start_stack() {
  local stack="$1"
  local compose_file
  if ! compose_file="$(compose_file_for "$stack")"; then
    echo "==> $stack: no docker-compose.yml/.yaml found, skipping"
    return
  fi

  echo "==> $stack"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  + docker compose -p $stack -f $compose_file up -d"
    return
  fi

  if docker compose -p "$stack" -f "$compose_file" up -d; then
    STARTED+=("$stack")
  else
    FAILED+=("$stack")
  fi
}

for stack in "${ORDER[@]}"; do
  start_stack "$stack"
done

shopt -s nullglob
for compose_file in "$REPO_ROOT"/*/docker-compose.yml "$REPO_ROOT"/*/docker-compose.yaml; do
  stack="$(basename "$(dirname "$compose_file")")"
  if [[ ! " ${ORDER[*]} " == *" $stack "* ]]; then
    echo "Warning: $stack has a docker-compose file but isn't listed in ORDER, starting it last." >&2
    start_stack "$stack"
  fi
done

echo
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete."
  exit 0
fi

echo "Started: ${STARTED[*]:-none}"
if [[ "${#FAILED[@]}" -gt 0 ]]; then
  echo "Failed: ${FAILED[*]}" >&2
  exit 1
fi
