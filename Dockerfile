# Build stage
FROM rust:1.93-slim-bookworm AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y build-essential pkg-config libssl-dev git cmake && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Define ARG for Cuprate tag
ARG CUPRATE_TAG=cuprated-0.0.8

# Clone the Cuprate repository with no caching
WORKDIR /usr/src

# The echo forces this layer to be rebuilt even when using cached layers
RUN git clone https://github.com/Cuprate/cuprate.git && \
    cd cuprate && \
    if [ "$CUPRATE_TAG" != "main" ]; then \
        git fetch --all --tags && \
        git checkout ${CUPRATE_TAG}; \
    fi
WORKDIR /usr/src/cuprate

# Build the project with BuildKit cache mounts for cargo
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/usr/src/cuprate/target \
    cargo build --release --bin cuprated && \
    cp target/release/cuprated /usr/local/bin/cuprated

# Runtime stage
FROM debian:trixie-slim

# OCI image labels
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.opencontainers.image.title="cuprate-docker" \
      org.opencontainers.image.description="Docker image for Cuprate, an alternative Monero node implementation written in Rust" \
      org.opencontainers.image.url="https://github.com/hundehausen/cuprate-docker" \
      org.opencontainers.image.source="https://github.com/hundehausen/cuprate-docker" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${VERSION}"

# Install runtime dependencies and apply latest security patches
RUN apt-get update && \
    apt-get install -y libssl3 ca-certificates wget && \
    apt-get upgrade -y && \
    # Clean up
    rm -rf /var/lib/apt/lists/*

# Create a cuprate user
RUN useradd -m -u 1000 -s /bin/bash cuprate

# Create directories for Cuprate data
RUN mkdir -p /home/cuprate/.local/share/cuprate /home/cuprate/.config/cuprate \
    && chown -R cuprate:cuprate /home/cuprate

# Copy the binary from the builder stage
COPY --from=builder /usr/local/bin/cuprated /usr/local/bin/

# Set the user
USER cuprate
WORKDIR /home/cuprate

# Healthcheck via restricted RPC
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=3 \
  CMD wget -q -O- http://localhost:18089/get_height || exit 1

# Expose P2P ports (mainnet, testnet, stagenet)
EXPOSE 18080/tcp 28080/tcp 38080/tcp
# Expose restricted RPC ports (mainnet, testnet, stagenet)
EXPOSE 18089/tcp 28089/tcp 38089/tcp

# Set up a volume for persistent data
VOLUME ["/home/cuprate/.local/share/cuprate", "/home/cuprate/.config/cuprate"]

# Default command
ENTRYPOINT ["cuprated"]
CMD ["--config-file", "/home/cuprate/.config/cuprate/Cuprated.toml"]
