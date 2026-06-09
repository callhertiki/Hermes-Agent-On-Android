"""
honeytoken.py — Noeau Guardian: Decoy / Honeytoken System

A honeytoken is a fake file or resource designed to attract attackers.
If someone is snooping through your files, they'll likely open anything
that looks like it contains passwords or credentials.

When our decoy files are touched, we know someone was looking.

HOW IT WORKS:
  1. We create fake folders with names like "Passwords_OLD"
  2. Inside, we put text files that LOOK like they have credentials
  3. The content is clearly marked as FAKE internally (but looks real from outside)
  4. We record the "last modified" time of each decoy as a baseline
  5. When you run a check, we compare current times to the baseline
  6. If a file's time changed, someone (or something) touched it

IMPORTANT NOTES ON ACCESS DETECTION:
  - This script detects MODIFICATIONS (file was changed) reliably.
  - Detecting READ-ONLY access (someone opened but didn't change the file):
    * Windows: Access time tracking is disabled by default for performance.
      To enable: run `fsutil behavior set disablelastaccess 0` as Administrator
    * Linux/Kali: Access times work if the filesystem is NOT mounted with
      `noatime` option. Check with: `cat /proc/mounts | grep noatime`
    * For production-grade detection, use Windows Audit Policy or Linux auditd.

SAFETY RULES:
  - Decoy files contain NO real usernames, passwords, or credentials.
  - Files are clearly marked as DECOY in their internal content.
  - Nothing in these files can be used to access any real account.
"""

import os
import json
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Optional


# ── BASELINE FILE ────────────────────────────────────────────────────────────
# We store the "normal" state of decoy files here.
# When we check decoys later, we compare to this baseline.
BASELINE_FILE = Path(__file__).parent.parent / "memory" / "honeytoken_baseline.json"

# ── DECOY LOG ────────────────────────────────────────────────────────────────
# When we detect that a decoy was touched, we log it here.
HONEYTOKEN_LOG = Path(__file__).parent.parent / "memory" / "honeytoken_alerts.json"


# ── DECOY FILE CONTENT TEMPLATES ────────────────────────────────────────────
# These templates look like real credential files from outside.
# BUT they contain a clear DECOY marker inside.
# IMPORTANT: These contain NO real credentials. All entries are fake.

DECOY_CONTENT_TEMPLATES = {
    "credentials_archive.txt": """\
# NOEAU_HONEYTOKEN_MARKER: DECOY_FILE_v1
# ============================================================
# IMPORTANT: This file is a security decoy.
# It contains NO real credentials.
# If you are reading this file, a security alert has been logged.
# Authorized users: please close this file and notify your sysadmin.
# ============================================================

[Archived Credentials — OUTDATED AND INVALID]
Last rotation: 2022-01-15
Status: DEPRECATED — All accounts have been migrated

Note: These entries are placeholders from the migration.
Active credentials are stored in KeePassXC only.

Service:  old_webmail
User:     archived_user_a
Pass:     [MIGRATED — NOT STORED HERE]

Service:  old_vpn
User:     archived_user_b
Pass:     [MIGRATED — NOT STORED HERE]

-- END OF ARCHIVE --
This file has not been updated since migration.
""",

    "old_passwords.txt": """\
# NOEAU_HONEYTOKEN_MARKER: DECOY_FILE_v1
# ============================================================
# SECURITY DECOY — Contains no valid credentials.
# Opening this file has been logged by Noeau Guardian.
# ============================================================

DO NOT USE — PASSWORDS CHANGED
================================

These were the passwords before the 2022 migration.
All accounts now use unique passwords stored in KeePassXC.

Legacy format:
[ENTRY] account=placeholder_a | pass=REPLACED_2022
[ENTRY] account=placeholder_b | pass=REPLACED_2022
[ENTRY] account=placeholder_c | pass=REPLACED_2022

If you need current access credentials, use your password manager.
""",

    "backup_logins.txt": """\
# NOEAU_HONEYTOKEN_MARKER: DECOY_FILE_v1
# ============================================================
# HONEYTOKEN FILE — Opening this file triggers an alert.
# No real credentials are contained in this file.
# ============================================================

[BACKUP LOGIN ARCHIVE — INACTIVE]
Created: 2021-09-01
Archived: 2022-03-15

All entries below are PLACEHOLDER values from the old system.
Real backups are encrypted and stored separately.

backup_service_1 — user: [archived] — key: [rotated]
backup_service_2 — user: [archived] — key: [rotated]
cloud_backup      — token: [EXPIRED_2022]

Contact system admin for current backup credentials.
"""
}


def create_decoys(base_folder: str, decoy_folder_names: list) -> dict:
    """
    Create the decoy folder structure and populate with fake credential files.

    Parameters:
        base_folder        — Where to create the decoy folders (e.g., ~/Documents)
        decoy_folder_names — List of folder names (e.g., ["Passwords_OLD", ...])

    Returns:
        Dictionary of created paths.
    """

    base = Path(base_folder).expanduser().resolve()
    created = []

    print(f"\n[*] Creating decoy files in: {base}")
    print("[*] All content is fake — no real credentials will be stored.")
    print()

    for folder_name in decoy_folder_names:
        decoy_folder = base / folder_name

        # Create the folder
        try:
            decoy_folder.mkdir(parents=True, exist_ok=True)
            print(f"  [+] Created folder: {decoy_folder}")

            # Add decoy files to this folder
            for filename, content in DECOY_CONTENT_TEMPLATES.items():
                decoy_file = decoy_folder / filename
                if not decoy_file.exists():
                    decoy_file.write_text(content, encoding="utf-8")
                    print(f"      [+] Created file: {filename}")
                else:
                    print(f"      [*] Already exists: {filename} — skipped")

            # Add a README so YOU remember what this folder is
            readme_path = decoy_folder / "_NOEAU_DECOY_README.txt"
            readme_content = (
                f"NOEAU GUARDIAN DECOY FOLDER\n"
                f"===========================\n"
                f"This folder is a security decoy created by Noeau Guardian.\n"
                f"Created: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
                f"Folder:  {folder_name}\n\n"
                f"Files in this folder contain NO real credentials.\n"
                f"If these files are accessed by an unauthorized user,\n"
                f"it will be detected during the next Noeau check.\n\n"
                f"DO NOT delete this folder — it is part of your security setup.\n"
            )
            readme_path.write_text(readme_content, encoding="utf-8")
            created.append(str(decoy_folder))

        except PermissionError:
            print(f"  [!] Permission denied: cannot create {decoy_folder}")
        except Exception as e:
            print(f"  [!] Error creating {folder_name}: {e}")

    # Save the baseline so we can detect future changes
    print()
    print("[*] Saving baseline state of decoy files...")
    baseline = _build_baseline(created)
    _save_baseline(baseline)

    print(f"[+] Decoy setup complete. {len(created)} folder(s) created.")
    print("[*] Baseline saved. Run 'Check Decoy Status' to detect tampering.")

    return {"created_folders": created, "baseline_saved": True}


def check_decoys(base_folder: str, decoy_folder_names: list) -> dict:
    """
    Check whether any decoy files have been accessed or modified.

    Compares current file state to the stored baseline.
    Reports any files that have changed since the baseline was set.

    Returns a dictionary with any alerts found.
    """

    baseline = _load_baseline()

    if not baseline:
        print("[!] No baseline found. Run 'Create Decoys' first to set up the baseline.")
        return {"alerts": [], "status": "no_baseline"}

    print("\n[*] Checking decoy file status...")
    alerts = []

    base = Path(base_folder).expanduser().resolve()

    for folder_name in decoy_folder_names:
        decoy_folder = base / folder_name

        if not decoy_folder.exists():
            print(f"  [!] Decoy folder MISSING: {decoy_folder}")
            alerts.append({
                "type": "FOLDER_MISSING",
                "path": str(decoy_folder),
                "severity": "HIGH",
                "message": f"Decoy folder was deleted or moved: {folder_name}",
                "time": datetime.now().isoformat()
            })
            continue

        # Check each file in the decoy folder
        for file_path in decoy_folder.iterdir():
            if file_path.is_file():
                file_key = str(file_path)
                current_state = _get_file_state(file_path)

                if file_key in baseline:
                    old_state = baseline[file_key]

                    # Check if modification time changed
                    if current_state["mtime"] != old_state["mtime"]:
                        alert = {
                            "type": "DECOY_MODIFIED",
                            "path": file_key,
                            "severity": "HIGH",
                            "message": f"ALERT: Decoy file was modified! {file_path.name}",
                            "old_mtime": old_state["mtime"],
                            "new_mtime": current_state["mtime"],
                            "time": datetime.now().isoformat()
                        }
                        alerts.append(alert)
                        print(f"  [!!!] MODIFIED: {file_path.name}")

                    # Check if file size changed (could indicate content was added)
                    elif current_state["size"] != old_state["size"]:
                        alert = {
                            "type": "DECOY_SIZE_CHANGED",
                            "path": file_key,
                            "severity": "MEDIUM",
                            "message": f"WARNING: Decoy file size changed! {file_path.name}",
                            "old_size": old_state["size"],
                            "new_size": current_state["size"],
                            "time": datetime.now().isoformat()
                        }
                        alerts.append(alert)
                        print(f"  [!!] SIZE CHANGED: {file_path.name}")

                    else:
                        print(f"  [+] OK: {file_path.name}")

                else:
                    # This file wasn't in the original baseline
                    print(f"  [?] New file in decoy folder (not in baseline): {file_path.name}")

    # Save any alerts to the log
    if alerts:
        _log_alerts(alerts)
        print()
        print(f"  [!!!] {len(alerts)} ALERT(S) DETECTED")
        print("  [*] Alerts saved to memory/honeytoken_alerts.json")
    else:
        print()
        print("  [+] All decoy files are untouched. No alerts.")

    return {"alerts": alerts, "checked_time": datetime.now().isoformat()}


def update_baseline(base_folder: str, decoy_folder_names: list):
    """
    Rebuild the baseline from current file state.

    Call this after:
    - You intentionally modified a decoy file
    - You added new decoy files
    - You want to reset after a false alarm

    This is like saying "the current state is the new normal."
    """

    base = Path(base_folder).expanduser().resolve()
    all_paths = []

    for folder_name in decoy_folder_names:
        decoy_folder = base / folder_name
        if decoy_folder.exists():
            all_paths.append(str(decoy_folder))

    if not all_paths:
        print("[!] No decoy folders found to baseline.")
        return

    baseline = _build_baseline(all_paths)
    _save_baseline(baseline)
    print(f"[+] Baseline updated. {len(baseline)} file states recorded.")


def view_alert_log():
    """Display the honeytoken alert log."""

    if not HONEYTOKEN_LOG.exists():
        print("[*] No alerts logged yet. Decoys are clean.")
        return

    try:
        with open(HONEYTOKEN_LOG, "r", encoding="utf-8") as f:
            alerts = json.load(f)

        if not alerts:
            print("[*] Alert log is empty.")
            return

        print(f"\n  HONEYTOKEN ALERT LOG ({len(alerts)} alerts)")
        print("  " + "─" * 50)
        for i, alert in enumerate(alerts, 1):
            print(f"\n  Alert #{i}")
            print(f"  Type:     {alert.get('type', 'Unknown')}")
            print(f"  Severity: {alert.get('severity', 'Unknown')}")
            print(f"  Message:  {alert.get('message', 'No message')}")
            print(f"  Path:     {alert.get('path', 'Unknown')}")
            print(f"  Time:     {alert.get('time', 'Unknown')}")

    except Exception as e:
        print(f"[!] Could not read alert log: {e}")


# ── INTERNAL HELPER FUNCTIONS ────────────────────────────────────────────────
# These functions are used internally — you don't call them directly.

def _get_file_state(file_path: Path) -> dict:
    """
    Get the current state of a file: size and modification time.
    Used to detect changes between baseline and current state.
    """
    try:
        stat = file_path.stat()
        return {
            "size": stat.st_size,
            # mtime = modification time (when the file was last changed)
            # We round to 1 decimal to avoid tiny floating point differences
            "mtime": round(stat.st_mtime, 1)
        }
    except Exception:
        return {"size": -1, "mtime": -1}


def _build_baseline(folder_paths: list) -> dict:
    """
    Record the current state of all files in the given folders.
    Returns a dictionary mapping file paths to their state.
    """
    baseline = {}
    for folder_path in folder_paths:
        folder = Path(folder_path)
        if folder.exists():
            for file_path in folder.rglob("*"):
                if file_path.is_file():
                    baseline[str(file_path)] = _get_file_state(file_path)
    return baseline


def _save_baseline(baseline: dict):
    """Save the baseline dictionary to the memory folder."""
    BASELINE_FILE.parent.mkdir(parents=True, exist_ok=True)
    try:
        with open(BASELINE_FILE, "w", encoding="utf-8") as f:
            json.dump(baseline, f, indent=2)
    except Exception as e:
        print(f"[!] Could not save baseline: {e}")


def _load_baseline() -> dict:
    """Load the saved baseline, or return empty dict if it doesn't exist."""
    if not BASELINE_FILE.exists():
        return {}
    try:
        with open(BASELINE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def _log_alerts(new_alerts: list):
    """Append new alerts to the alert log file."""
    existing = []
    if HONEYTOKEN_LOG.exists():
        try:
            with open(HONEYTOKEN_LOG, "r", encoding="utf-8") as f:
                existing = json.load(f)
        except Exception:
            existing = []

    all_alerts = existing + new_alerts

    HONEYTOKEN_LOG.parent.mkdir(parents=True, exist_ok=True)
    try:
        with open(HONEYTOKEN_LOG, "w", encoding="utf-8") as f:
            json.dump(all_alerts, f, indent=2)
    except Exception as e:
        print(f"[!] Could not save alert log: {e}")


def run_interactive(config: dict):
    """Interactive honeytoken menu. Called from main.py."""

    decoy_config = config.get("decoys", {})
    base_folder = decoy_config.get("base_folder", "~/Documents")
    folder_names = decoy_config.get("folders", [])

    print("\n" + "=" * 50)
    print("  Noeau Honeytoken System")
    print("=" * 50)
    print(f"  Base folder: {base_folder}")
    print(f"  Decoy folders: {', '.join(folder_names)}")
    print()
    print("  [1] Create decoy files (first time setup)")
    print("  [2] Check if decoys were touched")
    print("  [3] Update baseline (after intentional changes)")
    print("  [4] View alert log")
    print("  [B] Back")
    print()

    choice = input("  Choose: ").strip().upper()

    if choice == "1":
        print()
        print("  [!] This will create decoy folders in:", base_folder)
        print("  [!] Content is FAKE — no real passwords will be stored.")
        confirm = input("  Proceed? [y/N]: ").strip().lower()
        if confirm == "y":
            create_decoys(base_folder, folder_names)

    elif choice == "2":
        check_decoys(base_folder, folder_names)

    elif choice == "3":
        update_baseline(base_folder, folder_names)

    elif choice == "4":
        view_alert_log()

    elif choice == "B":
        return

    else:
        print("[!] Invalid choice.")
