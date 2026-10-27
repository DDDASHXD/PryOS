# Contributing to PryOS

Contributions are welcome through issues and pull requests. Start with the [README](README.md), [build instructions](docs/BUILDING.md), and [configuration guide](docs/CONFIGURATION.md).

1. Fork and clone the repository; create a focused branch.
2. Keep platform wrappers thin: Linux image operations belong in `scripts/build-linux.sh`, image configuration in `payload/`, and defaults in `config/build.env`.
3. Run `python3 -m unittest discover -s tests -v` and `bash scripts/check.sh`. A full ISO rebuild is required for changes to image packages, autologin, browser launch, permissions or desktop behavior.
4. For a build change, include builder OS/architecture, relevant versions, checksums, BIOS/UEFI mode and boot-test results. Apple Silicon builds target amd64 under emulation; distinguish host architecture from image architecture.
5. Open a pull request describing the concrete behavior change and validation. Mention any untested platforms.

Never commit ISOs, virtual disks, build roots, credentials, personal recovery logs or recovered files. Add original scripts to `payload/custom/` only if they are suitable for public distribution; private additions can stay in your own fork or local working tree. New packages need an official source, documented license and a reason to be in a recovery image. Avoid install-at-first-launch stubs: the tools should already be installed when the ISO boots.

Disk-changing helpers must identify their target and require deliberate user action. A desktop shortcut must not silently format, reset passwords, edit EFI variables or repair a filesystem. Root access is intentional, but does not justify unrelated writes. Keep the default read-only Windows mounting behavior.

Contributions are provided under the repository's MIT license for original project code. Third-party licensing remains separate; see [THIRD_PARTY.md](THIRD_PARTY.md).
