#!/usr/bin/env python3
import sys
from pathlib import Path


def read_lines(path: Path) -> list[str]:
    lines = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        lines.append(line)
    return lines


def longest_overlap(existing: list[str], incoming: list[str]) -> int:
    limit = min(len(existing), len(incoming))
    for size in range(limit, 0, -1):
        if existing[-size:] == incoming[:size]:
            return size
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 3:
      print("Usage: merge_ocr_pages.py <output.txt> <page-001.txt> [page-002.txt ...]", file=sys.stderr)
      return 1

    out_path = Path(argv[1])
    page_paths = [Path(value) for value in argv[2:]]
    merged: list[str] = []

    for page_path in page_paths:
        current = read_lines(page_path)
        if not current:
            continue
        overlap = longest_overlap(merged, current) if merged else 0
        merged.extend(current[overlap:])

    out_path.write_text("\n".join(merged) + ("\n" if merged else ""), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
