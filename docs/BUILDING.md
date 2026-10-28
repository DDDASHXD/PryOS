# Building

PryOS is Ubuntu 24.04 with XFCE. There are two images.

- `out/pryos-amd64.iso` for x86-64 PCs
- `out/pryos-arm64.iso` for ARM64 machines that boot with UEFI

Packing uses Linux mounts, chroot, SquashFS, and xorriso, so the builder has to be the same architecture as the image. Windows and macOS start an Ubuntu VM and build there.

Plan on at least 40 GB free, 8 GB of RAM, and a network connection. The build runs as root.

Shared settings are in `config/build.env`. The Ubuntu ISO name, URL, and SHA-256 are in `config/amd64.env` and `config/arm64.env`. The build downloads that ISO and checks the hash.

## Linux

On amd64 Ubuntu:

```sh
sudo bash scripts/setup-linux.sh
sudo bash build-iso.sh
sudo bash verify-iso.sh
```

That writes `out/pryos-amd64.iso`. The same commands on arm64 Ubuntu write `out/pryos-arm64.iso`.

The work directory defaults to `/var/tmp/pryos-build`. It has to sit on a Linux filesystem. Output defaults to `out/` in the checkout.

To use an Ubuntu ISO you already downloaded, with the hash from the matching `config/amd64.env` or `config/arm64.env`:

```sh
sudo env PRYOS_SOURCE_ISO=/path/to/ubuntu.iso bash build-iso.sh
```

Optional QEMU test tools:

```sh
sudo bash scripts/setup-linux.sh --test-tools
bash scripts/test-qemu.sh out/pryos-amd64.iso
bash scripts/test-qemu.sh out/pryos-arm64.iso
```

## Windows

Windows builds the x86-64 image through WSL2 and Ubuntu 24.04. Install Git for Windows and WSL2. Virtualization has to be enabled. From PowerShell in the checkout:

```powershell
.\scripts\setup-windows.ps1
.\scripts\build.ps1
```

Setup creates an Ubuntu 24.04 distro named `PryOSBuilder` and installs the build tools there. The result is `out/pryos-amd64.iso`.

To put that distro on another drive:

```powershell
.\scripts\setup-windows.ps1 -Location D:\PryOS-Builder
```

To use an Ubuntu 24.04 distro you already have:

```powershell
.\scripts\setup-windows.ps1 -Distro Ubuntu-24.04
.\scripts\build.ps1 -Distro Ubuntu-24.04 -WorkDir /var/tmp/pryos-build
```

Keep the work directory inside Linux, such as `/var/tmp/pryos-build`. The Windows checkout can hold the source and the finished ISO. The wrapper maps those paths.

If PowerShell blocks the scripts in that window:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

## macOS

Install Homebrew, then:

```sh
brew install git python lima qemu lima-additional-guestagents
```

x86-64 PC image:

```sh
bash scripts/build-macos.sh amd64
```

This writes `out/pryos-amd64.iso`. The VM is `pryos-builder`, from `scripts/pryos-builder.yaml`. On an Intel Mac this is the normal build. On Apple Silicon the VM emulates an x86-64 CPU, so the build takes longer.

ARM64 image:

```sh
bash scripts/build-macos.sh arm64
```

This writes `out/pryos-arm64.iso`. It needs an Apple Silicon Mac. The VM is `pryos-builder-arm64`, from `scripts/pryos-builder-arm64.yaml`. That VM is ARM64 Ubuntu and uses the Mac hypervisor.

With no argument, an Apple Silicon Mac builds the ARM64 image and an Intel Mac builds the PC image. `PRYOS_ARCH=amd64` and `PRYOS_ARCH=arm64` select the same images as the arguments.

The two VMs are separate. Each wants about 8 GB of RAM.

```sh
limactl shell pryos-builder
limactl shell pryos-builder-arm64
limactl stop pryos-builder
limactl stop pryos-builder-arm64
```

The VM does not mount your home folder. The script copies the git checkout into the VM, builds there, and copies the ISO back to `out/`.

## Rebuilds

`PRYOS_FORCE=1` replaces an ISO that is already in `out/`. On Windows, pass `-Force` to `scripts/build.ps1`. On macOS, put the variable in front of the same command:

```sh
PRYOS_FORCE=1 bash scripts/build-macos.sh amd64
PRYOS_FORCE=1 bash scripts/build-macos.sh arm64
```

`PRYOS_REFRESH=1` runs image customization again even when the sources look unchanged.

```sh
sudo env PRYOS_FORCE=1 PRYOS_REFRESH=1 bash build-iso.sh
```

If you change the base ISO checksum, use a new `PRYOS_WORK_DIR`. The old work directory still has the previous Ubuntu filesystem.

Keep ISOs out of git.
