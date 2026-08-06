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
- Builds pinned to the exact upstream commit — a moved or force-pushed tag fails the build instead of changing what ships
- CI smoke-tests every image (binary commit + healthcheck) before it is tagged `latest`
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

The image also ships a copy of the default config at `/home/cuprate/.config/cuprate/Cuprated.toml`, so it works standalone without any mount. A bind-mounted `./config` (as in `docker-compose.yml`) shadows that copy.

## Ports

| Network | P2P | Restricted RPC |
|---------|-----|-----------------|
| Mainnet | 18080 | 18089 |
| Testnet | 28080 | 28089 |
| Stagenet | 38080 | 38089 |

Only mainnet ports are mapped by default. See `docker-compose.override.yml.example` for testnet/stagenet.

## Security: Docker port publishing (0.0.0.0) and UFW

Docker publishes ports on all interfaces by default. If you define `ports:` in `docker-compose.yml` (for example `- 18089:18089`), Docker binds those ports to `0.0.0.0` unless you explicitly specify a host IP, making them reachable from any network interface on the host.

This can also bypass UFW rules. Docker installs its own iptables rules that accept traffic to published ports before UFW's filter rules are evaluated, so even a default-deny firewall does not stop a published port from being reachable from the internet.

- The restricted RPC (`18089`) is enabled by default in this image (`rpc.restricted.enable = true`). If you do not want it exposed publicly, either do not publish it at all or bind it only to localhost:
  - `docker-compose.yml`: `ports: ["127.0.0.1:18089:18089"]`
- For a public P2P node, it is normal to publish `18080`. Be deliberate about whether `18089` (restricted RPC) should be public.
- If you are running this container behind a firewall (e.g. at home behind a NAT router), it is usually okay to bind on `0.0.0.0`.

The unrestricted RPC (`18081`) is only bound to `127.0.0.1` inside the container and is never published by default.

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

# Build a specific Cuprate version (pinned to its commit hash)
docker build -t cuprate-docker:local \
  --build-arg CUPRATE_TAG=cuprated-0.1.0-preview \
  .

# Build a specific Cuprate version with an explicit commit hash
# (PINNED_COMMIT must be the commit CUPRATE_TAG resolves to)
docker build -t cuprate-docker:local \
  --build-arg CUPRATE_TAG=cuprated-0.1.0-preview \
  --build-arg CUPRATE_COMMIT_HASH=318c2dea4eb404ac4ecf2bea87c1a4696b0198cc \
  .

# Build latest development version (moving branch, pin check skipped)
docker build -t cuprate-docker:local \
  --build-arg CUPRATE_TAG=main \
  .

# Optional allocator feature (default: jemalloc)
docker build -t cuprate-docker:local \
  --build-arg FEATURES=jemalloc \
  .
```

The build verifies that `CUPRATE_TAG` resolves to `CUPRATE_COMMIT_HASH` and fails if they disagree — a moved or force-pushed upstream tag can never silently change what gets built. The exception is `CUPRATE_TAG=main`, which points at a moving branch and is not pinned. The default tag and hash are kept in lockstep in the `Dockerfile`.

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
