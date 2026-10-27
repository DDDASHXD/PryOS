# Configuring PryOS

## Build defaults

`config/build.env` is reviewed, source-controlled Bash configuration. `config/local.env` is an optional ignored override. Configuration is sourced as code; do not use untrusted files or store provider credentials there.

| Variable | Purpose |
| --- | --- |
| `PRYOS_VERSION` | Image version/metadata |
| `BASE_ISO_NAME`, `BASE_ISO_URL`, `BASE_ISO_SHA256` | Exact Ubuntu Desktop amd64 base and expected hash |
| `PRYOS_WORK_DIR` | Dedicated Linux filesystem working directory |
| `PRYOS_OUTPUT_DIR` | Output folder, normally checkout `out/` |
| `PRYOS_SOURCE_ISO` | Optional local copy of the expected base ISO |
| `PRYOS_CPUS` | SquashFS worker count, default 4 |
| `PRYOS_COMPRESSION_LEVEL` | Zstd level, default 8 |
| `PRYOS_FORCE` | Set to 1 to replace the final output atomically |
| `PRYOS_REFRESH` | Set to 1 to refresh customization despite unchanged inputs |
| `PRYOS_LIMA_INSTANCE` | macOS builder VM name, default `pryos-builder` |

Example `config/local.env`:

```sh
PRYOS_CPUS=2
PRYOS_COMPRESSION_LEVEL=3
```

CLI environment values are defaults unless overridden by your local configuration. Updating the base needs its official checksum and a new working root. Do not disable integrity checks to make a download succeed.

## Image customization

- `payload/customize.sh`: core recovery packages, Codex, common configuration.
- `payload/xfce-setup.sh`: XFCE, Helium, other agent clients, local root autologin and branding.
- `payload/make-desktop.py`: desktop shortcuts, default XFCE settings and version record.
- `payload/bin/`: installed CLI helpers.
- `payload/custom/`: your own scripts, installed into `/opt/recovery/custom` on PATH.
- `payload/AGENTS.md`: recovery guidance, also copied as Claude/Gemini context.
- `payload/codex-config.toml`: Codex's temporary home configuration.
- `payload/pryos.svg`: project wallpaper.
- `prepare-boot.py`: normal, safe-graphics and text boot entries, loopback handling and integrity manifest.

Keep executable scripts executable, use LF line endings, and avoid credentials or personal disk data. Edits affect the next build, not an already-created ISO. All downloaded binaries retain their own terms.

## Root desktop and agents

The local live desktop uses LightDM autologin to root, set after Casper by `recovery-live-setup.service`. Sudoers permits passwordless administration as a fallback. No remote login server is added. The Ubuntu compatibility ID is retained for package tooling, while the visible image name, hostname, menus and artwork are PryOS.

Agents run in `/root/Recovery`. Codex has full filesystem access with on-request approval policy; Linux password authentication does not control provider logins or every client-specific consent prompt. Other clients retain their own controls. Do not bake in credentials to skip provider sign-in. OpenCode can use an existing local model endpoint; no server/weights are installed by default.

## Helium

The signing key is pinned in `payload/keys/helium.asc` and verified by primary fingerprint before APT trusts it. Helium uses the official `helium-bin` package. Key rotation requires reviewing/updating that file and the expected fingerprint.

`pryos-browser` is the default URI/HTML browser and desktop launcher. Under the root desktop it authorizes only the dedicated local browser identity on X11 and uses `runuser` plus a private D-Bus session. The browser remains unprivileged, its password is locked, and Chromium's sandbox is not disabled. Its profile lives in the temporary `/home/pryos-browser` home. AI shells remain root and do not need a password to launch it.

The launcher loads the packaged Helium AppArmor profile into the live kernel when needed and uses Chromium's basic password store instead of prompting to create a desktop keyring. Browser data remains in the disposable profile. The desktop environment explicitly includes `/usr/sbin` and the other system command directories in PATH so root-only recovery tools are available from GUI launchers and terminals.

## Persistence

Do not configure a Ventoy persistence mapping for the ISO, including wildcard mappings. Every included boot entry has `nopersistent`. Package changes, user homes, preferences and agent logins are discarded with the overlay. Explicit writes to disks or external services persist. Export only the files/reports you actually intend to keep.
