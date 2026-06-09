#!/usr/bin/env python3
"""
noeau_search.py — Full-text search inside /home/Cipher/Noeau only.

Usage:
    python3 ~/Noeau/scripts/noeau_search.py "keyword"
    python3 ~/Noeau/scripts/noeau_search.py "keyword" --topic python
    python3 ~/Noeau/scripts/noeau_search.py "keyword" --type md
    python3 ~/Noeau/scripts/noeau_search.py "def.*class" --case-sensitive

Safe: only scans inside NOEAU_ROOT. Never touches system files or private data.
"""

import sys
import re
import json
import argparse
from pathlib import Path

NOEAU_ROOT = Path("/home/Cipher/Noeau")
PREFS_PATH = NOEAU_ROOT / "config" / "preferences.json"

# ── Terminal colours (disabled automatically when piped) ─────────────────────
_TTY = sys.stdout.isatty()
RED  = "\033[0;31m"  if _TTY else ""
GRN  = "\033[0;32m"  if _TTY else ""
YLW  = "\033[1;33m"  if _TTY else ""
CYN  = "\033[0;36m"  if _TTY else ""
BLD  = "\033[1m"     if _TTY else ""
DIM  = "\033[2m"     if _TTY else ""
RST  = "\033[0m"     if _TTY else ""

# ── Config ────────────────────────────────────────────────────────────────────

def load_search_extensions() -> set[str]:
    if PREFS_PATH.exists():
        try:
            cfg = json.loads(PREFS_PATH.read_text(encoding="utf-8"))
            return set(cfg.get("search", {}).get("extensions", [".md", ".txt", ".py"]))
        except Exception:
            pass
    return {".md", ".txt", ".py"}

def load_exclude_dirs() -> set[str]:
    if PREFS_PATH.exists():
        try:
            cfg = json.loads(PREFS_PATH.read_text(encoding="utf-8"))
            return set(cfg.get("search", {}).get("exclude_dirs", []))
        except Exception:
            pass
    return {".git", "__pycache__", ".obsidian"}

# ── Search ────────────────────────────────────────────────────────────────────

def search_file(filepath: Path, pattern: re.Pattern) -> list[dict]:
    results = []
    try:
        text = filepath.read_text(encoding="utf-8", errors="ignore")
    except (PermissionError, OSError):
        return results

    for i, line in enumerate(text.splitlines(), start=1):
        if pattern.search(line):
            results.append({
                "file":     filepath,
                "line_num": i,
                "line":     line.rstrip(),
            })
    return results

def highlight(line: str, pattern: re.Pattern) -> str:
    """Wrap every match in the line with bold-green colour."""
    if not _TTY:
        return line
    return pattern.sub(lambda m: f"{GRN}{BLD}{m.group(0)}{RST}", line)

def is_excluded(path: Path, exclude_dirs: set[str]) -> bool:
    return any(part in exclude_dirs for part in path.parts)

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Search inside ~/Noeau only. Never touches system files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  noeau_search.py "decorator"
  noeau_search.py "nmap" --topic cybersecurity
  noeau_search.py "import.*os" --type py --case-sensitive
""",
    )
    parser.add_argument("keyword",
                        help="Search term (basic regex supported)")
    parser.add_argument("--topic", default="",
                        help="Limit search to knowledge/<topic>")
    parser.add_argument("--type", choices=["md", "txt", "py", "all"], default="all",
                        help="File type to search (default: all)")
    parser.add_argument("--case-sensitive", action="store_true",
                        help="Case-sensitive search (default: case-insensitive)")
    parser.add_argument("--max-results", type=int, default=200,
                        help="Stop after N matches (default: 200)")
    args = parser.parse_args()

    # Safety: verify root exists
    if not NOEAU_ROOT.exists():
        print(f"{RED}ERROR: {NOEAU_ROOT} not found.{RST}")
        print("  Make sure the Noeau folder exists and preferences.json is configured.")
        sys.exit(1)

    # Determine search root
    if args.topic:
        search_root = NOEAU_ROOT / "knowledge" / args.topic
        if not search_root.exists():
            print(f"{RED}Topic '{args.topic}' not found under knowledge/{RST}")
            valid = [d.name for d in (NOEAU_ROOT / "knowledge").iterdir() if d.is_dir()]
            print(f"  Available topics: {', '.join(sorted(valid))}")
            sys.exit(1)
    else:
        search_root = NOEAU_ROOT

    # Extensions
    all_exts = load_search_extensions()
    if args.type == "all":
        exts = all_exts
    else:
        exts = {f".{args.type}"}

    exclude_dirs = load_exclude_dirs()

    # Compile regex
    flags = 0 if args.case_sensitive else re.IGNORECASE
    try:
        pattern = re.compile(args.keyword, flags)
    except re.error as e:
        print(f"{RED}Invalid regex pattern: {e}{RST}")
        sys.exit(1)

    # Print header
    scope = f"knowledge/{args.topic}" if args.topic else "all of Noeau"
    print(f"\n{CYN}  Searching:{RST} {BLD}{args.keyword}{RST}")
    print(f"{DIM}  Scope:    {scope}  |  types: {', '.join(sorted(exts))}{RST}\n")

    total_matches  = 0
    files_hit      = 0
    files_searched = 0

    for filepath in sorted(search_root.rglob("*")):
        if not filepath.is_file():
            continue
        if filepath.suffix.lower() not in exts:
            continue
        if is_excluded(filepath, exclude_dirs):
            continue

        # Hard safety: never leave NOEAU_ROOT
        try:
            filepath.relative_to(NOEAU_ROOT)
        except ValueError:
            continue

        files_searched += 1
        hits = search_file(filepath, pattern)

        if not hits:
            continue

        rel = filepath.relative_to(NOEAU_ROOT)
        print(f"  {YLW}📄 {rel}{RST}")

        for h in hits:
            if total_matches >= args.max_results:
                print(f"\n  {YLW}[max-results limit reached — use --max-results N to increase]{RST}")
                break
            line_label = f"{CYN}{str(h['line_num']).rjust(5)}{RST}"
            print(f"  {line_label}  {highlight(h['line'], pattern)}")
            total_matches += 1

        files_hit += 1
        print()

        if total_matches >= args.max_results:
            break

    # Summary
    if total_matches == 0:
        print(f"  {DIM}No matches found.{RST}")
    else:
        print(f"  {BLD}{total_matches}{RST} match(es) across {BLD}{files_hit}{RST} file(s)"
              f"  {DIM}({files_searched} searched){RST}")
    print()


if __name__ == "__main__":
    main()
