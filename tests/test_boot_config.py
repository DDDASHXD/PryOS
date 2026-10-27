import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parents[1]

class BootConfigTests(unittest.TestCase):
    def test_nonpersistent_boot_and_loopback_configs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tree, casper = root / 'iso', root / 'casper'
            for folder in (tree / '.disk', tree / 'boot/grub', tree / 'pool', casper):
                folder.mkdir(parents=True)
            (tree / 'pool/installer.deb').write_bytes(b'not in recovery ISO')
            (tree / 'boot.catalog').write_bytes(b'replayed at image creation')
            for name in ('vmlinuz', 'initrd', 'recovery.squashfs'):
                (casper / name).write_bytes(name.encode())
            subprocess.run([sys.executable, str(PROJECT / 'prepare-boot.py'), str(tree), str(casper)], check=True, env=dict(os.environ, PRYOS_VERSION='test'))
            grub = (tree / 'boot/grub/grub.cfg').read_text()
            loopback = (tree / 'boot/grub/loopback.cfg').read_text()
            kernels = [line.split() for line in grub.splitlines() if line.strip().startswith('linux ')]
            self.assertEqual(len(kernels), 3)
            for command in kernels:
                self.assertIn('nopersistent', command)
                self.assertNotIn('persistent', command)
                self.assertIn('layerfs-path=recovery.squashfs', command)
                self.assertIn('hostname=pryos', command)
            self.assertNotIn('iso-scan/filename=', grub)
            self.assertEqual(loopback.count('iso-scan/filename=${iso_path}'), 3)
            self.assertIn('PryOS test', (tree / '.disk/info').read_text())
            checksums = (tree / 'md5sum.txt').read_text()
            self.assertNotIn('pool/', checksums)
            self.assertNotIn('boot.catalog', checksums)
            self.assertIn(hashlib.md5(b'recovery.squashfs').hexdigest(), checksums)

if __name__ == '__main__':
    unittest.main()
