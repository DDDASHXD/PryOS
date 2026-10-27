#!/usr/bin/env bash
# Linux-only implementation; Windows and macOS wrappers enter a Linux environment.
set -Eeuo pipefail
export LC_ALL=C
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ $(uname -s) == Linux && $EUID == 0 ]] || { echo 'Run with sudo inside an amd64 Linux environment.' >&2; exit 1; }
[[ $(dpkg --print-architecture) == amd64 ]] || { echo 'The recovery image currently targets amd64. On Apple Silicon use the x86_64 Lima VM.' >&2; exit 1; }
if [[ ${PRYOS_MOUNT_NAMESPACE:-} != private ]]; then
  exec unshare --mount --propagation private env PRYOS_MOUNT_NAMESPACE=private bash "$project/scripts/build-linux.sh" "$@"
fi
# Source files are executable configuration: review local overrides before building.
source "$project/config/build.env"
if [[ -f $project/config/local.env ]]; then source "$project/config/local.env"; fi
export PRYOS_VERSION
work=$(realpath -m -- "${PRYOS_WORK_DIR:-/var/tmp/pryos-build}")
output=$(realpath -m -- "${PRYOS_OUTPUT_DIR:-$project/out}")
[[ $work != / && $work != /root && $work != /home && $work != "$project" ]] || { echo 'Choose a dedicated build working directory.' >&2; exit 1; }
mkdir -p "$work" "$output"
case $(findmnt -n -o FSTYPE --target "$work") in
  9p|drvfs|virtiofs|cifs|fuse.*) echo 'Working directory must be on a Linux filesystem, not a host share.' >&2; exit 1;;
esac
for executable in xorriso mksquashfs rsync curl python3 mount unshare; do command -v "$executable" >/dev/null || { echo 'Install builder dependencies using scripts/setup-linux.sh.' >&2; exit 1; }; done
out="$output/pryos-amd64.iso"
if [[ -e $out && ${PRYOS_FORCE:-0} != 1 ]]; then echo "Output exists: $out. Move it aside or set PRYOS_FORCE=1 to replace it atomically." >&2; exit 1; fi
exec > >(tee -a "$output/build.log") 2>&1
trap 'echo "Build failed near line $LINENO. See the build log." >&2' ERR
root="$work/root"
tree="$work/iso"
casper="$work/pryos-casper"
iso="$work/base.iso"
mounted=0
cleanup_chroot() {
  if [[ $mounted == 1 ]]; then
    for directory in run sys proc dev; do
      if mountpoint -q "$root/$directory"; then umount -R "$root/$directory" || true; fi
    done
    rm -f "$root/etc/resolv.conf" "$root/usr/sbin/policy-rc.d"
    if [[ -f $work/control/resolv.conf || -L $work/control/resolv.conf ]]; then cp -a "$work/control/resolv.conf" "$root/etc/resolv.conf"; fi
    if [[ -f $work/control/policy-rc.d ]]; then cp -a "$work/control/policy-rc.d" "$root/usr/sbin/policy-rc.d"; fi
    mounted=0
  fi
}
trap cleanup_chroot EXIT
echo "PryOS $PRYOS_VERSION build started $(date -u --iso-8601=seconds)"
if [[ -f $work/source.sha256 && $(cat "$work/source.sha256") != "$BASE_ISO_SHA256" ]]; then
  echo 'The source ISO configuration changed. Use a fresh PRYOS_WORK_DIR.' >&2; exit 1
fi
if [[ ! -f $work/source.sha256 ]]; then
  if [[ ! -f $iso ]]; then
    candidate=${PRYOS_SOURCE_ISO:-$project/downloads/$BASE_ISO_NAME}
    if [[ -f $candidate ]]; then
      python3 "$project/tools/copy-image.py" "$candidate" "$iso"
    else
      curl -fL --retry 4 "$BASE_ISO_URL" -o "$iso.partial"
      mv "$iso.partial" "$iso"
    fi
  fi
  python3 "$project/tools/hash-image.py" "$iso" "$BASE_ISO_SHA256"
  printf '%s\n' "$BASE_ISO_SHA256" > "$work/source.sha256"
fi
if [[ ! -f $work/extracted.ok ]]; then
  mkdir -p "$tree"
  xorriso -osirrox on -indev "$iso" -extract / "$tree"
  touch "$work/extracted.ok"
fi
if [[ ! -f $work/root.ok ]]; then
  lowerdirs=''
  for name in minimal minimal.standard minimal.standard.live; do
    mkdir -p "$work/layers/$name"
    mount -t squashfs -o loop,ro "$tree/casper/$name.squashfs" "$work/layers/$name"
    lowerdirs="$work/layers/$name${lowerdirs:+:$lowerdirs}"
  done
  mkdir -p "$work/merged" "$root"
  mount -t overlay overlay -o "lowerdir=$lowerdirs" "$work/merged"
  rsync -aHAX --numeric-ids "$work/merged/" "$root/"
  umount "$work/merged"
  for name in minimal.standard.live minimal.standard minimal; do umount "$work/layers/$name"; done
  touch "$work/root.ok"
fi
fingerprint=$(python3 "$project/tools/fingerprint.py" "$project/payload" "$project/config/build.env" "$project/scripts/build-linux.sh")
fingerprint="$fingerprint-$PRYOS_VERSION-$BASE_ISO_SHA256"
rebuilt=0
if [[ ${PRYOS_REFRESH:-0} == 1 || ! -f $work/customized.fingerprint || $(cat "$work/customized.fingerprint") != "$fingerprint" ]]; then
  mkdir -p "$root/tmp/payload" "$work/control"
  # Replace only this builder-owned payload staging directory to avoid stale custom tools.
  rsync -a --delete "$project/payload/" "$root/tmp/payload/"
  sed -i 's/\r$//' "$root/tmp/payload/"*.sh "$root/tmp/payload/bin/"*
  rm -f "$work/control/resolv.conf" "$work/control/policy-rc.d"
  if [[ -e $root/etc/resolv.conf || -L $root/etc/resolv.conf ]]; then cp -a "$root/etc/resolv.conf" "$work/control/resolv.conf"; fi
  if [[ -f $root/usr/sbin/policy-rc.d ]]; then cp -a "$root/usr/sbin/policy-rc.d" "$work/control/policy-rc.d"; fi
  mounted=1
  mount --rbind /dev "$root/dev"
  mount --make-rslave "$root/dev"
  mount -t proc proc "$root/proc"
  mount --rbind /sys "$root/sys"
  mount --make-rslave "$root/sys"
  mount -t tmpfs tmpfs "$root/run"
  rm -f "$root/etc/resolv.conf"
  cp -L /etc/resolv.conf "$root/etc/resolv.conf"
  printf '#!/bin/sh\nexit 101\n' > "$root/usr/sbin/policy-rc.d"
  chmod +x "$root/usr/sbin/policy-rc.d"
  chroot "$root" /usr/bin/env RECOVERY_BUILD=chroot PRYOS_VERSION="$PRYOS_VERSION" bash /tmp/payload/customize.sh
  cleanup_chroot
  printf '%s\n' "$fingerprint" > "$work/customized.fingerprint"
  rebuilt=1
fi
packing="$fingerprint-zstd$PRYOS_COMPRESSION_LEVEL"
if [[ $rebuilt == 1 || ! -f $work/packed.fingerprint || $(cat "$work/packed.fingerprint") != "$packing" ]]; then
  [[ $root == "$work/root" && -f $root/etc/casper.conf ]] || { echo 'Unexpected image root; refusing cleanup.' >&2; exit 1; }
  rm -rf "$root/tmp/payload" "$root/var/lib/apt/lists/"*
  # Version/status probes create runtime aliases. Never seed those into an overlay live home.
  for home in "$root/root/.codex" "$root/etc/skel/.codex"; do
    if [[ -d $home ]]; then find "$home" -mindepth 1 -maxdepth 1 ! -name config.toml -exec rm -rf -- {} +; fi
  done
  rm -f "$root/root/.bash_history" "$root/var/lib/systemd/random-seed"
  : > "$root/etc/machine-id"
  rm -f "$root/var/lib/dbus/machine-id"
  ln -s /etc/machine-id "$root/var/lib/dbus/machine-id"
  find "$root/var/log" -type f -exec truncate -s 0 {} +
  mkdir -p "$casper"
  cp -a "$tree/casper/vmlinuz" "$tree/casper/initrd" "$casper/"
  rm -f "$casper/recovery.squashfs.partial"
  mksquashfs "$root" "$casper/recovery.squashfs.partial" -noappend -comp zstd -Xcompression-level "$PRYOS_COMPRESSION_LEVEL" -processors "$PRYOS_CPUS"
  mv "$casper/recovery.squashfs.partial" "$casper/recovery.squashfs"
  chroot "$root" dpkg-query -W --showformat='${Package} ${Version}\n' > "$casper/filesystem.manifest"
  du -sx --block-size=1 "$root" | cut -f1 > "$casper/filesystem.size"
  printf '%s\n' "$packing" > "$work/packed.fingerprint"
fi
cp "$root/opt/recovery/build-info.txt" "$output/build-info.txt"
cp "$root/opt/recovery/ai-versions.txt" "$output/ai-versions.txt"
python3 "$project/prepare-boot.py" "$tree" "$casper"
rm -f "$work/pryos-amd64.partial.iso"
xorriso -indev "$iso" -outdev "$work/pryos-amd64.partial.iso" -volid PRYOS \
  -rm_r /casper /pool /dists -- -map "$casper" /casper \
  -map "$tree/boot/grub/grub.cfg" /boot/grub/grub.cfg \
  -map "$tree/boot/grub/loopback.cfg" /boot/grub/loopback.cfg \
  -map "$tree/md5sum.txt" /md5sum.txt -map "$tree/.disk/info" /.disk/info \
  -boot_image any replay -commit -end
mv "$work/pryos-amd64.partial.iso" "$work/pryos-amd64.iso"
python3 "$project/tools/copy-image.py" "$work/pryos-amd64.iso" "$out.partial"
python3 "$project/tools/hash-image.py" "$out.partial" "$(python3 "$project/tools/hash-image.py" "$work/pryos-amd64.iso")"
mv -f "$out.partial" "$out"
python3 "$project/tools/hash-image.py" "$out" > "$out.sha256.tmp"
python3 - "$out" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
digest = Path(str(path) + '.sha256.tmp').read_text().strip()
Path(str(path) + '.sha256').write_text(f'{digest}  {path.name}\n')
Path(str(path) + '.sha256.tmp').unlink()
PY
echo "PryOS ISO built: $out"
