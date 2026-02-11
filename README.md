<p align="center">
  <img src="https://raw.githubusercontent.com/Cuprate/cuprate/main/misc/logo/wordmark/CuprateWordmark.svg" alt="Cuprate" width="400">
</p>

<h3 align="center">Cuprate Docker</h3>

<p align="center">
  Dockerized <a href="https://github.com/Cuprate/cuprate">Cuprate</a> — an alternative Monero node written in Rust
</p>

<p align="center">
  <a href="https://github.com/hundehausen/cuprate-docker/actions/workflows/docker-build.yml"><img src="https://github.com/hundehausen/cuprate-docker/actions/workflows/docker-build.yml/badge.svg" alt="Build Status"></a>
  <a href="https://github.com/hundehausen/cuprate-docker/pkgs/container/cuprate-docker"><img src="https://ghcr-badge.egpl.dev/hundehausen/cuprate-docker/size" alt="Image Size"></a>
  <a href="https://github.com/hundehausen/cuprate-docker/pkgs/container/cuprate-docker"><img src="https://ghcr-badge.egpl.dev/hundehausen/cuprate-docker/latest_tag?trim=major&label=latest" alt="Latest Version"></a>
</p>

---

> **Note:** Cuprate is under active development and not yet ready for production use. This project is not affiliated with Monero or Cuprate.

## Features

- Multi-architecture images (`linux/amd64` and `linux/arm64`)
- Automated builds — new upstream Cuprate releases are detected and built every 8 hours
- Healthcheck via restricted RPC endpoint
- Resource limits and log rotation pre-configured
- Mainnet, testnet, and stagenet support

## Quick Start

### Docker Compose (recommended)

```bash
git clone https://github.com/hundehausen/cuprate-docker.git
cd cuprate-docker
docker compose up -d
```

### Docker Run

```bash
git clone https://github.com/hundehausen/cuprate-docker.git
cd cuprate-docker

docker run -d \
  --name cuprate-node \
  -t -i \
  -v cuprate-data:/home/cuprate/.local/share/cuprate \
  -v ./config:/home/cuprate/.config/cuprate \
  -p 18080:18080 \
  -p 18089:18089 \
  ghcr.io/hundehausen/cuprate-docker:latest \
  --config-file /home/cuprate/.config/cuprate/Cuprated.toml
```

### Verify it's running

```bash
# Check logs
docker compose logs -f

# Check healthcheck status
docker inspect --format='{{.State.Health.Status}}' cuprate-node

# Query the restricted RPC
curl http://localhost:18089/get_height
```

## Configuration

The default configuration is in `config/Cuprated.toml`, which is mounted into the container. Edit this file to customize your node. For full documentation, see the [Cuprate User Book](https://user.cuprate.org).

Key defaults:

| Setting | Value | Description |
|---------|-------|-------------|
| `network` | `"Mainnet"` | Network to sync (`Mainnet`, `Testnet`, `Stagenet`) |
| `fast_sync` | `true` | Skip verification of old blocks using known hashes |
| `rpc.restricted.enable` | `true` | Restricted (read-only) RPC on `0.0.0.0:18089` |
| `rpc.unrestricted.enable` | `true` | Unrestricted RPC on `127.0.0.1:18081` (localhost only) |

### Network Selection

By default the node runs on mainnet. For testnet or stagenet, copy the override example and uncomment the section you need:

```bash
cp docker-compose.override.yml.example docker-compose.override.yml
# Edit docker-compose.override.yml, then:
docker compose up -d
```

### Data Persistence

| Volume/Mount | Container Path | Description |
|---|---|---|
| `cuprate-data` (Docker volume) | `/home/cuprate/.local/share/cuprate` | Blockchain database |
| `./config` (bind mount) | `/home/cuprate/.config/cuprate` | Configuration files |

## Ports

| Network | P2P | Restricted RPC |
|---------|-----|-----------------|
| Mainnet | 18080 | 18089 |
| Testnet | 28080 | 28089 |
| Stagenet | 38080 | 38089 |

Only mainnet ports are mapped by default. See `docker-compose.override.yml.example` for testnet/stagenet.

## Building from Source

```bash
# Build with default tag
docker build -t cuprate-docker:local .

# Build a specific Cuprate version
docker build -t cuprate-docker:local \
  --build-arg CUPRATE_TAG=cuprated-0.0.8 \
  .

# Build latest development version
docker build -t cuprate-docker:local \
  --build-arg CUPRATE_TAG=main \
  .
```

You can also use the compose override to build locally instead of pulling from GHCR — see `docker-compose.override.yml.example`.

## Troubleshooting

### STDIN/TTY Issue

cuprated requires a STDIN pipe to avoid log spam ([cuprate#396](https://github.com/Cuprate/cuprate/issues/396)). When using `docker run`, always include the `-t -i` flags. The docker-compose configuration handles this automatically with `tty: true` and `stdin_open: true`.

### Container Exits Immediately

Check the container logs:

```bash
docker logs cuprate-node
```

Common causes: invalid config file syntax, insufficient permissions on mounted volumes. Ensure `config/` and its files are readable.

### Slow Initial Sync

The initial blockchain sync takes a significant amount of time depending on hardware and network. With `fast_sync = true` (the default), block verification is accelerated by comparing against known hashes. Monitor progress:

```bash
docker compose logs -f
```

### Healthcheck Failing

The healthcheck queries the restricted RPC at `http://localhost:18089/get_height`. If it fails:

1. Ensure `rpc.restricted.enable = true` in `config/Cuprated.toml`
2. The node has a 120-second start period before healthchecks begin
3. Check if the node is still syncing — RPC may not respond until initial startup completes
