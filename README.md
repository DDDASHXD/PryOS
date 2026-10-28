# PryOS

PryOS is a live Ubuntu system. It boots to an XFCE desktop as root, with disk tools and AI agents already installed.

The live system resets on reboot. Writes to real disks stay.

## Images

- `out/pryos-amd64.iso` for x86-64 PCs
- `out/pryos-arm64.iso` for ARM64 machines that boot with UEFI

## On the image

- XFCE
- Codex, Claude Code, Gemini CLI, and OpenCode
- GParted, TestDisk, PhotoRec, GSmartControl, NTFS tools, ddrescue, NVMe tools, efibootmgr, chntpw, dislocker, cryptsetup, and partclone
- `recovery-inventory`, `recovery-mount-windows`, and `windows-inspect`

Scripts you add under `payload/custom/` are installed to `/opt/recovery/custom`.

## Build

Plan on at least 40 GB free, 8 GB of RAM for the builder, and a network connection.

### Linux

Ubuntu 24.04. The image matches the machine. amd64 Ubuntu writes `out/pryos-amd64.iso`. arm64 Ubuntu writes `out/pryos-arm64.iso`.

```sh
git clone https://github.com/DDDASHXD/PryOS.git
cd PryOS
sudo bash scripts/setup-linux.sh
sudo bash build-iso.sh
sudo bash verify-iso.sh
```

### Windows

WSL2 with Ubuntu 24.04. This builds the x86-64 image.

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
```

x86-64 PC image:

```sh
bash scripts/build-macos.sh amd64
```

ARM64 image. This needs an Apple Silicon Mac:

```sh
bash scripts/build-macos.sh arm64
```

With no argument, an Apple Silicon Mac builds the ARM64 image and an Intel Mac builds the PC image.

Details are in [Building](docs/BUILDING.md), [Configuration](docs/CONFIGURATION.md), and [Testing](docs/TESTING.md).

## Boot

Copy the ISO to a Ventoy stick with persistence left off. The menu has a normal entry, a safe graphics entry, and a text entry.

Boot `pryos-amd64.iso` on an x86-64 PC. In VirtualBox, use a 64-bit machine with long mode on, two CPUs, and about 4 GB of RAM.

Boot `pryos-arm64.iso` on an ARM64 machine with UEFI. On an Apple Silicon Mac, use UTM or `bash scripts/test-qemu.sh out/pryos-arm64.iso`.

The desktop logs in as root. Connect to a network and open an agent from the desktop.

## Windows disks

```sh
recovery-inventory
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL,SERIAL,MOUNTPOINTS
recovery-mount-windows /dev/YOUR_WINDOWS_PARTITION /mnt/windows
windows-inspect /mnt/windows
```

`recovery-mount-windows` mounts NTFS read-only. Copy anything you want to keep onto another disk before you shut down.

## Checks

```sh
python3 -m unittest discover -s tests -v
bash scripts/check.sh
```

The repo holds source. Keep built ISOs out of git. Project code is [MIT](LICENSE). Other programs keep their own licenses. See [THIRD_PARTY.md](THIRD_PARTY.md).
