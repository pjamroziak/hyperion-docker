FROM debian:bookworm-slim

ARG TARGETARCH

LABEL org.opencontainers.image.title="Hyperion" \
      org.opencontainers.image.version="2.2.1" \
      org.opencontainers.image.source="https://github.com/pjamroziak/hyperion-docker"

RUN set -eu; \
    case "$TARGETARCH" in \
        amd64) checksum=8e30585049421297455387564f8df2c87603f0f8557bc95abca102be27e872b9 ;; \
        arm64) checksum=ee5e9eaeeb4a6bc69174b15dcb316de274cc77dab93fc5c370905e04ca2f056b ;; \
        *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    apt-get update -o APT::Update::Error-Mode=any; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl libgl1 libglib2.0-0 tzdata util-linux; \
    curl --fail --silent --show-error --location --retry 3 \
        "https://github.com/hyperion-project/hyperion.ng/releases/download/2.2.1/Hyperion-2.2.1-Linux-${TARGETARCH}.deb" \
        --output /tmp/hyperion.deb; \
    printf '%s  /tmp/hyperion.deb\n' "$checksum" | sha256sum --check --strict; \
    DEBIAN_FRONTEND=noninteractive XDG_CURRENT_DESKTOP=container-build \
        apt-get install -y --no-install-recommends /tmp/hyperion.deb; \
    rm /tmp/hyperion.deb; \
    rm -rf /var/lib/apt/lists/*; \
    hyperiond --service --version

ENV PUID=568 PGID=568 HOME=/config
RUN install -d -m 0750 -o "$PUID" -g "$PGID" /config

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

EXPOSE 8090/tcp 8092/tcp 19333/tcp 19400/tcp 19444/tcp 19445/tcp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["--info"]
