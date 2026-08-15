# Build stage
FROM rust:1.97-slim-trixie AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential pkg-config libssl-dev git cmake && \
    rm -rf /var/lib/apt/lists/*

# Cuprate release tag / branch to build
# renovate: datasource=github-releases depName=Cuprate/cuprate
ARG CUPRATE_TAG=cuprated-0.1.0-preview
# The exact commit CUPRATE_TAG must resolve to. Pinning this hash means a moved or
# force-pushed upstream tag fails the build instead of silently producing a
# different binary. Always bump this in lockstep with CUPRATE_TAG.
# Only skipped when CUPRATE_TAG=main (a moving branch that cannot be pinned).
ARG CUPRATE_COMMIT_HASH=318c2dea4eb404ac4ecf2bea87c1a4696b0198cc
# Allocator feature (matches upstream Docker default)
ARG FEATURES=jemalloc

# Clone the Cuprate repository
WORKDIR /usr/src

RUN git clone https://github.com/Cuprate/cuprate.git && \
    cd cuprate && \
    if [ "$CUPRATE_TAG" != "main" ]; then \
        git fetch --all --tags && \
        git checkout ${CUPRATE_TAG} && \
        test "$(git rev-parse HEAD)" = "${CUPRATE_COMMIT_HASH}" || \
            { echo "error: ${CUPRATE_TAG} resolves to $(git rev-parse HEAD), expected ${CUPRATE_COMMIT_HASH}" >&2; exit 1; }; \
    fi
WORKDIR /usr/src/cuprate

# Build the project with BuildKit cache mounts for cargo
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/usr/src/cuprate/target \
    cargo build --release --locked --bin cuprated --features "$FEATURES" && \
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
    apt-get install -y --no-install-recommends ca-certificates wget && \
    rm -rf /var/lib/apt/lists/*

# Defense-in-depth: Debian's base image ships setuid-root helpers (mount(8),
# su(1), passwd(1), ...). The node runs as a non-privileged user with all
# capabilities dropped and no-new-privileges enforced at deploy time (see
# docker-compose.yml), but remove the bits anyway so no helper in the image can
# ever be used to gain root after a compromise. chmod, not delete, so packages
# keep their files intact.
RUN find / -xdev -type f -perm /4000 -exec chmod u-s {} + && \
    find / -xdev -type f -perm /2000 -exec chmod g-s {} +

# Create a cuprate user
RUN useradd -m -u 1000 -s /usr/sbin/nologin cuprate

# Create directories for Cuprate data, config, and cache
RUN mkdir -p /home/cuprate/.local/share/cuprate \
             /home/cuprate/.config/cuprate \
             /home/cuprate/.cache/cuprate \
    && chown -R cuprate:cuprate /home/cuprate

# Copy the binary from the builder stage
COPY --from=builder /usr/local/bin/cuprated /usr/local/bin/

# Ship a default config so the image works standalone (e.g. CI smoke tests).
# A bind-mounted ./config (as in docker-compose.yml) shadows this path and wins.
COPY --chown=cuprate:cuprate config/Cuprated.toml /home/cuprate/.config/cuprate/Cuprated.toml

# Set the user
USER cuprate
WORKDIR /home/cuprate
ENV HOME=/home/cuprate

# Healthcheck via restricted RPC
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=3 \
  CMD wget -q -O- http://localhost:18089/get_height || exit 1

# Expose P2P ports (mainnet, testnet, stagenet)
EXPOSE 18080/tcp 28080/tcp 38080/tcp
# Expose restricted RPC ports (mainnet, testnet, stagenet)
EXPOSE 18089/tcp 28089/tcp 38089/tcp

# Default command
ENTRYPOINT ["cuprated"]
CMD ["--config-file", "/home/cuprate/.config/cuprate/Cuprated.toml"]
