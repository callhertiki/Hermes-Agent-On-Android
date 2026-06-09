"""
backup_checker.py — Noeau Guardian: Backup Health Checker

Checks whether your important folders exist and when they were
last modified. Tells you if a backup is missing, stale, or OK.

A "stale" backup is one that hasn't been updated in too long —
meaning your most recent data might not be backed up.

WHAT IT CHECKS:
  - Does the folder/path exist?
  - When was the most recent file inside it last modified?
  - How many days ago was that?
  - Is that within your acceptable threshold?

WHAT IT DOES NOT CHECK:
  - Whether the backup is valid or readable (would require opening it)
  - Whether the backup is complete
  - Whether a cloud backup synced correctly

For full backup verification, manually restore a test file occasionally.
That's the only way to KNOW your backups actually work.
"""

import os
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional


def check_backup_paths(backup_paths: list, stale_days: int = 7) -> dict:
    """
    Check a list of folders and report their backup health.

    For each path, we check:
      1. Does it exist?
      2. When was the newest file inside it last modified?
      3. Is that recent enough (within stale_days)?

    Parameters:
        backup_paths — List of folder paths to check (strings)
        stale_days   — How many days before we consider a backup "stale"

    Returns:
        Dictionary with results for each path.
    """

    results = {
        "check_time": datetime.now().isoformat(),
        "stale_threshold_days": stale_days,
        "paths": []
    }

    print(f"\n[*] Checking {len(backup_paths)} backup path(s)...")
    print(f"[*] Stale threshold: {stale_days} days")
    print()

    for path_str in backup_paths:
        # Expand ~ to the actual home directory
        path = Path(path_str).expanduser().resolve()
        path_result = _check_single_path(path, stale_days)
        path_result["configured_path"] = path_str
        results["paths"].append(path_result)

    return results


def _check_single_path(path: Path, stale_days: int) -> dict:
    """
    Check a single backup path and return its status.

    Status values:
        "OK"      — Exists and was recently modified
        "STALE"   — Exists but hasn't been modified in too long
        "MISSING" — The path doesn't exist at all
        "EMPTY"   — The folder exists but has no files
        "ERROR"   — Something went wrong checking this path
    """

    result = {
        "path": str(path),
        "exists": False,
        "status": "UNKNOWN",
        "newest_file_age_days": None,
        "newest_file_path": None,
        "newest_file_time": None,
        "file_count": 0,
        "total_size_mb": 0,
        "notes": []
    }

    # ── CHECK 1: Does the path exist? ────────────────────────────────────
    if not path.exists():
        result["exists"] = False
        result["status"] = "MISSING"
        result["notes"].append(f"Path does not exist: {path}")
        return result

    result["exists"] = True

    # ── CHECK 2: Is it a file or folder? ─────────────────────────────────
    if path.is_file():
        # Single file backup (like a .zip or .tar.gz backup archive)
        return _check_single_file(path, stale_days, result)

    # ── CHECK 3: Scan the folder for files ───────────────────────────────
    newest_mtime = None
    newest_file = None
    file_count = 0
    total_size = 0

    try:
        # Walk through all files in the folder recursively
        for file_path in path.rglob("*"):
            if file_path.is_file():
                try:
                    stat = file_path.stat()
                    file_count += 1
                    total_size += stat.st_size

                    # Track the most recently modified file
                    if newest_mtime is None or stat.st_mtime > newest_mtime:
                        newest_mtime = stat.st_mtime
                        newest_file = file_path

                except (PermissionError, OSError):
                    # Skip files we can't access
                    pass

    except PermissionError:
        result["status"] = "ERROR"
        result["notes"].append("Permission denied — cannot scan this folder")
        return result

    result["file_count"] = file_count
    result["total_size_mb"] = round(total_size / (1024 * 1024), 1)

    # ── CHECK 4: Was the folder empty? ───────────────────────────────────
    if file_count == 0:
        result["status"] = "EMPTY"
        result["notes"].append("No files found in this folder or its subfolders")
        return result

    # ── CHECK 5: How old is the newest file? ─────────────────────────────
    if newest_mtime is not None:
        # Convert the modification timestamp to a readable datetime
        newest_datetime = datetime.fromtimestamp(newest_mtime)
        age_delta = datetime.now() - newest_datetime
        age_days = age_delta.days

        result["newest_file_path"] = str(newest_file)
        result["newest_file_time"] = newest_datetime.strftime("%Y-%m-%d %H:%M")
        result["newest_file_age_days"] = age_days

        # Determine status based on age
        if age_days <= stale_days:
            result["status"] = "OK"
            result["notes"].append(
                f"Most recent file: {age_days} day(s) ago — within threshold"
            )
        else:
            result["status"] = "STALE"
            result["notes"].append(
                f"Most recent file: {age_days} day(s) ago — OLDER THAN {stale_days} DAY THRESHOLD"
            )
            result["notes"].append(
                "Consider running your backup soon."
            )

    return result


def _check_single_file(path: Path, stale_days: int, result: dict) -> dict:
    """Check a single file backup (like a .zip archive)."""
    try:
        stat = path.stat()
        size_mb = stat.st_size / (1024 * 1024)
        mod_time = datetime.fromtimestamp(stat.st_mtime)
        age_days = (datetime.now() - mod_time).days

        result["file_count"] = 1
        result["total_size_mb"] = round(size_mb, 1)
        result["newest_file_path"] = str(path)
        result["newest_file_time"] = mod_time.strftime("%Y-%m-%d %H:%M")
        result["newest_file_age_days"] = age_days

        if age_days <= stale_days:
            result["status"] = "OK"
        else:
            result["status"] = "STALE"
            result["notes"].append(
                f"Backup file is {age_days} days old — older than {stale_days} day threshold"
            )

    except Exception as e:
        result["status"] = "ERROR"
        result["notes"].append(f"Error reading file: {e}")

    return result


def print_backup_report(results: dict):
    """
    Print a human-readable backup health report.
    """

    print()
    print("=" * 60)
    print("  NOEAU BACKUP HEALTH REPORT")
    print(f"  Checked:   {results.get('check_time', 'Unknown')}")
    print(f"  Threshold: {results.get('stale_threshold_days', 7)} days")
    print("=" * 60)

    paths = results.get("paths", [])

    # Count status types for a summary
    status_counts = {"OK": 0, "STALE": 0, "MISSING": 0, "EMPTY": 0, "ERROR": 0}

    for path_result in paths:
        status = path_result.get("status", "UNKNOWN")
        if status in status_counts:
            status_counts[status] += 1

        # Pick an emoji based on status
        status_icon = {
            "OK": "✓",
            "STALE": "⚠",
            "MISSING": "✗",
            "EMPTY": "○",
            "ERROR": "!"
        }.get(status, "?")

        print()
        print(f"  [{status_icon}] {path_result.get('configured_path', 'Unknown')}")
        print(f"      Status:     {status}")

        if path_result.get("newest_file_time"):
            print(f"      Last file:  {path_result['newest_file_time']}")

        if path_result.get("newest_file_age_days") is not None:
            print(f"      Age:        {path_result['newest_file_age_days']} day(s)")

        if path_result.get("file_count"):
            print(f"      Files:      {path_result['file_count']}")

        if path_result.get("total_size_mb"):
            print(f"      Size:       {path_result['total_size_mb']} MB")

        for note in path_result.get("notes", []):
            print(f"      Note:       {note}")

    # Summary
    print()
    print("  " + "─" * 50)
    print(f"  SUMMARY:  ✓ OK: {status_counts['OK']}  "
          f"⚠ Stale: {status_counts['STALE']}  "
          f"✗ Missing: {status_counts['MISSING']}  "
          f"○ Empty: {status_counts['EMPTY']}")

    # Overall health assessment
    if status_counts["MISSING"] > 0 or status_counts["STALE"] > 0:
        print()
        print("  [!] RECOMMENDATION: Some backups need attention.")
        if status_counts["MISSING"] > 0:
            print("  [!] Missing paths — check if backup drives are connected.")
        if status_counts["STALE"] > 0:
            print("  [!] Stale paths — run your backup software now.")
    else:
        print()
        print("  [+] All backups are within the acceptable threshold.")

    print("=" * 60)


def get_backup_summary(results: dict) -> str:
    """
    Return a one-line backup status summary for use in reports.
    Example: "Backups: 3 OK, 1 STALE, 0 MISSING"
    """
    paths = results.get("paths", [])
    counts = {}
    for p in paths:
        status = p.get("status", "UNKNOWN")
        counts[status] = counts.get(status, 0) + 1

    parts = []
    for status in ["OK", "STALE", "MISSING", "EMPTY", "ERROR"]:
        if status in counts:
            parts.append(f"{counts[status]} {status}")

    return "Backups: " + ", ".join(parts) if parts else "Backups: No data"


def run_interactive(config: dict):
    """Interactive backup checker. Called from main.py."""

    backup_paths = config.get("backup_paths", [])
    stale_days = config.get("scan_defaults", {}).get("stale_backup_days", 7)

    print("\n" + "=" * 50)
    print("  Noeau Backup Checker")
    print("=" * 50)
    print(f"  Configured paths ({len(backup_paths)}):")
    for p in backup_paths:
        print(f"    • {p}")
    print()
    print("  [1] Check all configured backup paths")
    print("  [2] Check a custom path")
    print("  [B] Back")
    print()

    choice = input("  Choose: ").strip().upper()

    if choice == "1":
        results = check_backup_paths(backup_paths, stale_days)
        print_backup_report(results)
        return results

    elif choice == "2":
        custom_path = input("  Enter path to check: ").strip()
        if custom_path:
            results = check_backup_paths([custom_path], stale_days)
            print_backup_report(results)
            return results

    elif choice == "B":
        return

    return None
