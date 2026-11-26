FROM debian:bookworm-slim

ARG HYPERION_VERSION=2.2.1

LABEL org.opencontainers.image.title="Hyperion" \
      org.opencontainers.image.version="${HYPERION_VERSION}" \
      org.opencontainers.image.source="https://github.com/pjamroziak/hyperion-docker"

RUN set -eu; \
    apt-get update -o APT::Update::Error-Mode=any; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl gpg tzdata; \
    curl --fail --silent --show-error --location --retry 3 \
        https://releases.hyperion-project.org/hyperion.pub.key --output /tmp/hyperion.pub; \
    gpg --batch --dearmor --output /usr/share/keyrings/hyperion.gpg /tmp/hyperion.pub; \
    rm /tmp/hyperion.pub; \
    printf '%s\n' 'deb [signed-by=/usr/share/keyrings/hyperion.gpg] https://apt.releases.hyperion-project.org/ bookworm main' \
        > /etc/apt/sources.list.d/hyperion.list; \
    apt-get update -o APT::Update::Error-Mode=any; \
    package_version="$(apt-cache madison hyperion | awk -F '|' -v wanted="$HYPERION_VERSION" ' \
        { gsub(/[[:space:]]/, "", $2) } \
        $2 == wanted || index($2, wanted "+") == 1 || index($2, wanted "-") == 1 { print $2; exit } \
    ')"; \
    if [ -z "$package_version" ]; then \
        echo "Hyperion $HYPERION_VERSION is unavailable in the Bookworm APT repository" >&2; \
        exit 1; \
    fi; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; \
    chmod +x /usr/sbin/policy-rc.d; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "hyperion=$package_version"; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd --gid 568 hyperion; \
    useradd --uid 568 --gid 568 --home-dir /config --no-create-home --no-log-init hyperion; \
    install -d -m 0750 -o 568 -g 568 /config

USER 568:568
ENV HOME=/config
EXPOSE 8090/tcp

RUN hyperiond --service --version

ENTRYPOINT ["/usr/bin/stdbuf", "-oL", "hyperiond", "--service", "--userdata", "/config"]
CMD ["--info"]
