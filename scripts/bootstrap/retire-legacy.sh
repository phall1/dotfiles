#!/usr/bin/env bash
# Source removal alone leaves previously materialized files behind. Retire only
# exact known copies; a local edit must be reviewed rather than erased.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
checksum=(sha256sum)
if [[ "$(uname -s)" == Darwin ]]; then checksum=(shasum -a 256); fi
while read -r expected relative; do
  target="$HOME/$relative"
  [[ -e "$target" ]] || continue
  actual="$("${checksum[@]}" "$target" | awk '{print $1}')"
  if [[ -L "$target" || "$actual" != "$expected" ]]; then
    echo "Retired file has local changes; move it aside after review: $target" >&2
    exit 1
  fi
  rm "$target"
done < "$root/provision/retired-files.sha256"
