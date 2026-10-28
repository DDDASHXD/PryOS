# Configuration

Defaults live in `config/build.env`. The Ubuntu ISO for each architecture is in `config/amd64.env` and `config/arm64.env`. Copy `config/local.env.example` to `config/local.env` when you want local overrides. `local.env` is gitignored. These files are shell, so keep passwords and keys out of them. `local.env` is applied last.

| Variable | What it does |
| --- | --- |
| `PRYOS_VERSION` | Version string written into the image |
| `BASE_ISO_NAME`, `BASE_ISO_URL`, `BASE_ISO_SHA256` | Ubuntu Desktop ISO for this architecture |
| `PRYOS_WORK_DIR` | Linux directory for the extracted image. Default `/var/tmp/pryos-build` |
| `PRYOS_OUTPUT_DIR` | Where the ISO is written. Default `out/` |
| `PRYOS_SOURCE_ISO` | Local copy of the base ISO, if you already have it |
| `PRYOS_CPUS` | SquashFS workers. Default 4 |
| `PRYOS_COMPRESSION_LEVEL` | Zstd level. Default 8 |
| `PRYOS_FORCE` | Set to `1` to replace an existing ISO |
| `PRYOS_REFRESH` | Set to `1` to customize the image again |
| `PRYOS_ARCH` | `amd64` or `arm64`. On macOS this is the same as `bash scripts/build-macos.sh amd64` or `bash scripts/build-macos.sh arm64`. On Linux the builder has to be that architecture |
| `PRYOS_LIMA_INSTANCE` | macOS VM name. Default `pryos-builder` for amd64 and `pryos-builder-arm64` for arm64 |

Example `config/local.env`:

```sh
PRYOS_CPUS=2
PRYOS_COMPRESSION_LEVEL=3
```

Changing the base ISO means updating the name, URL, and checksum together, then building in a new work directory.

## What goes on the image

- `payload/customize.sh` installs recovery packages and Codex
- `payload/xfce-setup.sh` installs the XFCE desktop, the other agents, and root autologin
- `payload/make-desktop.py` writes the desktop shortcuts
- `payload/bin/` holds the helper commands
- `payload/custom/` is copied to `/opt/recovery/custom` and added to `PATH`
- `payload/AGENTS.md` is copied into the live session for the agents
- `payload/codex-config.toml` is the Codex config for the live home
- `payload/pryos.jpg` is the wallpaper
- `payload/pryos-menu.svg` is the applications menu icon
- `prepare-boot.py` writes the boot menu

Edits apply on the next build. An ISO you already made stays as it is.

Use LF line endings. Keep scripts that should run marked executable.

## Desktop

The live desktop logs in as root through LightDM. Sudo works with no password. The visible name and hostname are PryOS.

The home directory, added packages, and settings are gone after reboot. Writes to attached disks stay.
