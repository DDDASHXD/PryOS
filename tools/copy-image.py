"""Copy a large image without tiny DrvFS reads; verify separately with hash-image.py."""
from pathlib import Path
import sys

if __name__ == '__main__':
    source, destination = map(Path, sys.argv[1:])
    if source.resolve() == destination.resolve():
        raise SystemExit('Source and destination must differ')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with source.open('rb') as src, destination.open('wb') as dst:
        while block := src.read(16 * 1024 * 1024):
            dst.write(block)
