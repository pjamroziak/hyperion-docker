#!/usr/bin/env bash
set -euo pipefail

target=$1
archive_dir=$2
run_id=$3
repository=${target%:*}

# Load and validate both artifacts before pushing either platform.
for arch in amd64 arm64; do
    source="hyperion-release:$arch"
    docker image load --input "$archive_dir/hyperion-$arch.tar.gz"
    platform=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$source")
    if [[ "$platform" != "linux/$arch" ]]; then
        printf 'Expected linux/%s in %s, found %s.\n' "$arch" "$source" "$platform" >&2
        exit 1
    fi
done

sources=()
for arch in amd64 arm64; do
    staging="$repository:build-$run_id-$arch"
    docker image tag "hyperion-release:$arch" "$staging"
    docker image push --platform "linux/$arch" "$staging"
    sources+=("$staging")
done

# The staging pushes also create the package on its first release.
if inspection=$(docker buildx imagetools inspect "$target" 2>&1); then
    printf 'Release tag %s already exists. Use a new revision.\n' "$target" >&2
    exit 1
fi
if [[ "$inspection" != "ERROR: $target: not found" ]]; then
    printf 'Could not check the release tag.\n%s\n' "$inspection" >&2
    exit 1
fi

docker buildx imagetools create --tag "$target" "${sources[@]}"
docker buildx imagetools inspect "$target" --raw |
    jq -e '[.manifests[].platform | "\(.os)/\(.architecture)"] | sort == ["linux/amd64", "linux/arm64"]' >/dev/null
docker buildx imagetools inspect "$target"
