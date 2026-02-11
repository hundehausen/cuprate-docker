# Cuprate Docker

[![Build Status](https://github.com/hundehausen/cuprate-docker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/hundehausen/cuprate-docker/actions/workflows/docker-build.yml)
[![Image Size](https://ghcr-badge.egpl.dev/hundehausen/cuprate-docker/size)](https://github.com/hundehausen/cuprate-docker/pkgs/container/cuprate-docker)
[![Latest Version](https://ghcr-badge.egpl.dev/hundehausen/cuprate-docker/latest_tag?trim=major&label=latest)](https://github.com/hundehausen/cuprate-docker/pkgs/container/cuprate-docker)

This repository contains Docker configuration for running [Cuprate](https://github.com/Cuprate/cuprate), an alternative Monero node implementation written in Rust. This project is not affiliated with Monero or Cuprate.

Cuprate is not ready for production use.

## Known issues

- cuprated is buggy if STDIN pipe is not available -> Spams logs [Issue](https://github.com/Cuprate/cuprate/issues/396)
  - Note that this is fixed if you run the Docker Compose in this repo.

## Quick Start

### With Docker Compose

1. Clone this repository:
   ```bash
   git clone https://github.com/hundehausen/cuprate-docker.git
   cd cuprate-docker
   ```

2. Start the Cuprate node:
   ```bash
   docker compose up -d
   ```

3. Check the logs:
   ```bash
   docker compose logs -f
   ```

### With Docker run

1. Clone this repository:
   ```bash
   git clone https://github.com/hundehausen/cuprate-docker.git
   cd cuprate-docker
   ```

2. Start the Cuprate node:
   ```bash
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

3. Check the logs:
   ```bash
   docker logs -f cuprate-node
   ```

## Building from Source

To build the image locally with a specific Cuprate version:

```bash
docker build -t cuprate-docker:local \
  --build-arg CUPRATE_TAG=cuprated-0.0.8 \
  .
```

Replace `cuprated-0.0.8` with the desired [Cuprate release tag](https://github.com/Cuprate/cuprate/tags) or use `main` for the latest development version.

## Multi-Architecture Support

Pre-built images are available for both `linux/amd64` and `linux/arm64` architectures. Docker will automatically pull the correct image for your platform.

## Configuration

### Network Selection

By default, the node runs on the Monero mainnet. To use testnet or stagenet, modify the `command` in `docker-compose.yml`:

```yaml
command: ["--network", "testnet"]  # or "stagenet"
```

See `docker-compose.override.yml.example` for a ready-made testnet/stagenet template.

### Data Persistence

Blockchain data is stored in Docker volume:
- `cuprate-data`: Contains the blockchain data
Config data is the directory mounted at `./config`:
- `./config`: Contains configuration files

## Ports

The following ports are exposed:

- **P2P Ports**:
  - Mainnet: 18080
  - Testnet: 28080
  - Stagenet: 38080
- **Restricted RPC Ports**:
   - Mainnet: 18089
   - Testnet: 28089
   - Stagenet: 38089

## Troubleshooting

### STDIN/TTY Issue

cuprated requires a STDIN pipe to avoid log spam ([#396](https://github.com/Cuprate/cuprate/issues/396)). When using `docker run`, always include the `-t -i` flags. The docker-compose configuration handles this automatically with `tty: true` and `stdin_open: true`.

### Container Exits Immediately

Check the container logs for error details:
```bash
docker logs cuprate-node
```

Common causes include invalid configuration file syntax or insufficient permissions on mounted volumes. Ensure the `config/` directory and its files are readable.

### Slow Initial Sync

The initial blockchain sync can take a significant amount of time depending on your hardware and network connection. With `fast_sync = true` (the default), block verification is accelerated by comparing against known hashes. Monitor progress via the logs:
```bash
docker compose logs -f
```
