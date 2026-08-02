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

Compatible with **cuprated 0.1.0-preview (Kesterite)** — initial wallet RPC support, offline mode, graceful shutdown, regtest/FakeChain, and SOCKS5 proxies.

## Features

- Multi-architecture images (`linux/amd64` and `linux/arm64`)
- Automated builds — new upstream Cuprate releases are detected and built every 8 hours
- Built with `jemalloc` (same default as upstream Docker)
- Healthcheck via restricted RPC endpoint
- Resource limits (4 GB memory limit in Docker Compose) and log rotation pre-configured
- Mainnet, testnet, stagenet, and FakeChain/regtest support

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
| `network` | `"Mainnet"` | Network to sync (`Mainnet`, `Testnet`, `Stagenet`, `FakeChain`) |
| `offline` | `false` | When `true`, no P2P connections are made or accepted |
| `fast_sync` | `true` | Skip verification of old blocks using known hashes |
| `rpc.restricted.enable` | `true` | Restricted RPC on `0.0.0.0:18089` (enabled for Docker healthcheck; upstream default is `false`) |
| `rpc.unrestricted.enable` | `true` | Unrestricted RPC on `127.0.0.1:18081` (container-local only by default) |
| `target_max_memory` | auto-detected | Target max memory usage in bytes (auto-detected from system RAM) |

### Network Selection

By default the node runs on mainnet. For testnet, stagenet, offline mode, or regtest, copy the override example and uncomment the section you need:

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

## CLI Options

`cuprated` supports several command-line flags that override config file values. These can be passed via the `command` array in `docker-compose.yml` or at the end of a `docker run` invocation:

| Flag | Description |
|------|-------------|
| `--network <mainnet\|testnet\|stagenet\|fakechain>` | Override the network to run on |
| `--regtest` | Regtest mode (equivalent to `--network=fakechain`) |
| `--offline` | Do not connect to or listen for peers |
| `--outbound-connections <N>` | Outbound clear-net connections to maintain |
| `--seed-node <IP:PORT>` | Extra seed node (repeatable; useful for regtest) |
| `--fixed-difficulty <N>` | Force difficulty cache value (regtest only) |
| `--config-file <PATH>` | Specify a custom config file path |
| `--dry-run` | Validate configuration and exit without starting the node |
| `--generate-config` | Print the full default config file to stdout |
| `--skip-config-warning` | Skip the missing-config warning delay |
| `--version` | Print version and build information in JSON |
| `--no-fast-sync` | Disable fast sync (full verification of all past blocks) |

Example:

```bash
docker run --rm ghcr.io/hundehausen/cuprate-docker:latest --version
```

## Building from Source

```bash
# Build with default tag (cuprated-0.1.0-preview)
docker build -t cuprate-docker:local .

# Build a specific Cuprate version
docker build -t cuprate-docker:local \
  --build-arg CUPRATE_TAG=cuprated-0.1.0-preview \
  .

# Build latest development version
docker build -t cuprate-docker:local \
  --build-arg CUPRATE_TAG=main \
  .

# Optional allocator feature (default: jemalloc)
docker build -t cuprate-docker:local \
  --build-arg FEATURES=jemalloc \
  .
```

You can also use the compose override to build locally instead of pulling from GHCR — see `docker-compose.override.yml.example`.

## Troubleshooting

### Container Exits Immediately

Check the container logs:

```bash
docker logs cuprate-node
```

Common causes: invalid config file syntax, insufficient permissions on mounted volumes. Ensure `config/` and its files are readable.

You can validate your config before starting the container:

```bash
docker run --rm \
  -v ./config:/home/cuprate/.config/cuprate:ro \
  ghcr.io/hundehausen/cuprate-docker:latest \
  --config-file /home/cuprate/.config/cuprate/Cuprated.toml --dry-run
```

### Slow Initial Sync

The initial blockchain sync takes a significant amount of time depending on hardware and network. With `fast_sync = true` (the default), block verification is accelerated by comparing against known hashes. Monitor progress:

```bash
docker compose logs -f
```

### Healthcheck Failing

The healthcheck queries the restricted RPC at `http://localhost:18089/get_height`. If it fails:

1. Ensure `rpc.restricted.enable = true` in `config/Cuprated.toml` (this image enables it by default)
2. The node has a 120-second start period before healthchecks begin
3. Check if the node is still syncing — RPC may not respond until initial startup completes
