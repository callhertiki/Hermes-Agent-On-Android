"""
main.py — Noeau Guardian: Main Entry Point

This is the file you run. It shows the main menu and routes
you to the right tool based on your choice.

HOW TO RUN:
    Windows:  python main.py
    Linux:    python3 main.py
    Kali:     python3 main.py

REQUIREMENTS:
    - Python 3.8 or newer
    - No external packages needed — uses only Python's standard library

WHAT IS NOEAU GUARDIAN?
    A local, offline defensive security assistant for your own system.
    It protects your files, passwords, backups, and system health.
    It NEVER sends data anywhere. It NEVER deletes files automatically.
    All operations ask for your confirmation before making changes.
"""

import sys
import os
from pathlib import Path

# ── PATH SETUP ───────────────────────────────────────────────────────────────
# Make sure Python can find all our modules (skills, config, etc.)
# regardless of which directory you run this script from.
# Path(__file__) = the path to THIS file (main.py)
# .parent = the folder it's in (noeau/)
NOEAU_ROOT = Path(__file__).parent.resolve()
sys.path.insert(0, str(NOEAU_ROOT))

# ── IMPORT OUR MODULES ──────────────────────────────────────────────────────
# Now we can import from skills/ and config/ as if they were in the same folder.
from config.config import load_config
from skills import password_generator, file_scanner, honeytoken, backup_checker, report_generator
from skills.auth import verify_on_startup


# ── CONSTANTS ────────────────────────────────────────────────────────────────
VERSION = "1.0.0"
NAME = "Noeau Guardian"


def main():
    """
    Main program loop. Shows the menu and handles user input.
    Runs until the user chooses to exit.
    """

    # First thing: make sure all required folders exist
    _ensure_folders_exist()

    # PIN check — must pass before anything else is shown
    # On first run this creates the PIN. After that it verifies it.
    if not verify_on_startup():
        sys.exit(1)

    # Load configuration from config/config.json
    config = load_config()

    # Main loop — keeps running until user exits
    while True:
        _print_main_menu()

        choice = input("  Choose: ").strip().upper()

        if choice == "1":
            # Password Generator
            password_generator.run_interactive()

        elif choice == "2":
            # File Scanner
            file_scanner.run_interactive(config)

        elif choice == "3":
            # Honeytoken / Decoy System
            honeytoken.run_interactive(config)

        elif choice == "4":
            # Backup Checker
            backup_checker.run_interactive(config)

        elif choice == "5":
            # Security Report
            report_generator.run_interactive(config)

        elif choice == "6":
            # Settings
            _settings_menu(config)
            # Reload config after any changes
            config = load_config()

        elif choice == "Q":
            print()
            print("  [*] Noeau Guardian closing. Stay safe.")
            print()
            sys.exit(0)

        else:
            print()
            print("  [!] Invalid choice. Enter 1-6 or Q.")

        # After each action, pause before re-showing the menu
        # so the user has time to read the output
        print()
        input("  Press Enter to return to the main menu...")


def _print_main_menu():
    """Print the main menu to the screen."""

    print()
    print("  ╔══════════════════════════════════════════════╗")
    print(f"  ║  {NAME} v{VERSION}                        ║")
    print("  ║  Local Defensive Security Assistant          ║")
    print("  ╚══════════════════════════════════════════════╝")
    print()
    print("  [1] Password Generator")
    print("      Generate strong passwords and passphrases")
    print()
    print("  [2] File Scanner")
    print("      Find empty, duplicate, huge, or suspicious files")
    print()
    print("  [3] Honeytoken Manager")
    print("      Set up and check decoy files for intrusion detection")
    print()
    print("  [4] Backup Checker")
    print("      Verify your important folders are recently backed up")
    print()
    print("  [5] Security Report")
    print("      Generate a full daily security status report")
    print()
    print("  [6] Settings")
    print("      View or edit configuration")
    print()
    print("  [Q] Quit")
    print()


def _settings_menu(config: dict):
    """Show and allow editing of current settings."""

    from config.config import save_config

    print("\n" + "=" * 50)
    print("  Noeau Settings")
    print("=" * 50)
    print()
    print("  CURRENT SETTINGS")
    print("  " + "─" * 40)

    # Show backup paths
    backup_paths = config.get("backup_paths", [])
    print(f"\n  Backup paths ({len(backup_paths)}):")
    for p in backup_paths:
        print(f"    • {p}")

    # Show scan settings
    scan = config.get("scan_defaults", {})
    print(f"\n  Large file threshold: {scan.get('huge_file_mb', 100)} MB")
    print(f"  Stale backup threshold: {scan.get('stale_backup_days', 7)} days")

    # Show decoy settings
    decoy = config.get("decoys", {})
    print(f"\n  Decoy base folder: {decoy.get('base_folder', '~/Documents')}")
    print(f"  Decoy folders: {', '.join(decoy.get('folders', []))}")

    print()
    print("  [1] Add a backup path")
    print("  [2] Remove a backup path")
    print("  [3] Change large file threshold (MB)")
    print("  [4] Change stale backup threshold (days)")
    print("  [5] View config file location")
    print("  [6] Change Noeau PIN")
    print("  [7] Remove Noeau PIN")
    print("  [B] Back")
    print()

    choice = input("  Choose: ").strip().upper()

    if choice == "1":
        new_path = input("  Enter path to add: ").strip()
        if new_path:
            config["backup_paths"].append(new_path)
            save_config(config)
            print(f"  [+] Added: {new_path}")

    elif choice == "2":
        print("  Enter the number of the path to remove:")
        for i, p in enumerate(backup_paths, 1):
            print(f"    {i}. {p}")
        idx_input = input("  Number: ").strip()
        if idx_input.isdigit():
            idx = int(idx_input) - 1
            if 0 <= idx < len(backup_paths):
                removed = config["backup_paths"].pop(idx)
                save_config(config)
                print(f"  [+] Removed: {removed}")

    elif choice == "3":
        new_mb = input("  New threshold in MB [current: "
                      f"{scan.get('huge_file_mb', 100)}]: ").strip()
        if new_mb.isdigit():
            config.setdefault("scan_defaults", {})["huge_file_mb"] = int(new_mb)
            save_config(config)
            print(f"  [+] Threshold set to {new_mb} MB")

    elif choice == "4":
        new_days = input("  New threshold in days [current: "
                        f"{scan.get('stale_backup_days', 7)}]: ").strip()
        if new_days.isdigit():
            config.setdefault("scan_defaults", {})["stale_backup_days"] = int(new_days)
            save_config(config)
            print(f"  [+] Threshold set to {new_days} days")

    elif choice == "5":
        config_path = NOEAU_ROOT / "config" / "config.json"
        print(f"\n  Config file: {config_path}")
        print("  You can edit this file directly in any text editor.")

    elif choice == "6":
        from skills.auth import change_pin
        change_pin()

    elif choice == "7":
        from skills.auth import remove_pin
        remove_pin()


def _ensure_folders_exist():
    """
    Make sure all required folders exist before the program starts.
    This prevents errors when saving reports, logs, or quarantined files.
    """
    required_folders = [
        NOEAU_ROOT / "memory",
        NOEAU_ROOT / "reports",
        NOEAU_ROOT / "quarantine",
        NOEAU_ROOT / "decoys",
        NOEAU_ROOT / "config",
        NOEAU_ROOT / "skills",
    ]

    for folder in required_folders:
        folder.mkdir(parents=True, exist_ok=True)

    # Create __init__.py files for Python package imports if missing
    for pkg_folder in ["skills", "config"]:
        init_file = NOEAU_ROOT / pkg_folder / "__init__.py"
        if not init_file.exists():
            init_file.write_text("# Noeau Guardian package\n", encoding="utf-8")


# ── ENTRY POINT ──────────────────────────────────────────────────────────────
# This block runs only when you execute this file directly:
#   python main.py
# It does NOT run if another file imports this module.

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        # Handle Ctrl+C gracefully
        print()
        print("\n  [*] Interrupted. Noeau Guardian closing.")
        print()
        sys.exit(0)
