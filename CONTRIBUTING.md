# Contributing

1. Fork the repo and make a branch.
2. Linux build steps belong in `scripts/build-linux.sh`. Image contents belong in `payload/`. Defaults belong in `config/build.env`.
3. Run `python3 -m unittest discover -s tests -v` and `bash scripts/check.sh`. Rebuild the ISO if you change packages, login, or the desktop.
4. In the pull request, say what changed and how you checked it. Include the builder OS, whether the image was amd64 or arm64, and whether you booted it.

Keep ISOs, virtual disks, credentials, and recovered files out of git. `payload/custom/` is installed on the image, so only put public scripts there.

New packages need an upstream and a reason to be on a recovery image. Disk tools should name the target and wait for a person before they write. Windows mounts stay read-only by default.

Project code is MIT. Other software is covered in [THIRD_PARTY.md](THIRD_PARTY.md).
