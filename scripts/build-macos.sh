#!/usr/bin/env bash
set -euo pipefail
[[ $(uname -s) == Darwin ]] || { echo 'Use build-iso.sh directly on Linux, or scripts/build.ps1 on Windows.' >&2; exit 1; }
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
host=$(uname -m)
requested=${1:-${PRYOS_ARCH:-}}
case $requested in
  '') if [[ $host == arm64 ]]; then arch=arm64; else arch=amd64; fi ;;
  amd64|arm64) arch=$requested ;;
  *) echo 'Use: bash scripts/build-macos.sh amd64' >&2; echo '     bash scripts/build-macos.sh arm64' >&2; exit 1 ;;
esac
case $arch in
  arm64)
    [[ $host == arm64 ]] || { echo 'The arm64 image needs an Apple Silicon Mac, or an arm64 Ubuntu machine running build-iso.sh.' >&2; exit 1; }
    yaml="$project/scripts/pryos-builder-arm64.yaml"
    default_vm=pryos-builder-arm64
    ;;
  amd64)
    yaml="$project/scripts/pryos-builder.yaml"
    default_vm=pryos-builder
    ;;
esac
vm=${PRYOS_LIMA_INSTANCE:-$default_vm}
echo "Building out/pryos-${arch}.iso in ${vm}"
for executable in limactl python3 git; do command -v "$executable" >/dev/null || { echo 'Install tools with: brew install lima qemu lima-additional-guestagents python' >&2; exit 1; }; done
if ! limactl list --format '{{.Name}}' | grep -qxF "$vm"; then
  limactl start --name="$vm" "$yaml"
else
  limactl start "$vm"
fi
# Copy only Git-visible source, including uncommitted edits; no host-home mount is exposed.
python3 "$project/tools/export-source.py" "$project" | limactl shell "$vm" sh -c 'rm -rf -- "$HOME/pryos-src"; mkdir -p "$HOME/pryos-src"; tar -xf - -C "$HOME/pryos-src"'
remote=$(limactl shell "$vm" sh -c 'printf "%s" "$HOME/pryos-src"')
if [[ -f $project/config/local.env ]]; then limactl copy "$project/config/local.env" "$vm:$remote/config/local.env"; fi
limactl shell "$vm" sudo bash "$remote/scripts/setup-linux.sh"
limactl shell "$vm" sudo env PRYOS_ARCH="$arch" PRYOS_OUTPUT_DIR=/var/tmp/pryos-out PRYOS_FORCE="${PRYOS_FORCE:-0}" PRYOS_REFRESH="${PRYOS_REFRESH:-0}" bash "$remote/build-iso.sh"
mkdir -p "$project/out"
iso="pryos-${arch}.iso"
for filename in "$iso" "${iso}.sha256" build-info.txt ai-versions.txt build.log; do
  limactl copy "$vm:/var/tmp/pryos-out/$filename" "$project/out/$filename"
done
(cd "$project/out" && shasum -a 256 -c "${iso}.sha256")
