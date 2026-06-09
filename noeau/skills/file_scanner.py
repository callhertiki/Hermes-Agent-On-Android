"""
file_scanner.py — Noeau Guardian: File Scanner & Cleaner

Scans a folder and finds:
  - Empty files (0 bytes — often left behind by broken programs)
  - Duplicate files (exact same content, wasting space)
  - Huge files (over a size threshold you set)
  - Suspicious file extensions in unexpected places

SAFETY RULES:
  - This script NEVER deletes files automatically.
  - It creates a report showing what it found.
  - It asks for your permission before moving anything to quarantine.
  - "Quarantine" means MOVING the file to a safe folder, not deleting it.
"""

import os
import hashlib
import shutil
from pathlib import Path
from datetime import datetime
from typing import Optional


# ── SUSPICIOUS EXTENSIONS ───────────────────────────────────────────────────
# These file types can run code. They're only flagged as suspicious
# when found in personal folders like Documents — not in system folders.
SUSPICIOUS_EXTENSIONS = {
    ".exe": "Executable program",
    ".bat": "Windows batch script",
    ".cmd": "Windows command script",
    ".ps1": "PowerShell script",
    ".vbs": "VBScript",
    ".wsf": "Windows Script File",
    ".scr": "Screensaver / executable",
    ".pif": "Program Information File (can run executables)",
    ".hta": "HTML Application (can run scripts)",
    ".jar": "Java executable archive",
}


def scan_folder(
    folder_path: str,
    huge_file_mb: int = 100,
    suspicious_extensions: Optional[list] = None
) -> dict:
    """
    Scan a folder and return a report dictionary.

    This function ONLY reads files — it does not move, modify, or delete
    anything. Think of it as taking inventory.

    Parameters:
        folder_path           — The folder to scan (string path)
        huge_file_mb          — Files bigger than this (in MB) are flagged
        suspicious_extensions — List of extensions to flag (defaults to built-in list)

    Returns:
        A dictionary with four categories of findings:
        {
            "empty_files": [...],
            "duplicate_files": {...},
            "huge_files": [...],
            "suspicious_files": [...]
        }
    """

    folder = Path(folder_path).expanduser().resolve()

    # Make sure the folder actually exists
    if not folder.exists():
        print(f"[!] Folder not found: {folder}")
        return {}

    if not folder.is_dir():
        print(f"[!] That path is a file, not a folder: {folder}")
        return {}

    print(f"[*] Scanning: {folder}")
    print(f"[*] This may take a moment for large folders...")
    print()

    # Use the default suspicious extensions list if none was provided
    if suspicious_extensions is None:
        suspicious_extensions = list(SUSPICIOUS_EXTENSIONS.keys())

    # Convert the size threshold from megabytes to bytes
    # (File sizes are measured in bytes internally)
    huge_file_bytes = huge_file_mb * 1024 * 1024

    # These lists will store what we find
    empty_files = []
    huge_files = []
    suspicious_files = []
    all_files_by_hash = {}  # Used to find duplicates

    # Walk through ALL files in the folder and all subfolders
    # os.walk() goes through every subfolder automatically
    total_files = 0
    for dirpath, dirnames, filenames in os.walk(folder):
        for filename in filenames:
            file_path = Path(dirpath) / filename
            total_files += 1

            # Print progress every 100 files so the user knows it's working
            if total_files % 100 == 0:
                print(f"  [*] Scanned {total_files} files...", end="\r")

            try:
                # Get basic file information
                file_stat = file_path.stat()
                file_size = file_stat.st_size
                file_ext = file_path.suffix.lower()

                # ── CHECK 1: Empty files ────────────────────────────────
                # A file with 0 bytes is usually leftover junk
                if file_size == 0:
                    empty_files.append({
                        "path": str(file_path),
                        "size_bytes": 0
                    })

                # ── CHECK 2: Huge files ─────────────────────────────────
                # Large files might be forgotten video exports, etc.
                elif file_size > huge_file_bytes:
                    size_mb = file_size / (1024 * 1024)
                    huge_files.append({
                        "path": str(file_path),
                        "size_mb": round(size_mb, 1)
                    })

                # ── CHECK 3: Suspicious extensions ─────────────────────
                # Only flag these in personal/document folders
                if file_ext in suspicious_extensions:
                    suspicious_files.append({
                        "path": str(file_path),
                        "extension": file_ext,
                        "description": SUSPICIOUS_EXTENSIONS.get(
                            file_ext, "Potentially executable file"
                        ),
                        "size_bytes": file_size
                    })

                # ── CHECK 4: Duplicate detection ────────────────────────
                # Skip empty files and very large files for hashing
                # (hashing a huge file takes a long time)
                if 0 < file_size < (500 * 1024 * 1024):  # Under 500 MB
                    file_hash = _hash_file(file_path)
                    if file_hash:
                        if file_hash in all_files_by_hash:
                            # We've seen this exact content before
                            all_files_by_hash[file_hash].append(str(file_path))
                        else:
                            # First time we've seen this content
                            all_files_by_hash[file_hash] = [str(file_path)]

            except PermissionError:
                # Some files are protected — skip them silently
                pass
            except Exception as e:
                # Something unexpected happened with this file — skip it
                pass

    # Filter duplicates: only keep groups with 2+ files
    duplicate_groups = {
        h: paths
        for h, paths in all_files_by_hash.items()
        if len(paths) > 1
    }

    print(f"\n[+] Scan complete. Scanned {total_files} files.")
    print()

    return {
        "scan_folder": str(folder),
        "scan_time": datetime.now().isoformat(),
        "total_files_scanned": total_files,
        "empty_files": empty_files,
        "duplicate_groups": duplicate_groups,
        "huge_files": huge_files,
        "suspicious_files": suspicious_files
    }


def print_report(scan_results: dict):
    """
    Print the scan results in a readable format.

    This is for viewing only — nothing is modified.
    """

    if not scan_results:
        print("[!] No scan results to display.")
        return

    print()
    print("=" * 60)
    print("  NOEAU FILE SCAN REPORT")
    print(f"  Folder:  {scan_results.get('scan_folder', 'Unknown')}")
    print(f"  Time:    {scan_results.get('scan_time', 'Unknown')}")
    print(f"  Files:   {scan_results.get('total_files_scanned', 0)} scanned")
    print("=" * 60)

    # ── EMPTY FILES ──────────────────────────────────────────────────────
    empty = scan_results.get("empty_files", [])
    print(f"\n  EMPTY FILES ({len(empty)} found)")
    print("  " + "─" * 50)
    if empty:
        for item in empty[:20]:  # Show first 20
            print(f"  • {item['path']}")
        if len(empty) > 20:
            print(f"  ... and {len(empty) - 20} more")
    else:
        print("  ✓ No empty files found")

    # ── DUPLICATE FILES ──────────────────────────────────────────────────
    dupes = scan_results.get("duplicate_groups", {})
    total_dupe_files = sum(len(v) for v in dupes.values())
    print(f"\n  DUPLICATE FILES ({len(dupes)} groups, {total_dupe_files} total files)")
    print("  " + "─" * 50)
    if dupes:
        for i, (file_hash, paths) in enumerate(list(dupes.items())[:10]):
            print(f"  Group {i+1} — identical content:")
            for path in paths:
                print(f"    • {path}")
        if len(dupes) > 10:
            print(f"  ... and {len(dupes) - 10} more groups")
    else:
        print("  ✓ No duplicate files found")

    # ── HUGE FILES ───────────────────────────────────────────────────────
    huge = scan_results.get("huge_files", [])
    print(f"\n  LARGE FILES ({len(huge)} found)")
    print("  " + "─" * 50)
    if huge:
        # Sort by size, biggest first
        huge_sorted = sorted(huge, key=lambda x: x["size_mb"], reverse=True)
        for item in huge_sorted[:20]:
            print(f"  • {item['size_mb']} MB  —  {item['path']}")
        if len(huge) > 20:
            print(f"  ... and {len(huge) - 20} more")
    else:
        print("  ✓ No oversized files found")

    # ── SUSPICIOUS EXTENSIONS ────────────────────────────────────────────
    suspicious = scan_results.get("suspicious_files", [])
    print(f"\n  SUSPICIOUS EXTENSIONS ({len(suspicious)} found)")
    print("  " + "─" * 50)
    if suspicious:
        print("  [i] These file types can execute code. Verify each one is expected.")
        for item in suspicious[:20]:
            print(f"  • [{item['extension']}] {item['path']}")
            print(f"    Reason: {item['description']}")
        if len(suspicious) > 20:
            print(f"  ... and {len(suspicious) - 20} more")
    else:
        print("  ✓ No suspicious extensions found in this folder")

    print()
    print("=" * 60)


def quarantine_files(
    file_paths: list,
    quarantine_folder: str,
    ask_first: bool = True
) -> list:
    """
    Move files to the quarantine folder — one at a time, with confirmation.

    SAFETY: This MOVES files, it does not delete them.
    The original location is preserved in the filename.
    You can always move files back from quarantine.

    Parameters:
        file_paths       — List of file paths to quarantine
        quarantine_folder — Where to move them
        ask_first        — If True, ask before moving each file

    Returns:
        List of files that were actually moved.
    """

    quarantine = Path(quarantine_folder).resolve()

    # Create the quarantine folder if it doesn't exist
    quarantine.mkdir(parents=True, exist_ok=True)

    moved_files = []

    for file_path in file_paths:
        path = Path(file_path)

        if not path.exists():
            print(f"  [!] File no longer exists, skipping: {path.name}")
            continue

        print(f"\n  File: {file_path}")
        print(f"  Size: {path.stat().st_size} bytes")

        if ask_first:
            confirm = input("  Move to quarantine? [y/N]: ").strip().lower()
            if confirm != "y":
                print("  [*] Skipped.")
                continue

        # Create a safe destination filename
        # We add a timestamp so files with the same name don't collide
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_name = f"{timestamp}_{path.name}"
        destination = quarantine / safe_name

        try:
            # shutil.move() moves the file (not copies — the original is removed)
            shutil.move(str(path), str(destination))
            moved_files.append({
                "original": str(file_path),
                "quarantined_as": str(destination)
            })
            print(f"  [+] Moved to quarantine: {destination.name}")

        except PermissionError:
            print(f"  [!] Permission denied — could not move {path.name}")
            print("  [*] Try running the script as administrator (Windows)")
            print("  [*] or check file permissions (Linux/Mac)")

        except Exception as e:
            print(f"  [!] Error moving file: {e}")

    return moved_files


def _hash_file(file_path: Path) -> Optional[str]:
    """
    Calculate the SHA-256 hash of a file's contents.

    Two files with the same hash have identical content.
    SHA-256 is a one-way mathematical function — you can't get the
    original file back from its hash, but you can compare hashes.

    Returns the hash string, or None if the file can't be read.
    """
    try:
        sha256 = hashlib.sha256()

        # Read the file in chunks to avoid loading huge files into memory
        # 65536 bytes = 64 KB per chunk
        with open(file_path, "rb") as f:
            while True:
                chunk = f.read(65536)
                if not chunk:
                    break
                sha256.update(chunk)

        return sha256.hexdigest()

    except (PermissionError, OSError):
        return None


def run_interactive(config: dict):
    """
    Interactive menu for the file scanner.
    Called from main.py.
    """

    print("\n" + "=" * 50)
    print("  Noeau File Scanner")
    print("=" * 50)
    print()
    print("  Enter the folder path to scan.")
    print("  Examples:")
    print("    Windows: C:\\Users\\YourName\\Documents")
    print("    Linux:   /home/yourname/Documents")
    print("    Shortcut: ~/Documents")
    print()

    folder = input("  Folder to scan [or Enter to cancel]: ").strip()

    if not folder:
        print("  [*] Cancelled.")
        return

    # Get the scan settings from config
    scan_config = config.get("scan_defaults", {})
    huge_mb = scan_config.get("huge_file_mb", 100)
    suspicious_exts = scan_config.get("suspicious_extensions")

    # Run the scan
    results = scan_folder(
        folder_path=folder,
        huge_file_mb=huge_mb,
        suspicious_extensions=suspicious_exts
    )

    if not results:
        return

    # Show the report
    print_report(results)

    # Ask what to do with findings
    print("\n  What would you like to do?")
    print("  [1] Quarantine empty files")
    print("  [2] Quarantine suspicious files")
    print("  [3] Nothing — report only")
    print()

    action = input("  Choose [3]: ").strip()

    quarantine_folder = config.get("quarantine", {}).get("folder", "quarantine")
    # Make quarantine path relative to the noeau folder
    quarantine_path = Path(__file__).parent.parent / quarantine_folder

    if action == "1" and results.get("empty_files"):
        empty_paths = [f["path"] for f in results["empty_files"]]
        print(f"\n  [*] Will offer to quarantine {len(empty_paths)} empty file(s).")
        quarantine_files(empty_paths, str(quarantine_path))

    elif action == "2" and results.get("suspicious_files"):
        suspicious_paths = [f["path"] for f in results["suspicious_files"]]
        print(f"\n  [*] Will offer to quarantine {len(suspicious_paths)} suspicious file(s).")
        print("  [!] Only quarantine files you don't recognize.")
        quarantine_files(suspicious_paths, str(quarantine_path))

    else:
        print("  [*] No files moved. Report complete.")

    return results
