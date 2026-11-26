# Hyperion on TrueNAS

This image runs Hyperion 2.2.1 on Debian Bookworm. The build verifies the upstream release package against its published SHA-256 checksum. At startup the entrypoint reads `PUID` and `PGID` and starts Hyperion under those IDs. Hyperion stores its database and user data in `/config` and writes console logs to Docker. [Hyperion release packages](https://github.com/hyperion-project/hyperion.ng/releases/tag/2.2.1)

## Releases

Pull requests build and smoke-test the image on `amd64` and `arm64`. A release tag on `main` runs the same checks and publishes both tested images under one tag in GitHub Container Registry. The published image for the first release is `ghcr.io/pjamroziak/hyperion-docker:2.2.1-r1`.

The image tag combines the upstream Hyperion version and the image revision. Use `2.2.1-r2` for the next packaging or Debian dependency update that keeps Hyperion at `2.2.1`. Start at `r1` when the upstream Hyperion version changes and update the release package checksums in the Dockerfile. Each revision gets its own tag.

Update the image tag in `truenas-compose.yaml` in the release PR. After the PR is merged, tag the matching commit on `main` and push the tag:

```sh
git switch main
git pull --ff-only
git tag v2.2.1-r1
git push origin refs/tags/v2.2.1-r1
```

GitHub creates the package with private visibility on the first push. Grant the NAS pull access for a private package, or set the package to public for anonymous pulls. [GitHub Container Registry documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

For local testing, you can build the image on the target architecture with `docker build -t ghcr.io/pjamroziak/hyperion-docker:2.2.1-r1 .`.

## Install on TrueNAS

1. On TrueNAS SCALE 24.10 or later, create a dataset for the configuration. The example uses `/mnt/tank/apps/hyperion`. Give the UID and GID configured below read, write and traverse access to the dataset and any existing Hyperion data.
2. Open **Apps → Discover Apps → ⋮ → Install via YAML**. Name the app `hyperion` and paste `truenas-compose.yaml`. Set `source:` to the dataset path and edit `PUID` and `PGID` under `environment` to match its permissions. Both default to `568` and accept positive decimal IDs. [TrueNAS Custom Apps](https://apps.truenas.com/managing-apps/installing-custom-apps/)
3. Open the **Web UI** portal or browse to `http://TRUENAS_IP:8090`. If a host port is already occupied, change the left-hand side of its mapping. For HTTP, also update the `x-portals` port. The health check uses the internal HTTP port `8090`.

To upgrade, edit the app's YAML and set `image` to the new release tag. Take a snapshot of the configuration dataset before upgrading Hyperion. To roll back, restore the previous tag and restore the snapshot if the new version migrated the database.

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
