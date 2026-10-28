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
  command -v qemu-img >/dev/null || { echo 'Install QEMU. qemu-img is required for the test disk.' >&2; exit 1; }
  accel=tcg
  cpu=max
  case $(uname -s)-$(uname -m) in
    Darwin-arm64) accel=hvf; cpu=host ;;
    Linux-aarch64) [[ ! -r /dev/kvm ]] || { accel=kvm; cpu=host; } ;;
  esac
  vm="$project/vm-test"
  mkdir -p "$vm"
  [[ -f $vm/edk2-vars.fd ]] || truncate -s 64M "$vm/edk2-vars.fd"
  [[ -f $vm/disposable.qcow2 ]] || qemu-img create -f qcow2 "$vm/disposable.qcow2" 16G
  exec qemu-system-aarch64 -name PryOS -machine "virt,accel=${accel}" -cpu "$cpu" -m 4096 -smp 2 \
    -drive if=pflash,unit=0,format=raw,readonly=on,file="$firmware" \
    -drive if=pflash,unit=1,format=raw,file="$vm/edk2-vars.fd" \
    -device virtio-gpu-pci \
    -display default,show-cursor=on \
    -device qemu-xhci,id=xhci \
    -device usb-kbd,bus=xhci.0 \
    -device usb-tablet,bus=xhci.0 \
    -drive if=none,id=cdrom,media=cdrom,readonly=on,file="$iso" \
    -device usb-storage,bus=xhci.0,drive=cdrom \
    -drive if=virtio,file="$vm/disposable.qcow2",discard=unmap \
    -nic user,model=virtio-net-pci
fi

accel=tcg
case $(uname -s) in
  Linux) [[ ! -r /dev/kvm ]] || accel=kvm ;;
  Darwin) [[ $(uname -m) != x86_64 ]] || accel=hvf ;;
esac
exec qemu-system-x86_64 -accel "$accel" -m 4096 -smp 2 -boot d -cdrom "$iso" -nic user,model=e1000
