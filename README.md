# Cuprate Docker

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
   docker run -d --name cuprate-node -v cuprate-data:/home/cuprate/.local/share/cuprate -v ./config:/home/cuprate/.config/cuprate -p 18080:18080 -p ghcr.io/hundehausen/cuprate-docker:latest
   ```

3. Check the logs:
   ```bash
   docker logs -f cuprate-node
   ```

## Configuration

### Network Selection

By default, the node runs on the Monero mainnet. To use testnet or stagenet, modify the `command` in `docker-compose.yml`:

```yaml
command: ["--network", "testnet"]  # or "stagenet"
```

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