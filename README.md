# Cuprate Docker

This repository contains Docker configuration for running [Cuprate](https://github.com/Cuprate/cuprate), an alternative Monero node implementation written in Rust. This project is not affiliated with Monero or Cuprate.

Cuprate is not ready for production use.

## Quick Start

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

## Configuration

### Network Selection

By default, the node runs on the Monero mainnet. To use testnet or stagenet, modify the `command` in `docker-compose.yml`:

```yaml
command: ["--network", "testnet"]  # or "stagenet"
```

### Data Persistence

Blockchain data and configuration are stored in Docker volumes:
- `cuprate-data`: Contains the blockchain data
- `cuprate-config`: Contains configuration files

## Ports

The following ports are exposed:

- **P2P Ports**:
  - Mainnet: 18080
  - Testnet: 28080
  - Stagenet: 38080

- **RPC Ports**:
  - Mainnet: 18081
  - Testnet: 28081
  - Stagenet: 38081
