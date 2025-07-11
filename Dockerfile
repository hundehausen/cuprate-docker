# Build stage
FROM rust:1.88-slim-bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Define ARG for Cuprate tag
ARG CUPRATE_TAG=cuprated-0.0.4

# Clone the Cuprate repository with no caching
WORKDIR /usr/src
# This ARG is used to bust the Docker build cache for the following RUN command
# Set to an always unique value during build with:
# docker build --build-arg CACHEBUST=$(date +%s) -t cuprate-docker .
ARG CACHEBUST=1
# The echo forces this layer to be rebuilt even when using cached layers
RUN echo "Cache bust: ${CACHEBUST}" && \
    git clone https://github.com/Cuprate/cuprate.git && \
    cd cuprate && \
    if [ "$CUPRATE_TAG" != "main" ]; then \
        git fetch --all --tags && \
        git checkout ${CUPRATE_TAG}; \
    fi
WORKDIR /usr/src/cuprate

# Build the project
RUN cargo build --release --bin cuprated

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies and upgrade zlib1g to address CVE-2023-45853
RUN apt-get update && \
    apt-get install -y libssl-dev ca-certificates && \
    # Add bookworm-security repository for security updates
    echo 'deb http://security.debian.org/debian-security bookworm-security main' > /etc/apt/sources.list.d/security.list && \
    apt-get update && \
    # Explicitly upgrade zlib1g to latest version
    apt-get install -y --only-upgrade zlib1g && \
    # Clean up
    rm -rf /var/lib/apt/lists/*

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

# Expose P2P ports (mainnet, testnet, stagenet)
EXPOSE 18080/tcp 28080/tcp 38080/tcp

# Set up a volume for persistent data
VOLUME ["/home/cuprate/.local/share/cuprate", "/home/cuprate/.config/cuprate"]

# Default command
ENTRYPOINT ["cuprated"]
