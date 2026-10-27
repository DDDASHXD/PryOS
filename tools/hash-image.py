"""Hash large images with large reads, including across WSL host mounts."""
import hashlib
from pathlib import Path
import sys

def digest(path):
    result = hashlib.sha256()
    with Path(path).open('rb') as stream:
        while block := stream.read(16 * 1024 * 1024):
            result.update(block)
    return result.hexdigest()

if __name__ == '__main__':
    actual = digest(sys.argv[1])
    if len(sys.argv) > 2:
        if actual.lower() != sys.argv[2].strip().lower():
            raise SystemExit(f'Checksum mismatch: {sys.argv[1]}')
        print(f'SHA256 verified: {Path(sys.argv[1]).name} ({actual})')
    else:
        print(actual)
