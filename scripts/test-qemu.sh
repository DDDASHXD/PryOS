#!/usr/bin/env bash
set -euo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
iso=${1:-$project/out/pryos-amd64.iso}
[[ -f $iso ]] || { echo "No ISO at $iso" >&2; exit 1; }
accel=tcg
case $(uname -s) in
  Linux) [[ ! -r /dev/kvm ]] || accel=kvm;;
  Darwin) [[ $(uname -m) != x86_64 ]] || accel=hvf;;
esac
exec qemu-system-x86_64 -accel "$accel" -m 4096 -smp 2 -boot d -cdrom "$iso" -nic user,model=e1000
