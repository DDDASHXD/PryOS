"""Export Git-visible working files, including edits, without generated/private files."""
from pathlib import Path
import subprocess
import sys
import tarfile

def export(project, stream):
    project = Path(project).resolve()
    result = subprocess.run(['git', '-C', str(project), 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], check=True, capture_output=True)
    names = sorted(set(name for name in result.stdout.decode().split('\0') if name))
    with tarfile.open(fileobj=stream, mode='w|') as archive:
        for name in names:
            path = project / name
            if path.is_symlink():
                raise ValueError(f'Source symlinks need explicit review: {name}')
            if not path.is_file():
                continue
            if path.stat().st_size > 10 * 1024 * 1024:
                raise ValueError(f'Refusing a large source file: {name}')
            if path.name in {'auth.json', '.env', 'id_rsa', 'id_ed25519'} or path.suffix.lower() in {'.iso', '.vhdx', '.vdi', '.pem'}:
                raise ValueError(f'Refusing private/generated source file: {name}')
            archive.add(path, arcname=name, recursive=False)

if __name__ == '__main__':
    export(sys.argv[1] if len(sys.argv) > 1 else '.', sys.stdout.buffer)
