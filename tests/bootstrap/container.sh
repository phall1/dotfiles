#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
platform="${1:-linux/arm64}"
profile="${2:-container}"
case "$platform" in linux/arm64|linux/amd64) ;; *) echo 'Use linux/arm64 or linux/amd64' >&2; exit 1 ;; esac
case "$profile" in container|container,pi) ;; *) echo 'Use container or container,pi' >&2; exit 1 ;; esac
tag="dotfiles-bootstrap:${platform#linux/}"
docker build --platform "$platform" -f "$root/tests/bootstrap/Dockerfile" -t "$tag" "$root"
[[ "$(docker image inspect "$tag" --format '{{.Architecture}}')" == "${platform#linux/}" ]]
image="$(docker image inspect "$tag" --format '{{.Id}}')"
docker run --rm --platform "$platform" -e MISE_ENV="$profile" "$image"
