#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID == 0 && ${RECOVERY_BUILD:-} == chroot || $EUID == 0 && ${RECOVERY_BUILD:-} == cubic ]] || exit 1
src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export DEBIAN_FRONTEND=noninteractive
echo 'lightdm shared/default-x-display-manager select lightdm' | debconf-set-selections
apt-get install -y --no-install-recommends xfce4 xfce4-terminal xfce4-whiskermenu-plugin lightdm lightdm-gtk-greeter \
  network-manager-gnome thunar-volman gvfs gvfs-backends xdg-user-dirs xdg-utils \
  zenity gsmartcontrol mousepad dbus-x11 desktop-file-utils gnupg xz-utils x11-xserver-utils

# Remove the installer and its Snap infrastructure rather than hiding one launcher.
remove=()
for package in ubuntu-desktop ubuntu-desktop-minimal gdm3 gnome-shell gnome-session gnome-session-bin ubuntu-session firefox snapd ubuntu-desktop-bootstrap ubuntu-desktop-installer; do
  if dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null | grep -qx installed; then remove+=("$package"); fi
done
if ((${#remove[@]})); then apt-get purge -y "${remove[@]}"; fi
# Only image-local Snap data; no host mounts point here.
rm -rf /var/lib/snapd /var/snap /snap
find /etc/xdg -type f -name '*.desktop' -print0 | while IFS= read -r -d '' entry; do
  if grep -qiE 'ubuntu-desktop-bootstrap|ubuntu-desktop-installer|snap-userd' "$entry"; then rm -f "$entry"; fi
done

# Helium's signing key is checked into this source tree for reviewable trust changes.
rm -f /etc/apt/sources.list.d/mozilla.list /etc/apt/preferences.d/mozilla /etc/apt/keyrings/packages.mozilla.org.asc
fingerprint=$(gpg --batch --show-keys --with-colons "$src/keys/helium.asc" | awk -F: '$1=="fpr" {print $10; exit}')
[[ $fingerprint == BE677C1989D35EAB2C5F26C9351601AD01D6378E ]] || { echo 'Unexpected Helium signing key' >&2; exit 1; }
gpg --batch --yes --dearmor -o /usr/share/keyrings/helium.gpg "$src/keys/helium.asc"
echo 'deb [signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main' > /etc/apt/sources.list.d/helium.list
apt-get update
apt-get install -y --no-install-recommends helium-bin
ln -sfn /usr/local/bin/pryos-browser /usr/local/bin/helium
install -d /usr/local/share/applications
while IFS= read -r desktop; do
  [[ $desktop == /usr/share/applications/*.desktop ]] || continue
  sed -E 's@^Exec=[^ ]+@Exec=/usr/local/bin/pryos-browser@' "$desktop" > "/usr/local/share/applications/$(basename "$desktop")"
done < <(dpkg-query -L helium-bin)
if ! id pryos-browser >/dev/null 2>&1; then useradd --create-home --shell /usr/sbin/nologin pryos-browser; fi
passwd -l pryos-browser
update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/pryos-browser 200
update-alternatives --set x-www-browser /usr/local/bin/pryos-browser

# Official Node runtime, with published SHA-256 verification.
if [[ ! -x /opt/recovery-node/bin/node ]]; then
  curl -fsSL --retry 4 https://nodejs.org/dist/index.json -o /tmp/node-index.json
  version=$(python3 -c 'import json; print(next(x["version"] for x in json.load(open("/tmp/node-index.json")) if x["version"].startswith("v22.")))')
  case $(dpkg --print-architecture) in
    amd64) node_target=linux-x64 ;;
    arm64) node_target=linux-arm64 ;;
    *) echo 'No Node.js build for this architecture.' >&2; exit 1 ;;
  esac
  archive="node-$version-$node_target.tar.xz"
  curl -fsSL --retry 4 "https://nodejs.org/dist/$version/$archive" -o "/tmp/$archive"
  curl -fsSL --retry 4 "https://nodejs.org/dist/$version/SHASUMS256.txt" -o /tmp/node-shasums
  (cd /tmp && grep "  $archive\$" node-shasums | sha256sum -c -)
  mkdir -p /opt/recovery-node
  tar -xJf "/tmp/$archive" -C /opt/recovery-node --strip-components=1
  rm -f "/tmp/$archive" /tmp/node-shasums /tmp/node-index.json
fi
for executable in node npm npx; do ln -sfn "/opt/recovery-node/bin/$executable" "/usr/local/bin/$executable"; done
npm install --global --prefix /opt/recovery-ai --no-fund --no-audit @google/gemini-cli opencode-ai
for executable in gemini opencode; do ln -sfn "/opt/recovery-ai/bin/$executable" "/usr/local/bin/$executable"; done
curl -fsSL --retry 4 https://claude.ai/install.sh -o /tmp/install-claude.sh
HOME=/opt/claude bash /tmp/install-claude.sh stable
ln -sfn "$(readlink -f /opt/claude/.local/bin/claude)" /usr/local/bin/claude
chmod -R a+rX /opt/claude /opt/recovery-node /opt/recovery-ai
printf 'export DISABLE_AUTOUPDATER=1\nexport PATH="/opt/recovery/custom:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"\n' > /etc/profile.d/recovery-ai.sh
claude --version
gemini --version
opencode --version

install -d /etc/sudoers.d /etc/skel/Desktop /etc/skel/.config/autostart /etc/skel/Recovery
printf 'root ALL=(ALL:ALL) NOPASSWD: ALL\n%%sudo ALL=(ALL:ALL) NOPASSWD: ALL\nubuntu ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/99-recovery
chmod 0440 /etc/sudoers.d/99-recovery
visudo -cf /etc/sudoers.d/99-recovery
passwd -d root
cat > /etc/pam.d/recovery-autologin <<'EOF'
# Local live-console autologin only; no remote login service is enabled.
auth required pam_permit.so
account required pam_permit.so
session required pam_unix.so
session required pam_env.so
session optional pam_systemd.so
EOF
cat > /etc/systemd/system/recovery-live-setup.service <<'EOF'
[Unit]
Description=Configure the root XFCE recovery desktop after Casper
After=local-fs.target
Before=display-manager.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/recovery-live-setup
RemainAfterExit=yes
[Install]
WantedBy=graphical.target
EOF
systemctl enable recovery-live-setup.service
systemctl enable --force lightdm.service
systemctl set-default graphical.target
ln -sfn /usr/lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
echo /usr/sbin/lightdm > /etc/X11/default-display-manager
printf '#!/bin/sh\nexec startxfce4\n' > /etc/skel/.xsession
printf 'export PATH="/opt/recovery/custom:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"\nexport BROWSER=pryos-browser\n' > /etc/skel/.xsessionrc
chmod +x /etc/skel/.xsession
cat > /etc/skel/.config/autostart/recovery-desktop.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=PryOS desktop setup
Exec=recovery-desktop-init
OnlyShowIn=XFCE;
EOF
cp "$src/AGENTS.md" /etc/skel/Recovery/CLAUDE.md
cp "$src/AGENTS.md" /etc/skel/Recovery/GEMINI.md

python3 "$src/make-desktop.py"
install -d /root/Desktop
cp -a /etc/skel/Desktop/. /root/Desktop/
install -d /root/.codex
cp "$src/codex-config.toml" /root/.codex/config.toml
install -d /usr/share/backgrounds
install -m 0644 "$src/pryos.svg" /usr/share/backgrounds/pryos.svg
printf '[Added Associations]\nx-scheme-handler/http=pryos-browser.desktop;\nx-scheme-handler/https=pryos-browser.desktop;\ntext/html=pryos-browser.desktop;\n[Default Applications]\nx-scheme-handler/http=pryos-browser.desktop\nx-scheme-handler/https=pryos-browser.desktop\ntext/html=pryos-browser.desktop\n' > /etc/skel/.config/mimeapps.list
cat > /usr/share/applications/pryos-browser.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Helium
Exec=pryos-browser %U
Icon=helium
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
EOF
install -d /etc/skel/.local/share/xfce4/helpers
cat > /etc/skel/.local/share/xfce4/helpers/pryos-helium.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=X-XFCE-Helper
Name=Helium
Icon=helium
X-XFCE-Category=WebBrowser
X-XFCE-Commands=pryos-browser;
X-XFCE-CommandsWithParameter=pryos-browser "%s";
EOF
printf 'WebBrowser=pryos-helium\nTerminalEmulator=xfce4-terminal\nFileManager=Thunar\n' > /etc/skel/.config/xfce4/helpers.rc
sed -i '/^IMAGE_ID=/d; /^IMAGE_VERSION=/d; s/^NAME=.*/NAME="PryOS"/; s/^PRETTY_NAME=.*/PRETTY_NAME="PryOS Recovery"/' /etc/os-release
printf '\nIMAGE_ID=pryos\nIMAGE_VERSION=%s\n' "${PRYOS_VERSION:-0.1.0}" >> /etc/os-release
printf 'PryOS Recovery \\n \\l\n' > /etc/issue
printf 'PryOS Recovery\n' > /etc/issue.net
printf 'PryOS — temporary root recovery desktop. Attached-disk changes remain permanent.\n' > /etc/motd
apt-get clean
npm cache clean --force
rm -f /tmp/install-claude.sh
