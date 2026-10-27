# Building PryOS

## Architecture and prerequisites

The ISO is Ubuntu 24.04 LTS **amd64**, with XFCE and a nonpersistent root recovery session. The source ISO filename, URL and expected SHA-256 are pinned in `config/build.env`. Agent/package versions can change upstream; installed versions are recorded, so this is not a byte-reproducible or fully version-pinned image.

Image customization needs Linux mounts, `chroot`, OverlayFS, SquashFS and xorriso. The supported build environment is Ubuntu 24.04 amd64, native or in WSL2/a VM. macOS and Windows wrappers enter that environment. An ARM-native ISO is not currently produced.

Use a dedicated Linux working directory, roughly 40–60 GB free, 8 GB RAM, 4 CPUs and networking. Builder commands run as root. Review source changes before running untrusted contribution branches as root. Do not attach valuable drives to a test VM.

## Windows: WSL2

Install Git for Windows and a current WSL release. Hardware virtualization must be enabled. On a new installation, Windows may need an administrator terminal and restart to enable WSL2. Use `wsl --update` if your version lacks the distribution-name/location options.

From PowerShell in the cloned repository:

```powershell
.\scripts\setup-windows.ps1
.\scripts\build.ps1
```

The setup helper creates a dedicated Ubuntu 24.04 distribution named `PryOSBuilder`, then installs host build tools. It does not modify Docker's internal distro. To store the virtual disk on another drive:

```powershell
.\scripts\setup-windows.ps1 -Location D:\PryOS-Builder
```

To use an existing Ubuntu 24.04 WSL2 distro:

```powershell
.\scripts\setup-windows.ps1 -Distro Ubuntu-24.04
.\scripts\build.ps1 -Distro Ubuntu-24.04 -WorkDir /var/tmp/pryos-build
```

Keep the working directory inside Linux, not `/mnt/c` or another Windows mount. Source and output may be in the Windows checkout; the wrapper translates their paths. If PowerShell blocks local scripts, use a process-only policy in that terminal: `Set-ExecutionPolicy -Scope Process Bypass`.

Run structural verification using the same distro and working directory. For example, from its Linux shell, navigate to the checkout and run:

```sh
sudo env PRYOS_WORK_DIR=/var/tmp/pryos-build bash verify-iso.sh
```

## Linux: native or an Ubuntu VM

```sh
sudo bash scripts/setup-linux.sh
sudo bash build-iso.sh
sudo bash verify-iso.sh
```

Default work directory: `/var/tmp/pryos-build`. Default output: the checkout's `out/`. The script rejects shared host filesystems as build roots. The source ISO is downloaded and SHA-256 verified automatically. To supply an already-downloaded matching image:

```sh
sudo env PRYOS_SOURCE_ISO=/path/to/ubuntu.iso bash build-iso.sh
```

On distributions without APT, use an Ubuntu 24.04 amd64 VM instead of running the dependency helper on the host. QEMU/virt-manager, VirtualBox, or another hypervisor can provide that VM. The source checkout can be cloned inside it.

Optional Linux testing tools:

```sh
sudo bash scripts/setup-linux.sh --test-tools
bash scripts/test-qemu.sh out/pryos-amd64.iso
```

That QEMU helper boots without attaching a hard disk, using KVM if available and software emulation otherwise. OVMF is installed for manual UEFI tests; the basic helper uses the default BIOS firmware.

## macOS: Lima/QEMU builder

Install [Homebrew](https://brew.sh/), then:

```sh
brew install git python lima qemu lima-additional-guestagents
bash scripts/build-macos.sh
```

The helper creates `pryos-builder` from `scripts/pryos-builder.yaml`. It is an x86-64 Ubuntu 24.04 Linux VM on both Intel and Apple Silicon. Apple Silicon requires full x86 CPU emulation, which can be substantially slower; this is not an ARM64 recovery image and cannot boot natively on Apple Silicon.

The VM does not mount your home directory. The helper exports only Git-visible working files, including uncommitted edits, into a dedicated guest source directory. Generated files and secrets are excluded. An optional `config/local.env` is copied explicitly as build configuration; never put credentials in that file. The build root and outputs remain on the guest's Linux disk, then the ISO/checksum/reports are copied back into local `out/` and the SHA-256 is checked.

Useful operations:

```sh
limactl shell pryos-builder
limactl stop pryos-builder
PRYOS_FORCE=1 bash scripts/build-macos.sh
```

For graphical tests, install QEMU or UTM and **emulate an x86-64 PC** on Apple Silicon. macOS Virtualization.framework's ARM VM mode is not an x86-64 boot test. `bash scripts/test-qemu.sh` can use Homebrew QEMU; it uses HVF on Intel Macs and software emulation on ARM Macs.

The macOS path follows [Lima's foreign-architecture guidance](https://lima-vm.io/docs/config/multi-arch/) and [installation instructions](https://lima-vm.io/docs/installation/). It has not been executed on Mac hardware in this development environment. File an issue with the Lima/QEMU/macOS versions if it needs adjustment.

## Caching, rebuilding and outputs

`PRYOS_WORK_DIR` holds the extracted base, writable image tree, cache signatures and packed filesystem. Payload/configuration changes invalidate customization/packing. Boot menu changes regenerate boot configuration. A changed base ISO checksum requires a **fresh working directory** to prevent mixing base filesystems.

The builder refuses to overwrite a finished ISO unless `PRYOS_FORCE=1` is set (Windows: `-Force`). `PRYOS_REFRESH=1` also reruns customization to fetch newer upstream tools even if source inputs are unchanged. Cached working roots are for trusted local development; a release should also be checked from a fresh root.

```sh
sudo env PRYOS_FORCE=1 PRYOS_REFRESH=1 bash build-iso.sh
```

Outputs are the ISO, SHA-256, `build.log`, package metadata and AI-client versions. Verification writes `out/verification.txt`. The original kernel/initrd and BIOS/UEFI structures are preserved. Every live entry has `nopersistent`; installer archive pools are omitted.

On failure, the builder restores its temporary DNS and service-start policy and unmounts chroot resources in its private mount namespace. Correct the reported error and retry. Do not recursively delete an unspecified working directory; choose a new dedicated work path when you want a fresh build.

ISOs belong in local output storage or a separately reviewed release channel, not Git commits. See [third-party licensing](../THIRD_PARTY.md) before distributing binaries.
