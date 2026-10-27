# Testing and troubleshooting

Source checks are lightweight and do not download an ISO:

```sh
python3 -m unittest discover -s tests -v
bash scripts/check.sh
```

Tests cover nonpersistent/loopback boot parameters, integrity manifest scope, and source export's handling of ignored/generated/credential files. GitHub Actions runs source and PowerShell syntax checks on Linux, macOS and Windows. Source tests do not establish ISO bootability.

After a build, run `sudo bash verify-iso.sh` inside the matching Linux builder. Set the same `PRYOS_WORK_DIR` and `PRYOS_OUTPUT_DIR` if customized. This verifies the ISO manifest and packed settings, checks installed CLIs and signed-out Codex, validates desktop/sudoers syntax, and compares the kernel/initrd with the original image. Verification requires the corresponding staged build root.

## Boot acceptance

Use a VM without valuable disks first:

1. Boot normal mode. XFCE should appear with PryOS wallpaper, recovery/agent shortcuts, and no installer window.
2. In Root Terminal, `id -u` must print `0`, `printenv XDG_CURRENT_DESKTOP` should identify XFCE, and `sudo -n true` should succeed.
3. Open the agent chooser and recovery GUIs. Check all client versions and signed-out state without providing credentials for an installation-only test.
4. Open Helium from the desktop and from an HTTP link. Confirm it runs as `pryos-browser` (for example `ps -eo user,args | grep helium`), without `--no-sandbox`. Check an about page before using it for provider logins.
5. Check `/proc/cmdline` includes `nopersistent`, no `persistent` token, and `/` is a live overlay.
6. Create `/root/REBOOT-MARKER`, reboot, and confirm it is absent. Optionally install an absent harmless package and verify it disappears too.
7. Attach a disposable NTFS disk. Verify the mount helper reports `ro`, refuses a mounted source/occupied target and rejects a non-NTFS device. Inspect only test data.
8. Test the actual Ventoy USB on the target PC, in BIOS/UEFI/Secure Boot modes as relevant. VM success does not prove firmware or physical-driver compatibility.

## VirtualBox black screen

Use Ubuntu **64-bit**, CPU long mode enabled, VMSVGA with 128 MB VRAM, 3D acceleration off initially, two CPUs and roughly 4 GB RAM. The development VM initially used a 32-bit profile with `longmode=off`; it could not run the amd64 image. A matching label alone does not fix a disabled CPU mode.

Try safe graphics, then diagnostic text mode. Boot messages are shown rather than hiding failures behind Ubuntu's splash screen. With Ventoy, try its GRUB2 alternative if Normal mode fails; preserve the exact error and firmware/mode details in a bug report. Do not make disk repairs to troubleshoot an ISO display failure.

## Build failures

- Mount or OverlayFS errors: build in Linux with root privileges and put the working directory on ext4/XFS/Btrfs, not a Windows/macOS shared mount.
- Checksum mismatch: discard the incomplete source file and download again, or update base version/hash together from Ubuntu's official release page. Use a new work directory after a base change.
- WSL installation options unavailable: update WSL, complete any Windows restart, and confirm hardware virtualization is enabled.
- Apple Silicon slowness: full x86 CPU emulation is expected. Use an x86-64 Linux/Windows builder for faster builds; do not substitute an ARM VM and claim it tests the amd64 ISO.
- Permission prompts: Linux root passwords, provider authentication and agent consent are separate. Read the exact prompt before changing permissions.

Do not upload credentials, recovery keys, personal registries or disk images to issue reports. Redact diagnostics first.
