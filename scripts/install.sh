#!/usr/bin/env bash
#
# Sets up the /docker_data layout and per-stack .env files for every stack
# in this repo. For each <stack>/ directory that has a docker-compose file:
#   - creates /docker_data/<stack> as a BTRFS subvolume (falls back to a
#     plain directory if /docker_data isn't a BTRFS filesystem)
#   - creates /docker_data/<stack>/configs and /docker_data/<stack>/volumes
#   - if <stack>/docs/.env exists, copies it to
#     /docker_data/<stack>/configs/.env (unless it's already there) and
#     symlinks <stack>/.env -> /docker_data/<stack>/configs/.env
#
# Existing files/directories are never overwritten.
#
# It also fixes ownership for the two stacks that require a specific UID
# before first start (Navidrome and Prometheus).
#
# Usage: sudo ./scripts/install.sh [--dry-run] [--data-root /docker_data]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_ROOT="/docker_data"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --data-root)
      DATA_ROOT="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  + $*"
  else
    "$@"
  fi
}

is_btrfs() {
  local path="$1"
  while [[ ! -d "$path" ]]; do
    path="$(dirname "$path")"
  done
  [[ "$(stat -f -c %T "$path" 2>/dev/null)" == "btrfs" ]]
}

create_data_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    echo "  exists: $path"
    return
  fi
  if command -v btrfs >/dev/null 2>&1 && is_btrfs "$DATA_ROOT"; then
    run btrfs subvolume create "$path"
  else
    run mkdir -p "$path"
  fi
}

if [[ "$DRY_RUN" -eq 0 && "$EUID" -ne 0 ]]; then
  echo "Run this script as root (needed to create subvolumes/directories under $DATA_ROOT)." >&2
  exit 1
fi

run mkdir -p "$DATA_ROOT"

shopt -s nullglob
for compose_file in "$REPO_ROOT"/*/docker-compose.yml "$REPO_ROOT"/*/docker-compose.yaml; do
  service_dir="$(dirname "$compose_file")"
  service="$(basename "$service_dir")"
  data_dir="$DATA_ROOT/$service"

  echo "==> $service"

  create_data_dir "$data_dir"
  run mkdir -p "$data_dir/configs" "$data_dir/volumes"

  docs_env="$service_dir/docs/.env"
  configs_env="$data_dir/configs/.env"
  repo_env_link="$service_dir/.env"

  if [[ -f "$docs_env" ]]; then
    if [[ -f "$configs_env" ]]; then
      echo "  configs/.env already exists, leaving as-is"
    else
      run cp "$docs_env" "$configs_env"
      echo "  created $configs_env from docs/.env"
    fi

    if [[ -L "$repo_env_link" || -e "$repo_env_link" ]]; then
      echo "  $repo_env_link already exists, leaving as-is"
    else
      run ln -s "$configs_env" "$repo_env_link"
      echo "  linked $repo_env_link -> $configs_env"
    fi
  fi
done

echo "==> Fixing volume ownership"

navidrome_dir="$DATA_ROOT/navidrome"
if [[ -d "$navidrome_dir" ]]; then
  run chown -R 1000:1000 "$navidrome_dir"
  echo "  chown 1000:1000 $navidrome_dir"
fi

prometheus_dir="$DATA_ROOT/tig_stack/volumes/prometheus"
if [[ -d "$prometheus_dir" ]]; then
  run chown -R 65534:65534 "$prometheus_dir"
  echo "  chown 65534:65534 $prometheus_dir"
fi

echo
echo "Done. Edit each stack's configs/.env (via the symlinked .env in the repo) before starting the stacks."
