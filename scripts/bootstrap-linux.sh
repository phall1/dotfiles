#!/usr/bin/env bash
set -euo pipefail
command -v apt-get >/dev/null || { echo 'This entrypoint requires Debian/Ubuntu.' >&2; exit 1; }
sudo apt-get update
sudo apt-get install -y ca-certificates curl git xz-utils unzip
version="$(git --version | awk '{print $3}')"
dpkg --compare-versions "$version" ge 2.45.1 || {
  echo 'Git >=2.45.1 is required by Phig. Use Debian 13 / Raspberry Pi OS Trixie (64-bit), or provision a supported Git first.' >&2
  exit 1
}
exec bash "$(dirname "${BASH_SOURCE[0]}")/bootstrap.sh" "$@"
