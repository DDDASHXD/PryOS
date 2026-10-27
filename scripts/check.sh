#!/usr/bin/env bash
set -euo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project"
python_cmd=python3
command -v "$python_cmd" >/dev/null || python_cmd=python
"$python_cmd" -m unittest discover -s tests -v
shell_files=()
while IFS= read -r -d '' filename; do
  case $filename in
    *.sh|payload/bin/*) bash -n "$filename"; shell_files+=("$filename");;
  esac
done < <(git ls-files -z --cached --others --exclude-standard)
# Dynamic config sources and literal code for guest shells/dpkg are intentional.
if command -v shellcheck >/dev/null; then shellcheck -x -e SC1090,SC1091,SC2016 "${shell_files[@]}"; fi
echo 'PryOS source checks passed'
