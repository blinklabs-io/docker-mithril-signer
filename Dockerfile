FROM rust:bookworm@sha256:9181b56c2a21ab1d5e73cffe04fc762426d30aa7fac3c91141dd033f49a7fc8b AS rustbuilder
# Full upstream commit SHA
# e85df3ddc52b528c7b9ddbdddf1941fec6d5f348 (2642.0)
ARG MITHRIL_VERSION=e85df3ddc52b528c7b9ddbdddf1941fec6d5f348
ENV MITHRIL_VERSION=${MITHRIL_VERSION}
WORKDIR /code
RUN echo "Building ${MITHRIL_VERSION}..." \
    && git init mithril \
    && cd mithril \
    && git remote add origin https://github.com/input-output-hk/mithril.git \
    && git fetch --depth 1 origin "${MITHRIL_VERSION}" \
    && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "${MITHRIL_VERSION}" \
    && cargo build --release -p mithril-signer

FROM ghcr.io/blinklabs-io/cardano-configs:20261027-1@sha256:f111e6bfd0d0332fa73d3aee857d13f32247a8e7cd8655df624f70e8b832ad0b AS cardano-configs

FROM debian:bookworm-slim@sha256:7ff6ba31527b9e336162fa061746c366c4b2032f4d2cff2078bea43f78efe3f8 AS mithril-signer
COPY --from=rustbuilder /code/mithril/target/release/mithril-signer /bin/
COPY --from=cardano-configs /config/ /opt/cardano/config/
RUN apt-get update -y \
    && apt-get install -y \
       ca-certificates \
       libssl3 \
       llvm-14-runtime \
       sqlite3 \
       wget \
    && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["/bin/mithril-signer"]
