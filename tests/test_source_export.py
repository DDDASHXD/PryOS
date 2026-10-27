import importlib.util
import io
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('source_export', PROJECT / 'tools/export-source.py')
source_export = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source_export)

class SourceExportTests(unittest.TestCase):
    def test_generated_files_and_credentials_are_not_exported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            (root / '.gitignore').write_text('.env\nout/\n*.iso\n')
            (root / 'README.md').write_text('public source')
            (root / '.env').write_text('dummy private configuration')
            (root / 'disk.iso').write_bytes(b'not source')
            (root / 'out').mkdir()
            (root / 'out/build.log').write_text('private build output')
            data = io.BytesIO()
            source_export.export(root, data)
            data.seek(0)
            with tarfile.open(fileobj=data) as archive:
                self.assertEqual(set(archive.getnames()), {'.gitignore', 'README.md'})

    def test_even_a_tracked_auth_file_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            (root / 'auth.json').write_text('{}')
            subprocess.run(['git', '-C', str(root), 'add', 'auth.json'], check=True)
            with self.assertRaises(ValueError):
                source_export.export(root, io.BytesIO())

if __name__ == '__main__':
    unittest.main()
