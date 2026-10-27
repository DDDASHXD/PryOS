# PryOS

**A fresh recovery workstation on every boot.**

PryOS is an Ubuntu-based, nonpersistent recovery live ISO with XFCE, Helium, disk/Windows diagnostics, and preinstalled AI agent clients. It boots to a root desktop so recovery commands do not need a Linux password. AI clients are **signed out** and use your own accounts.

## Included

- **XFCE** with recovery applications and guides on the desktop.
- **Helium by imput** as the default browser, launched as a dedicated unprivileged user so Chromium's sandbox stays enabled.
- **Codex, Claude Code, Gemini CLI and OpenCode**, with individual launchers and an agent chooser. Open several terminals to use different agents; this is not an automatic cross-provider orchestration service.
- GParted, TestDisk, PhotoRec, GSmartControl/smartmontools, NTFS tools, ddrescue, NVMe tools, efibootmgr, chntpw, dislocker, cryptsetup, partclone and custom Windows inspection scripts.
- A writable live session that resets after reboot. No installer, Snap daemon, account credentials, API keys or local model weights are bundled.

**Disk changes are permanent.** Resetting the live OS does not undo writes to attached drives or EFI NVRAM. Root access and AI permission dialogs are separate. Read [the recovery/security boundaries](SECURITY.md) before using it on important disks.

## Build

The output is `out/pryos-amd64.iso`, with a SHA-256 checksum and version reports. The image targets **x86-64 PCs**, including when built from an Apple Silicon Mac.

| Build host | Tools and entry point |
| --- | --- |
| Windows | WSL2 + Ubuntu 24.04, PowerShell wrappers |
| Linux | Ubuntu 24.04 amd64 + squashfs-tools/xorriso/chroot |
| macOS Intel/Apple Silicon | Homebrew + Lima/QEMU x86-64 Ubuntu VM; Apple Silicon uses slower CPU emulation |

### Linux

```sh
git clone https://github.com/DDDASHXD/PryOS.git
cd PryOS
sudo bash scripts/setup-linux.sh
sudo bash build-iso.sh
sudo bash verify-iso.sh
```

### Windows

```powershell
git clone https://github.com/DDDASHXD/PryOS.git
cd PryOS
.\scripts\setup-windows.ps1
.\scripts\build.ps1
```

### macOS

```sh
brew install git python lima qemu lima-additional-guestagents
git clone https://github.com/DDDASHXD/PryOS.git
cd PryOS
bash scripts/build-macos.sh
```

Allow roughly **40–60 GB of free storage**, 8 GB of builder RAM, and internet access. Working files must live on a Linux filesystem. The macOS helper copies source into a Linux VM rather than trying to run `chroot`/SquashFS tools natively on macOS.

See [detailed setup/building](docs/BUILDING.md), [configuration](docs/CONFIGURATION.md), and [testing/troubleshooting](docs/TESTING.md). Windows/WSL and Linux image building are validated locally; the macOS helper is provided with source checks and documented upstream tooling, but has not been executed on a Mac in this development environment.

## Boot

Copy the ISO to Ventoy's data partition **without a persistence mapping**. Choose PryOS's normal, safe graphics or diagnostic text entry. All include `nopersistent`. Secure Boot and physical-device compatibility require testing on your hardware.

For VirtualBox: Ubuntu **64-bit**, CPU long mode enabled, two CPUs, around 4 GB RAM, VMSVGA, 128 MB VRAM, 3D acceleration off initially. A 32-bit guest with long mode disabled cannot run this image.

The desktop autologs in as root. Connect networking, open an agent, and sign in. Codex supports its normal login and device-code flow where your account permits it; Claude uses `/login`, Gemini offers Google authentication, and OpenCode offers `/connect`. Provider access is not bundled. Helium and agent credentials live in the temporary session.

## Inspect Windows

```sh
recovery-inventory
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL,SERIAL,MOUNTPOINTS
recovery-mount-windows /dev/YOUR_WINDOWS_PARTITION /mnt/windows
windows-inspect /mnt/windows
```

The mount helper uses read-only NTFS with journal recovery disabled. It does not unlock BitLocker or remove hibernation. The inspector reports Windows markers and registry-file metadata, not registry contents or personal documents. Recovery guides open a root shell rather than silently choosing a disk or applying repairs. Save recovered files and reports to another healthy disk before reboot.

## Contribute

Read [CONTRIBUTING.md](CONTRIBUTING.md). Source checks run through GitHub Actions on Linux, macOS and Windows:

```sh
python3 -m unittest discover -s tests -v
bash scripts/check.sh
```

The repository contains source and configuration, not ISOs, virtual disks or vendor binaries. Original PryOS code/artwork uses [MIT](LICENSE); downloaded software retains its own licensing. See [THIRD_PARTY.md](THIRD_PARTY.md) before redistributing an ISO.
