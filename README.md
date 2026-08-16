# Peppolab

A personal homelab running fully self-hosted services via Docker Compose, with Traefik as the reverse proxy and automatic TLS via OVH DNS challenge.

---

## Services

### [Traefik](https://traefik.io/)

The single entry point for all HTTP/HTTPS traffic. Handles TLS termination with automatic certificate issuance via Let's Encrypt using the OVH DNS challenge.

| Container | Description |
| --- | --- |
| `traefik` | Reverse proxy routing requests to all backend services. Exposes dedicated ports for services that can't use the standard 443 entrypoint (Portainer, Backrest, Dozzle). Prometheus metrics are exposed on a separate entrypoint. Dynamic configuration is loaded from the [`traefik/dynamic_confs/`](traefik/dynamic_confs/) directory. |

### [Tailscale](https://tailscale.com/)

Subnet router that exposes the whole home network to a Tailscale tailnet, providing secure remote access to the homelab — no router port-forwarding or dynamic DNS required, since Tailscale handles NAT traversal itself.

| Container | Description |
| --- | --- |
| `tailscale` | Runs as a subnet router, advertising the home LAN CIDR (`ADVERTISE_ROUTES`) to the tailnet. Any device signed into the same tailnet can reach home network IPs once the advertised route is approved in the [Tailscale admin console](https://login.tailscale.com/admin/machines). |

### [Pi-hole](https://pi-hole.net/)

Network-wide DNS resolver and ad blocker.

| Container | Description |
| --- | --- |
| `pihole` | DNS server that blocks ads and trackers at the network level by dropping requests to known bad domains. Also acts as the local DNS resolver for the homelab, so internal service names resolve correctly. |

### [Nextcloud](https://nextcloud.com/)

Self-hosted cloud storage, calendar, contacts, and file sync. The stack also bundles an online office suite and a real-time push notification service. Official mobile apps are available for Android and iOS.

| Container | Description |
| --- | --- |
| `nextcloud` | Main Nextcloud application server (Apache). Handles file sync, WebDAV, calendar (CalDAV), and contacts (CardDAV). |
| `nextcloud-cron` | Runs Nextcloud's background jobs (`cron.php`) on a schedule, handling cleanup, notifications, and app-level maintenance tasks. |
| `nextcloud-notify-push` | The [`notify_push`](https://github.com/nextcloud/notify_push) high-performance push server. Delivers real-time file-change notifications to desktop and mobile clients without polling. |
| `collabora-nextcloud` | [Collabora Online](https://www.collaboraoffice.com/) (LibreOffice in the browser) integrated with Nextcloud for editing documents, spreadsheets, and presentations directly in the web UI. |
| `postgres-nextcloud` | PostgreSQL database backing all Nextcloud data and metadata. |
| `valkey-nextcloud` | [Valkey](https://valkey.io) (Redis-compatible) cache used for file locking and session caching, keeping the app responsive under concurrent access. |

### [Immich](https://immich.app/)

High-performance, self-hosted photo and video management — a Google Photos alternative with smart search and facial recognition. Official mobile apps are available for Android and iOS and handle automatic background photo backup.

| Container | Description |
| --- | --- |
| `immich-server` | Main API and web UI server. Handles uploads, browsing, sharing, and all client requests. |
| `immich-machine-learning` | Runs ML inference for smart search (CLIP embeddings), facial recognition, and object detection. Runs separately so it can be scaled or swapped independently. |
| `immich-postgres` | PostgreSQL database with the [pgvecto.rs](https://github.com/tensorchord/pgvecto.rs) extension, used for storing photo metadata and the vector embeddings that power semantic search. |
| `immich-redis` | Valkey/Redis instance used as a job queue and cache between the server and the ML container. |

### [Navidrome](https://www.navidrome.org/)

Self-hosted music streaming server with a companion stack for acquiring, organising, and browsing the music library. Any Subsonic-compatible mobile app works as a client — on Android, [Tempo](https://github.com/CappielloAntonio/tempo) is a good option.

| Container | Description |
| --- | --- |
| `navidrome` | Music streaming server compatible with the Subsonic/Airsonic API. Reads the music library as a read-only volume. |
| `slskd` | Web-based [Soulseek](https://www.slsknet.org) client for discovering and downloading music. Writes directly into the shared music volume so new downloads are immediately visible in Navidrome. |
| `file-browser` | Web file manager for browsing and managing the music directory without needing SSH or SFTP. |
| `beets` | Music library manager and tagger that fetches metadata from MusicBrainz, renames files consistently, and keeps the collection well-organised. Runs as a persistent container invoked manually via `docker exec`. |

### [Ghostfolio](https://ghostfol.io/)

Open-source wealth management and portfolio tracking dashboard.

| Container | Description |
| --- | --- |
| `ghostfolio` | Main web application. Tracks investments across multiple asset classes and brokers, with charts, allocation views, and performance analytics. |
| `gf-postgres` | PostgreSQL database storing all portfolio data, transactions, and user settings. |
| `gf-redis` | Redis cache used for session management and API response caching. |

### [GitLab](https://about.gitlab.com/)

Fully self-hosted Git platform with built-in CI/CD pipelines.

| Container | Description |
| --- | --- |
| `gitlab` | GitLab Community Edition. Provides repository hosting, merge requests, issue tracking, the container registry, and the CI/CD pipeline configuration UI. Runs with its internal NGINX disabled so Traefik handles TLS. |
| `gitlab-runner` | CI/CD job executor registered to the self-hosted GitLab instance. Spawns Docker-in-Docker containers to run pipeline jobs. |

### [Vaultwarden](https://github.com/dani-garcia/vaultwarden)

Lightweight, self-hosted [Bitwarden](https://bitwarden.com)-compatible password manager server. Works with all official Bitwarden clients: mobile apps for Android and iOS, desktop apps for Windows, macOS, and Linux, and browser extensions for all major browsers.

| Container | Description |
| --- | --- |
| `vaultwarden` | Drop-in Bitwarden server written in Rust. Stores the encrypted vault locally, so no secrets ever leave the homelab. |

### [Backrest](https://github.com/garethgeorge/backrest)

Web UI for [Restic](https://restic.net)-based backups.

| Container | Description |
| --- | --- |
| `backrest` | Manages scheduled Restic snapshots of all Docker data volumes. Runs privileged with access to `/dev/btrfs-control` to support BTRFS filesystem snapshots. Supports remote storage backends (Backblaze B2, S3, SSH/SFTP). |

### [SFTP](https://github.com/atmoz/sftp)

Simple SFTP server for direct file transfer access.

| Container | Description |
| --- | --- |
| `sftp` | Provides SFTP access to the music library volume, useful for bulk uploads or scripted transfers that don't go through slskd or the file browser. |

### [Lockate](lockate/)

Custom Spring Boot application, split into an API service and a background jobs service.

| Container | Description |
| --- | --- |
| `lockate-api` | REST API server exposing the Lockate application endpoints. |
| `lockate-jobs` | Background job runner for the same application, using a separate Spring profile to avoid running scheduled tasks in the API pods. |
| `postgres` | PostgreSQL database for Lockate's persistent data. |
| `valkey` | Valkey (Redis-compatible) cache used by both the API and job services. |
| `liquibase` | Runs [Liquibase](https://www.liquibase.org) database migrations on startup (restarts on failure until the database is ready), keeping the schema in sync with the application. |

### [Portainer](https://www.portainer.io/)

Web UI for managing Docker across the homelab.

| Container | Description |
| --- | --- |
| `portainer` | Portainer Community Edition server. Provides a GUI for inspecting containers, stacks, images, volumes, and networks. |
| `portainer-agent` | Runs on the Docker host and gives Portainer full visibility into local volumes and containers, including those not started by Portainer itself. |

### [Dozzle](https://dozzle.dev/)

Real-time Docker log viewer.

| Container | Description |
| --- | --- |
| `dozzle` | Streams container logs live in the browser. Useful for a quick look at what a container is doing without SSH or `docker logs`. No data is stored — it reads directly from the Docker socket. |

### Monitoring Stack

Prometheus-based metrics collection with Grafana dashboards.

| Container | Description |
| --- | --- |
| `prometheus` | [Prometheus](https://prometheus.io/) — scrapes and stores time-series metrics from all configured targets. Central metrics store for the homelab. |
| `node-exporter` | [Node Exporter](https://github.com/prometheus/node_exporter) — exposes host-level system metrics (CPU, memory, disk I/O, network, filesystem) to Prometheus. Runs with full read access to the host filesystem. |
| `cadvisor` | [cAdvisor](https://github.com/google/cadvisor) — exposes per-container resource usage metrics (CPU, memory, network, disk) to Prometheus. |
| `grafana` | [Grafana](https://grafana.com/) — dashboards and visualisation layer. Connects to Prometheus as a data source and displays homelab health, resource usage, and service-level metrics. |

---

## Install

### 1. Prerequisites

- Docker with the Compose plugin
- A domain managed by OVH (used for the Let's Encrypt DNS challenge) — optional, any DNS provider supported by the [Traefik ACME DNS challenge](https://doc.traefik.io/traefik/https/acme/#providers) works
- Each stack folder under `/docker_data/<stack>` as a BTRFS subvolume — optional, only needed if you want Backrest to take filesystem-level snapshots; regular directories work otherwise
- `/docker_snapshots` directory where Backrest writes the snapshots (one per stack) — optional, same as above

### 2. Clone the repository

```bash
git clone <repo-url> peppolab
cd peppolab
```

### 3. Data directory layout

All persistent data lives under `/docker_data`. Each stack folder is its own BTRFS subvolume, which allows Backrest to snapshot them individually into `/docker_snapshots/<stack>`:

```text
/docker_data/
└── <stack>/          ← BTRFS subvolume
    ├── configs/      # config files, secrets, SSH keys, etc.
    └── volumes/      # container volume mounts

/docker_snapshots/
└── <stack>/          ← snapshot created by Backrest before each backup run
```

### 4. Configure environment variables

Steps 3, 4, and 5 can be automated by running [`scripts/install.sh`](scripts/install.sh) as root. For every stack with a `docker-compose.yml`/`.yaml`, it creates `/docker_data/<stack>` as a BTRFS subvolume (falling back to a plain directory if `/docker_data` isn't BTRFS), creates `configs/` and `volumes/` inside it, and — for stacks with a `docs/.env` template — copies it to `/docker_data/<stack>/configs/.env` and symlinks `<stack>/.env` to it (Option B below). It also applies the ownership fixes from step 5 (Navidrome, Prometheus). It never overwrites existing files, so it's safe to re-run. Use `--dry-run` to preview, and `--data-root` to point somewhere other than `/docker_data`:

```bash
sudo ./scripts/install.sh
```

You'll still need to edit each generated `configs/.env` with real values afterwards.

Otherwise, configuration can be done by hand. Each stack that needs configuration has a `docs/.env` template. The `.env` file itself can live either directly in the stack folder or in `/docker_data/<stack>/configs/` and be symlinked in:

**Option A — keep it in the repo folder:**

```bash
cp traefik/docs/.env traefik/.env
# edit traefik/.env with your values
```

**Option B — keep it in `/docker_data` and symlink:**

```bash
cp traefik/docs/.env /docker_data/traefik/configs/.env
# edit /docker_data/traefik/configs/.env with your values
ln -s /docker_data/traefik/configs/.env traefik/.env
```

Repeat for every stack that has a `docs/.env`:

```text
traefik   nextcloud   immich   gitlab   pihole
portainer   tig_stack   vaultwarden   tailscale
```

The most important file is [`traefik/docs/.env`](traefik/docs/.env). It holds the OVH API credentials and the public domain name for every service:

| Variable | Description |
| --- | --- |
| `ACME_EMAIL` | Email used for Let's Encrypt certificate registration |
| `OVH_APPLICATION_KEY` | OVH API application key |
| `OVH_APPLICATION_SECRET` | OVH API application secret |
| `OVH_CONSUMER_KEY` | OVH API consumer key |
| `OVH_ENDPOINT` | OVH API endpoint (e.g. `ovh-eu`) |
| `PUBLIC_DOMAIN` | Root domain (e.g. `peppolab.example.com`) |
| `*_DOMAIN` | One variable per service with its full subdomain |
| `BASIC_AUTH_PASSWORD` | Hashed password for services protected by basic auth |

### 5. Fix volume ownership

Handled automatically by `scripts/install.sh` (see step 4). To do it by hand instead: some containers run as non-root users and require the data directories to be owned by the right UID before first start:

```bash
# Navidrome and its companions run as 1000:1000
sudo chown -R 1000:1000 /docker_data/navidrome

# Prometheus runs as UID 65534 (nobody)
sudo chown -R 65534:65534 /docker_data/tig_stack/volumes/prometheus
```

### 6. Start services

Run [`scripts/start.sh`](scripts/start.sh) to bring up every stack in the right order — Tailscale, Traefik, Pi-hole, Portainer, Dozzle, TIG stack, Backrest, then the rest. Traefik has to precede Pi-hole/Portainer/Dozzle/TIG stack/Backrest since it creates the `traefik_global` Docker network they all join. Use `--dry-run` to preview the commands it would run:

```bash
./scripts/start.sh
```

Or do it by hand. Start Traefik first, since it creates the `traefik_global` Docker network that every other stack connects to:

```bash
cd traefik && docker compose up -d && cd ..
```

Then bring up the remaining stacks in any order:

```bash
for stack in pihole tailscale nextcloud immich navidrome ghostfolio gitlab vaultwarden backrest sftp lockate portainer dozzle tig_stack; do
  docker compose -p "$stack" -f "$stack/docker-compose.yml" up -d
done
```

### 7. Service-specific notes

**Tailscale** — generate an auth key at [login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys) (reusable, and pre-authorized if your tailnet requires it) and put it in `TS_AUTHKEY`. Set `ADVERTISE_ROUTES` to your home LAN's CIDR (e.g. `192.168.1.0/24`). After the container starts, go to the [admin console's Machines page](https://login.tailscale.com/admin/machines), open the `tailscale` machine, and approve the advertised subnet route — routes are not usable until approved. Install the Tailscale client on any device that needs remote access and sign into the same tailnet; no router port-forward or dynamic DNS entry is needed.

**GitLab Runner** — after GitLab is fully initialised, register the runner:

```bash
docker exec -it gitlab-runner gitlab-runner register
```

**Backrest (SFTP remote)** — place the SSH key pair in `/docker_data/backrest/configs/ssh/`, then set the env variable `RESTIC_SFTP_ARGS="-i /root/.ssh/id_ed25519 -o IdentitiesOnly=yes"` in the Backrest UI when creating the repository. The [`before_backup.sh`](backrest/scripts/before_backup.sh) and [`after_backup.sh`](backrest/scripts/after_backup.sh) scripts handle BTRFS snapshotting around each backup run.

**Nextcloud notify_push** — the `nextcloud-notify-push` container will fail on the first start until the [Client Push](https://apps.nextcloud.com/apps/notify_push) app is installed from the Nextcloud app store. Install the app first, then restart the container.
