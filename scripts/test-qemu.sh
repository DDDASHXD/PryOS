#!/usr/bin/env bash
set -euo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ -n ${1:-} ]]; then
  iso=$1
elif [[ $(uname -m) == arm64 || $(uname -m) == aarch64 ]] && [[ -f $project/out/pryos-arm64.iso ]]; then
  iso=$project/out/pryos-arm64.iso
else
  iso=$project/out/pryos-amd64.iso
fi
[[ -f $iso ]] || { echo "No ISO at $iso" >&2; exit 1; }

if [[ $iso == *arm64* ]]; then
  firmware=''
  for candidate in \
    /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
    /usr/local/share/qemu/edk2-aarch64-code.fd \
    /usr/share/qemu/edk2-aarch64-code.fd \
    /usr/share/AAVMF/AAVMF_CODE.fd
  do
    if [[ -f $candidate ]]; then firmware=$candidate; break; fi
  done
  [[ -n $firmware ]] || { echo 'Install QEMU. The arm64 ISO needs AAVMF firmware (edk2-aarch64-code.fd).' >&2; exit 1; }
  accel=tcg
  cpu=max
  case $(uname -s)-$(uname -m) in
    Darwin-arm64) accel=hvf; cpu=host ;;
    Linux-aarch64) [[ ! -r /dev/kvm ]] || { accel=kvm; cpu=host; } ;;
  esac
  exec qemu-system-aarch64 -machine "virt,accel=${accel}" -cpu "$cpu" -m 4096 -smp 2 \
    -drive if=pflash,format=raw,readonly=on,file="$firmware" \
    -cdrom "$iso" \
    -device virtio-gpu-pci \
    -device qemu-xhci -device usb-kbd -device usb-tablet \
    -nic user,model=virtio-net-pci
fi

accel=tcg
case $(uname -s) in
  Linux) [[ ! -r /dev/kvm ]] || accel=kvm ;;
  Darwin) [[ $(uname -m) != x86_64 ]] || accel=hvf ;;
esac
exec qemu-system-x86_64 -accel "$accel" -m 4096 -smp 2 -boot d -cdrom "$iso" -nic user,model=e1000
