FROM rust:bookworm@sha256:48b7f435b8fc6378ce43b44f15e3a47fd8919b2825f835c39bd4bd3da50af5b8 AS rustbuilder
# Full upstream commit SHA
# 3f6cb73f491eb3195d02318643e40836fb093acc (0.13.20/2630.1-hotfix)
ARG MITHRIL_VERSION=3f6cb73f491eb3195d02318643e40836fb093acc
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

FROM ghcr.io/blinklabs-io/cardano-configs:20260915-1@sha256:d13289f8c094b8ec9e0f0c64888254c94183239400f9564fb933e323ee2fa5f7 AS cardano-configs

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
