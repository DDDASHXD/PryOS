#!/usr/bin/env bash
set -euo pipefail
[[ $(uname -s) == Linux ]] || { echo 'Run this inside Linux, WSL2, or the macOS Linux builder VM.' >&2; exit 1; }
[[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
apt-get update
apt-get install -y --no-install-recommends squashfs-tools xorriso rsync curl ca-certificates python3 util-linux
if [[ ${1:-} == --test-tools ]]; then apt-get install -y qemu-system-x86 ovmf shellcheck; fi
