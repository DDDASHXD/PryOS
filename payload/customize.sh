#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID == 0 ]] || { echo 'Run inside the image build chroot.' >&2; exit 1; }
[[ -d /usr/share/initramfs-tools/scripts/casper || -f /usr/share/initramfs-tools/scripts/casper || -d /etc/casper.conf.d || -f /etc/casper.conf ]] || { echo 'No Casper live filesystem found; refusing host customization.' >&2; exit 1; }
[[ ${RECOVERY_BUILD:-} == cubic || ${RECOVERY_BUILD:-} == chroot ]] || { echo 'Inside Cubic only, run: RECOVERY_BUILD=cubic bash /tmp/payload/customize.sh'; exit 1; }
. /etc/os-release
arch=$(dpkg --print-architecture)
[[ $ID == ubuntu && $VERSION_ID == 24.04 && ( $arch == amd64 || $arch == arm64 ) ]] || { echo 'Requires Ubuntu 24.04 amd64 or arm64 live root.' >&2; exit 1; }
src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y universe
apt-get update
apt-get install -y gparted testdisk smartmontools ntfs-3g efibootmgr chntpw \
  gddrescue nvme-cli hdparm gdisk parted dosfstools exfatprogs e2fsprogs \
  btrfs-progs xfsprogs cryptsetup dislocker partclone rsync p7zip-full unzip \
  git python3 curl ca-certificates jq ripgrep pciutils usbutils lshw \
  iproute2 iputils-ping dnsutils traceroute netcat-openbsd less nano \
  bubblewrap apparmor-profiles apparmor-utils

# Ubuntu 24.04 needs its packaged bubblewrap user-namespace profile for Codex.
# Install it in the image; do not load policies into the WSL build host's kernel.
if [[ ! -f /etc/apparmor.d/bwrap-userns-restrict ]]; then
  install -m 0644 /usr/share/apparmor/extra-profiles/bwrap-userns-restrict /etc/apparmor.d/bwrap-userns-restrict
fi

# Keep the installer out of a shell pipeline so download failures abort the build.
curl --fail --show-error --silent --location https://chatgpt.com/codex/install.sh -o /tmp/install-codex.sh
# Preserve the complete standalone installation, including companion binaries.
# Only installation uses this CODEX_HOME; runtime uses the live user's home.
HOME=/root CODEX_HOME=/opt/codex CODEX_INSTALL_DIR=/usr/local/bin CODEX_NON_INTERACTIVE=1 sh /tmp/install-codex.sh
chmod -R a+rX /opt/codex
[[ -x /usr/local/bin/codex ]] || { echo 'Codex installation failed.' >&2; exit 1; }
codex --version

install -d /opt/recovery/custom /etc/skel/Recovery /etc/skel/.codex /usr/local/bin /usr/share/applications
install -m 0644 "$src/codex-config.toml" /etc/skel/.codex/config.toml
# Never generate an image from a build root that has already been signed in.
if find /root /etc/skel /home -type f \( -path '*/.codex/auth.json' -o -path '*/.ssh/id_*' \) -print -quit | grep -q .; then
  echo 'Credentials found in image home directories; remove them before generating an ISO.' >&2; exit 1
fi
install -m 0644 "$src/AGENTS.md" /etc/skel/Recovery/AGENTS.md
install -m 0644 "$src/AGENTS.md" /opt/recovery/AGENTS.md
install -m 0644 "$src/START-HERE.txt" /etc/skel/Recovery/START-HERE.txt
for tool in "$src"/bin/*; do install -m 0755 "$tool" /usr/local/bin/; done
if [[ -d $src/custom ]]; then
  if find "$src/custom" -type f \( -name auth.json -o -name .env -o -name '*.pem' -o -name id_rsa -o -name id_ed25519 \) -print -quit | grep -q .; then
    echo 'Possible credentials in custom folder; remove before building.' >&2; exit 1
  fi
  cp -a "$src/custom/." /opt/recovery/custom/
fi
printf '%s\n' 'export PATH="/opt/recovery/custom:$PATH"' > /etc/profile.d/recovery-tools.sh
install -d /etc/dconf/db/local.d /etc/dconf/profile
if [[ ! -f /etc/dconf/profile/user ]]; then printf 'user-db:user\nsystem-db:local\n' > /etc/dconf/profile/user; fi
grep -qxF 'system-db:local' /etc/dconf/profile/user || echo 'system-db:local' >> /etc/dconf/profile/user
cat > /etc/dconf/db/local.d/00-recovery <<'EOF'
[org/gnome/desktop/media-handling]
automount=false
automount-open=false
EOF
dconf update
cat > /usr/share/applications/recovery-codex.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Recovery Codex
Comment=Sign in and inspect this machine with Codex
Exec=/usr/local/bin/recovery-codex
Icon=utilities-terminal
Terminal=true
Categories=System;Utility;
EOF
bash "$src/xfce-setup.sh"
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  cat /etc/os-release
  codex --version
  dpkg-query -W
} > /opt/recovery/build-info.txt
rm -f /tmp/install-codex.sh
apt-get clean
echo 'Customization complete. The image builder must configure nopersistent boot entries and generate the ISO; boot-test before relying on it.'
