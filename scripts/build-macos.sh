#!/usr/bin/env bash
set -euo pipefail
[[ $(uname -s) == Darwin ]] || { echo 'Use build-iso.sh directly on Linux, or scripts/build.ps1 on Windows.' >&2; exit 1; }
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
vm=${PRYOS_LIMA_INSTANCE:-pryos-builder}
for executable in limactl python3 git; do command -v "$executable" >/dev/null || { echo 'Install tools with: brew install lima qemu lima-additional-guestagents python' >&2; exit 1; }; done
if ! limactl list --format '{{.Name}}' | grep -qxF "$vm"; then
  limactl start --name="$vm" "$project/scripts/pryos-builder.yaml"
else
  limactl start "$vm"
fi
# Copy only Git-visible source, including uncommitted edits; no host-home mount is exposed.
python3 "$project/tools/export-source.py" "$project" | limactl shell "$vm" sh -c 'rm -rf -- "$HOME/pryos-src"; mkdir -p "$HOME/pryos-src"; tar -xf - -C "$HOME/pryos-src"'
remote=$(limactl shell "$vm" sh -c 'printf "%s" "$HOME/pryos-src"')
if [[ -f $project/config/local.env ]]; then limactl copy "$project/config/local.env" "$vm:$remote/config/local.env"; fi
limactl shell "$vm" sudo bash "$remote/scripts/setup-linux.sh"
limactl shell "$vm" sudo env PRYOS_OUTPUT_DIR=/var/tmp/pryos-out PRYOS_FORCE="${PRYOS_FORCE:-0}" PRYOS_REFRESH="${PRYOS_REFRESH:-0}" bash "$remote/build-iso.sh"
mkdir -p "$project/out"
for filename in pryos-amd64.iso pryos-amd64.iso.sha256 build-info.txt ai-versions.txt build.log; do
  limactl copy "$vm:/var/tmp/pryos-out/$filename" "$project/out/$filename"
done
(cd "$project/out" && shasum -a 256 -c pryos-amd64.iso.sha256)
