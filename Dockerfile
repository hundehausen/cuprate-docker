# Build stage
FROM rust:1.85-slim-bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Clone the Cuprate repository with no caching
WORKDIR /usr/src
# Set cuprate branch or release to use and pin to a given commit
ARG CUPRATE_BRANCH=cuprated-0.0.1
ARG CUPRATE_COMMIT=21ad35d44a465efbb5414a902cb6c370b8358303
# This ARG is used to bust the Docker build cache for the following RUN command
# Set to an always unique value during build with:
# docker build --build-arg CACHEBUST=$(date +%s) -t cuprate-docker .
ARG CACHEBUST=1
# The echo forces this layer to be rebuilt even when using cached layers
RUN echo "Cache bust: ${CACHEBUST}" \
    && git clone --branch ${CUPRATE_BRANCH} https://github.com/Cuprate/cuprate.git \
    && test `git rev-parse HEAD` = ${CUPRATE_COMMIT} || exit 1 \
WORKDIR /usr/src/cuprate

# Build the project
RUN cargo build --release --bin cuprated

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a cuprate user
RUN useradd -m -u 1000 -s /bin/bash cuprate

# Create directories for Cuprate data
RUN mkdir -p /home/cuprate/.local/share/cuprate /home/cuprate/.config/cuprate \
    && chown -R cuprate:cuprate /home/cuprate

# Copy the binary from the builder stage
COPY --from=builder /usr/src/cuprate/target/release/cuprated /usr/local/bin/

# Set the user
USER cuprate
WORKDIR /home/cuprate

# Expose P2P and RPC ports (mainnet, testnet, stagenet)
# P2P ports
EXPOSE 18080/tcp 28080/tcp 38080/tcp
# RPC ports
EXPOSE 18081/tcp 28081/tcp 38081/tcp

# Set up a volume for persistent data
VOLUME ["/home/cuprate/.local/share/cuprate", "/home/cuprate/.config/cuprate"]

# Default command
ENTRYPOINT ["cuprated"]
