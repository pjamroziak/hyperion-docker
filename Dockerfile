# syntax=docker/dockerfile:1

ARG HYPERION_VERSION=2.2.1

FROM scratch AS hyperion-package
ARG HYPERION_VERSION
ADD --checksum=sha256:8e30585049421297455387564f8df2c87603f0f8557bc95abca102be27e872b9 --chmod=0644 \
    https://github.com/hyperion-project/hyperion.ng/releases/download/${HYPERION_VERSION}/Hyperion-${HYPERION_VERSION}-Linux-amd64.deb /hyperion.deb

FROM debian:bookworm-slim AS runtime

ARG HYPERION_VERSION
ARG TARGETARCH

LABEL org.opencontainers.image.title="Hyperion" \
      org.opencontainers.image.version="${HYPERION_VERSION}" \
      org.opencontainers.image.source="https://github.com/pjamroziak/hyperion-docker"

RUN --mount=type=bind,from=hyperion-package,source=/hyperion.deb,target=/tmp/hyperion.deb \
    set -eu; \
    if [ "$TARGETARCH" != amd64 ]; then \
        echo "This image supports only linux/amd64." >&2; \
        exit 1; \
    fi; \
    apt-get update -o APT::Update::Error-Mode=any; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl libdbus-1-3 libegl1 libfontconfig1 libgl1 \
        libglib2.0-0 libxkbcommon0 tzdata util-linux; \
    DEBIAN_FRONTEND=noninteractive XDG_CURRENT_DESKTOP=container-build \
        apt-get install -y --no-install-recommends /tmp/hyperion.deb; \
    rm -rf /var/lib/apt/lists/*; \
    if ! hyperiond --service --version; then \
        ldd "$(readlink -f "$(command -v hyperiond)")" >&2; \
        exit 1; \
    fi

ENV PUID=568 PGID=568 HOME=/config
RUN install -d -m 0750 -o "$PUID" -g "$PGID" /config

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

EXPOSE 8090/tcp 8092/tcp 19333/tcp 19400/tcp 19444/tcp 19445/tcp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["--info"]
