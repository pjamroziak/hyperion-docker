# Hyperion on TrueNAS

This image runs Hyperion 2.2.1 on Debian Bookworm. The build verifies the upstream release package against its published SHA-256 checksum. At startup the entrypoint reads `PUID` and `PGID` and starts Hyperion under those IDs. Hyperion stores its database and user data in `/config` and writes console logs to Docker. [Hyperion release packages](https://github.com/hyperion-project/hyperion.ng/releases/tag/2.2.1)

## Build and publish

Run these commands in the repository on a Docker host with the same architecture as the target NAS. Publishing requires write access to the package. [GitHub Container Registry documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

```sh
docker build -t ghcr.io/pjamroziak/hyperion-docker:2.2.1 .
docker login ghcr.io -u pjamroziak
docker push ghcr.io/pjamroziak/hyperion-docker:2.2.1
```

TrueNAS needs pull access if the package is private. You can also build the image on the target host or transfer it with `docker save` and `docker load`. Compose can use a local image with the same name and tag.

## Install on TrueNAS

1. On TrueNAS SCALE 24.10 or later, create a dataset for the configuration. The example uses `/mnt/tank/apps/hyperion`. Give the UID and GID configured below read, write and traverse access to the dataset and any existing Hyperion data.
2. Open **Apps → Discover Apps → ⋮ → Install via YAML**. Name the app `hyperion` and paste `truenas-compose.yaml`. Set `source:` to the dataset path and edit `PUID` and `PGID` under `environment` to match its permissions. Both default to `568` and accept positive decimal IDs. [TrueNAS Custom Apps](https://apps.truenas.com/managing-apps/installing-custom-apps/)
3. Open the **Web UI** portal or browse to `http://TRUENAS_IP:8090`. If a host port is already occupied, change the left-hand side of its mapping. For HTTP, also update the `x-portals` port. The health check uses the internal HTTP port `8090`.

## Published ports

| Port | Protocol | Service |
| --- | --- | --- |
| 8090 | TCP | HTTP web UI, JSON-RPC over HTTP and WebSocket |
| 8092 | TCP | HTTPS web UI, JSON-RPC over HTTPS and secure WebSocket |
| 19333 | TCP | Boblight input, disabled by default in Hyperion |
| 19400 | TCP | FlatBuffers image input |
| 19444 | TCP | Raw JSON API |
| 19445 | TCP | Protocol Buffers image input |

Use `network_mode: host` and remove `ports:` if you need LAN multicast discovery through mDNS (`5353/udp`) or SSDP (`1900/udp`). In host mode, Hyperion uses the NAS network directly. [Hyperion connection options](https://api.hyperion-project.org/connect-to-hyperion-1027155m0), [Default Hyperion settings](https://github.com/hyperion-project/hyperion.ng/blob/2.2.1/settings/hyperion.settings.json.default), [Docker host networking](https://docs.docker.com/engine/network/drivers/host/)

## Logs and status

- Open **Apps → hyperion → Workloads → Logs** in TrueNAS to see startup messages, warnings and errors. The default level is `Info`. To enable `Debug` temporarily, add `command: ["--debug"]` under the `hyperion` service and remove it after troubleshooting. [TrueNAS container logs](https://apps.truenas.com/managing-apps/managing-installed-apps/), [Hyperion CLI options](https://docs.hyperion-project.org/user/advanced/CLI.html)
- The Docker `local` driver rotates logs across three 10 MB segments per container. Recreating the container starts a new log history. The dataset mounted at `/config` keeps the database and user data. [Docker local logging driver](https://docs.docker.com/engine/logging/drivers/local/)
- The health check probes the web UI over HTTP. For LED hardware and capture diagnostics, open **System → Log** in Hyperion. [Hyperion troubleshooting](https://docs.hyperion-project.org/user/advanced/Support.html)

## Hardware

- For WLED on a reachable LAN, enter the controller's IP address in Hyperion. [WLED configuration](https://docs.hyperion-project.org/user/leddevices/network/wled.html)
- For a USB capture device or serial controller, add the relevant device under `devices`, for example `/dev/video0:/dev/video0` or `/dev/ttyUSB0:/dev/ttyUSB0`. Use `group_add` for the device's numeric group ID on the NAS. If the grabber has a stable `/dev/v4l/by-id/` path, use it on the host side of the mapping.
