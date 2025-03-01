# Cuprate Docker

This repository contains Docker configuration for running [Cuprate](https://github.com/Cuprate/cuprate), an alternative Monero node implementation written in Rust. This project is not affiliated with Monero or Cuprate.

Cuprate is not ready for production use.

## Features

- Multi-architecture support (amd64 and arm64)
- Automatic Monero blockchain synchronization
- Configurable for mainnet, testnet, or stagenet
- Persistent storage for blockchain data and configuration

## Prerequisites

- Docker
- Docker Compose
- Git

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/cuprate-docker.git
   cd cuprate-docker
   ```

2. Start the Cuprate node:
   ```bash
   docker-compose up -d
   ```

3. Check the logs:
   ```bash
   docker-compose logs -f
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

## Building for Multiple Architectures

To build for both amd64 and arm64:

```bash
# Create a new builder instance
docker buildx create --name mybuilder --use

# Build and push for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 -t yourusername/cuprate:latest --push .
```

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

## Advanced Configuration

For advanced configuration, you can create a custom config file and mount it in the container:

1. Create a config file (e.g., `cuprate.toml`) with your custom settings
2. Add a volume mount in `docker-compose.yml`:
   ```yaml
   volumes:
     - ./cuprate.toml:/home/cuprate/.config/cuprate/cuprate.toml
     - cuprate-data:/home/cuprate/.local/share/cuprate
     - cuprate-config:/home/cuprate/.config/cuprate
   ```

## Troubleshooting

### Insufficient Disk Space

The Monero blockchain requires significant disk space. Ensure your system has enough available space. Currently the Monero blockchain uses about 220 GB unpruned.

### Connection Issues

If you're having trouble connecting to the Monero network, check your firewall settings to ensure the P2P ports are accessible.

## License

This Docker configuration is provided under the same license as Cuprate:
- The `binaries/` directory in Cuprate is licensed under AGPL-3.0
- Everything else is licensed under MIT

See [Cuprate's LICENSE](https://github.com/Cuprate/cuprate/blob/main/LICENSE) for more details.
