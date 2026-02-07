# Build stage
FROM rust:1.92-slim-bookworm AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y build-essential pkg-config libssl-dev git cmake && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Define ARG for Cuprate tag
ARG CUPRATE_TAG=cuprated-0.0.6

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

# Build the project
RUN cargo build --release --bin cuprated

# Runtime stage
FROM debian:trixie-slim

# Install runtime dependencies and upgrade zlib1g to address CVE-2023-45853
RUN apt-get update && \
    apt-get install -y libssl-dev ca-certificates && \
    apt-get upgrade -y && \
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
# Expose unrestricted RPC ports (mainnet, testnet, stagenet)
EXPOSE 18089/tcp 28089/tcp 38089/tcp

# Set up a volume for persistent data
VOLUME ["/home/cuprate/.local/share/cuprate", "/home/cuprate/.config/cuprate"]

# Default command
ENTRYPOINT ["cuprated"]
CMD []
