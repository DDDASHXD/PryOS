"""Prepare a single-layer, nonpersistent Casper boot menu and image checksums."""
from pathlib import Path
import hashlib
import sys
import os

tree, casper = map(Path, sys.argv[1:])
grub = '''set default=0
set timeout=8
if loadfont unicode; then
    set gfxmode=auto
    insmod all_video
    terminal_output gfxterm
fi
menuentry "PryOS - clean session" {
    set gfxpayload=keep
    echo "Starting PryOS recovery desktop..."
    linux /casper/vmlinuz boot=casper layerfs-path=recovery.squashfs nopersistent username=ubuntu hostname=pryos plymouth.enable=0 ---
    initrd /casper/initrd
}
menuentry "PryOS - safe graphics" {
    linux /casper/vmlinuz boot=casper layerfs-path=recovery.squashfs nopersistent username=ubuntu hostname=pryos nomodeset plymouth.enable=0 ---
    initrd /casper/initrd
}
menuentry "PryOS - diagnostic text boot" {
    set gfxpayload=text
    linux /casper/vmlinuz boot=casper layerfs-path=recovery.squashfs nopersistent username=ubuntu hostname=pryos nomodeset plymouth.enable=0 console=tty0 systemd.unit=multi-user.target ---
    initrd /casper/initrd
}
if [ "$grub_platform" = "efi" ]; then
    menuentry "UEFI firmware settings" { fwsetup }
fi
menuentry "Power off" { halt }
'''
for name in ("grub.cfg", "loopback.cfg"):
    content = grub
    if name == "loopback.cfg":
        content = content.replace("boot=casper ", "boot=casper iso-scan/filename=${iso_path} ")
    (tree / "boot/grub" / name).write_text(content, encoding="utf-8", newline="\n")
(tree / ".disk/info").write_text(f"PryOS {os.environ.get('PRYOS_VERSION', '0.1.0')} amd64 - root live session\n")
entries = []
for path in sorted(tree.rglob("*")):
    rel = path.relative_to(tree)
    # xorriso patches boot catalog/El Torito addresses while replaying boot setup.
    if rel.parts[0] in {"casper", "pool", "dists"} or str(rel) in {"md5sum.txt", "boot.catalog", "boot/grub/boot.catalog", "boot/grub/i386-pc/eltorito.img"}:
        continue
    if path.is_file() and not path.is_symlink():
        entries.append((path, rel))
for path in sorted(casper.rglob("*")):
    if path.is_file():
        entries.append((path, Path("casper") / path.relative_to(casper)))
with (tree / "md5sum.txt").open("w", newline="\n") as output:
    for path, rel in entries:
        with path.open("rb") as content:
            digest = hashlib.file_digest(content, "md5").hexdigest()
        output.write(f"{digest}  ./{rel.as_posix()}\n")
