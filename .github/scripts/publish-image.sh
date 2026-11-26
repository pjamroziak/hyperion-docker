#!/usr/bin/env bash
set -euo pipefail

target=$1
archive=$2
run_id=$3
repository=${target%:*}

source=hyperion-release:amd64
docker image load --input "$archive"
platform=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$source")
if [[ "$platform" != linux/amd64 ]]; then
    printf 'Expected a linux/amd64 image, found %s.\n' "$platform" >&2
    exit 1
fi

# The staging push also creates the package on its first release.
staging="$repository:build-$run_id"
docker image tag "$source" "$staging"
docker image push --platform linux/amd64 "$staging"

if inspection=$(docker buildx imagetools inspect "$target" 2>&1); then
    printf 'Release tag %s already exists. Use a new revision.\n' "$target" >&2
    exit 1
fi
if [[ "$inspection" != "ERROR: $target: not found" ]]; then
    printf 'Could not check the release tag.\n%s\n' "$inspection" >&2
    exit 1
fi

docker buildx imagetools create --prefer-index=false --tag "$target" "$staging"
test "$(docker buildx imagetools inspect "$target" --raw)" = "$(docker buildx imagetools inspect "$staging" --raw)"
docker buildx imagetools inspect "$target"
