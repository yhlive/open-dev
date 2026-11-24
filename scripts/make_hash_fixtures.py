#!/usr/bin/env python3
"""Generate deterministic File Hash workshop files and a SHA-256 manifest."""

import argparse
import hashlib
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="New or existing fixture directory")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    block = bytes(range(256)) * 4096
    files = [
        ("empty.bin", 0),
        ("abc.bin", None),
        ("payload-008m.bin", 8),
        ("payload-064m.bin", 64),
        ("payload-128m.bin", 128),
    ]
    for name, _ in files:
        if (args.output / name).exists():
            raise SystemExit(f"Already exists: {name}. Choose an empty output directory.")
    entries = []
    for name, size in files:
        path = args.output / name
        digest = hashlib.sha256()
        with path.open("wb") as output:
            if size is None:
                output.write(b"abc")
                digest.update(b"abc")
            else:
                for _ in range(size):
                    output.write(block)
                    digest.update(block)
        print(f"{path.name}: {path.stat().st_size} bytes")
        entries.append(f"{digest.hexdigest()}  {name}\n")
    (args.output / "SHA256SUMS.txt").write_text("".join(entries), encoding="ascii")


if __name__ == "__main__":
    main()
