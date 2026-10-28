#!/usr/bin/env bash
# Structural and installed-tool checks; physical boot tests remain separate.
set -Eeuo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $EUID == 0 && $(uname -s) == Linux ]] || { echo 'Run with sudo inside the Linux builder.' >&2; exit 1; }
if [[ ${PRYOS_VERIFY_NAMESPACE:-} != private ]]; then
  exec unshare --mount --propagation private env PRYOS_VERIFY_NAMESPACE=private bash "$0" "$@"
fi
work=$(realpath -m -- "${PRYOS_WORK_DIR:-/var/tmp/pryos-build}")
output=$(realpath -m -- "${PRYOS_OUTPUT_DIR:-$project/out}")
arch=$(dpkg --print-architecture)
iso=${1:-$output/pryos-${arch}.iso}
root="$work/root"
mounted="$work/verify-mount"
[[ -f $iso && -f $root/etc/casper.conf ]] || { echo 'Build first, and use the matching PRYOS_WORK_DIR.' >&2; exit 1; }
mkdir -p "$output" "$mounted"
exec > >(tee "$output/verification.txt") 2>&1
cleanup() {
  cd /
  if mountpoint -q "$root/proc"; then umount "$root/proc"; fi
  if mountpoint -q "$mounted"; then umount "$mounted"; fi
}
trap cleanup EXIT
echo 'PryOS structural verification (not a boot test)'
date -u --iso-8601=seconds
xorriso -indev "$iso" -report_el_torito plain -report_system_area plain
mount -t iso9660 -o loop,ro "$iso" "$mounted"
cd "$mounted"
md5sum -c --quiet md5sum.txt
echo 'ISO checksums passed'
[[ $(grep -c 'linux .*nopersistent' boot/grub/grub.cfg) == 3 ]]
grep -q 'hostname=pryos' boot/grub/grub.cfg
grep -q 'iso-scan/filename=${iso_path}' boot/grub/loopback.cfg
[[ $(find casper -maxdepth 1 -name '*.squashfs' | wc -l) == 1 ]]
[[ ! -d pool && ! -d dists ]]
unsquashfs -s casper/recovery.squashfs
for rel in etc/skel/.codex/config.toml etc/skel/Recovery/AGENTS.md usr/local/bin/recovery-codex usr/local/bin/pryos-browser etc/systemd/system/recovery-live-setup.service etc/pam.d/recovery-autologin; do
  unsquashfs -cat casper/recovery.squashfs "$rel" | cmp "$root/$rel" -
done
mount -t proc proc "$root/proc"
chroot "$root" /usr/bin/env -u OPENAI_API_KEY CODEX_HOME=/etc/skel/.codex DISABLE_AUTOUPDATER=1 /bin/bash -c '
set -e
for tool in codex claude gemini opencode gparted testdisk photorec smartctl ntfs-3g efibootmgr chntpw ddrescue nvme dislocker startxfce4 lightdm pryos-browser; do command -v "$tool"; done
codex --version
claude --version
gemini --version
opencode --version
/usr/bin/helium --version
if status=$(codex login status 2>&1); then echo "Unexpected signed-in Codex"; exit 1; fi
printf "%s\n" "$status"
grep -q "Not logged in" <<< "$status"
visudo -cf /etc/sudoers.d/99-recovery
desktop-file-validate /etc/skel/Desktop/*.desktop
id pryos-browser
'
if find "$root/root" "$root/home" "$root/etc/skel" "$root/opt" -type f -name auth.json -print -quit | grep -q .; then echo 'Unexpected auth.json in image'; exit 1; fi
[[ $(find "$root/etc/skel/Desktop" -name '*.desktop' | wc -l) -ge 20 ]]
[[ $(find "$root/etc/skel/Desktop" -name '*.desktop' ! -perm -111 | wc -l) == 0 ]]
grep -q 'metadata::xfce-exe-checksum' "$root/usr/local/bin/recovery-trust-launchers"
! grep -q 'name="panel-2"' "$root/etc/xdg/xfce4/panel/default.xml"
! grep -q 'name="panel-2"' "$root/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
[[ ! -d $root/var/lib/snapd/snaps ]]
grep -q 'pryos-browser.desktop' "$root/etc/skel/.config/mimeapps.list"
grep -q 'PryOS' "$root/etc/os-release"
cmp "$work/iso/casper/vmlinuz" casper/vmlinuz
cmp "$work/iso/casper/initrd" casper/initrd
echo 'PryOS structural and tool checks passed. Run BIOS/UEFI/VM/Ventoy/reboot tests separately.'
