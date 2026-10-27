"""Fingerprint customization inputs so edited payloads invalidate cached stages."""
import hashlib
from pathlib import Path
import sys

result = hashlib.sha256()
for argument in sys.argv[1:]:
    source = Path(argument)
    paths = sorted(p for p in source.rglob('*') if p.is_file()) if source.is_dir() else [source]
    for path in paths:
        if '__pycache__' in path.parts:
            continue
        result.update(str(path.relative_to(source) if source.is_dir() else path.name).encode())
        result.update(b'\0')
        result.update(str(path.stat().st_mode & 0o111).encode())
        result.update(path.read_bytes())
print(result.hexdigest())
