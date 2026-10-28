# Testing

Source checks do not download an ISO:

```sh
python3 -m unittest discover -s tests -v
bash scripts/check.sh
```

GitHub Actions runs those checks on Linux, macOS, and Windows. They do not prove the ISO boots.

After a build, on the same Linux machine and with the same work directory:

```sh
sudo bash verify-iso.sh
```

Set `PRYOS_WORK_DIR` and `PRYOS_OUTPUT_DIR` if you changed them for the build. Verification needs that work directory. It checks the ISO contents, the installed tools, and that the kernel matches the Ubuntu base.

## Boot

Try the ISO in a VM before you point it at a disk you care about.

1. Boot the normal entry. XFCE should come up with the PryOS wallpaper and the desktop shortcuts.
2. In Root Terminal, `id -u` prints `0`.
3. Open an agent and a recovery tool from the desktop.
4. `cat /proc/cmdline` includes `nopersistent`.
5. Create a file in `/root`, reboot, and confirm it is gone.
6. On a disposable NTFS disk, `recovery-mount-windows` should mount it read-only.

Then try the Ventoy stick on the machine you want to boot. Use `pryos-amd64.iso` on an x86-64 PC and `pryos-arm64.iso` on an ARM64 machine with UEFI. A VM boot does not prove the firmware or the hardware drivers.

For the PC image in VirtualBox, use a 64-bit machine, long mode on, VMSVGA, 128 MB video memory, 3D off, two CPUs, and about 4 GB of RAM. If the screen stays black, try safe graphics, then the text entry.

For the ARM64 image on an Apple Silicon Mac:

```sh
bash scripts/test-qemu.sh out/pryos-arm64.iso
```

That opens a QEMU window and attaches an empty disk at `vm-test/disposable.qcow2`. UTM can boot the ISO as well. The PC image on a Mac is:

```sh
bash scripts/test-qemu.sh out/pryos-amd64.iso
```

## Build problems

- Mount errors usually mean the work directory is on a Windows or macOS share. Put it on a Linux filesystem and run the build as root.
- A checksum error means the Ubuntu ISO download does not match `config/amd64.env` or `config/arm64.env`. Download it again, or update the name, URL, and hash together, and use a new work directory.
- If WSL refuses to create the distro, update WSL, reboot if Windows asks, and check that virtualization is on.
- `bash scripts/build-macos.sh amd64` on Apple Silicon emulates an x86-64 CPU, so that build takes longer. `bash scripts/build-macos.sh arm64` uses the Mac hypervisor.

Keep passwords, recovery keys, and disk images out of bug reports.
