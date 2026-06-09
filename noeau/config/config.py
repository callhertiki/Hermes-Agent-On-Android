"""
config.py — Noeau Guardian Configuration Loader

This module handles reading and writing the config.json file.
All settings the user can customize live in config.json.
This file just loads them and makes them easy to use.
"""

import json
import os
from pathlib import Path


# The config file lives in the same folder as this script.
# Path(__file__) gives us the path to THIS file (config.py).
# .parent gives us the folder it's in.
CONFIG_FILE = Path(__file__).parent / "config.json"


def load_config():
    """
    Load the configuration from config.json.

    Returns a dictionary with all settings.
    If the file doesn't exist or is broken, returns default settings.
    """

    # Check if the config file exists
    if not CONFIG_FILE.exists():
        print(f"[!] Config file not found at: {CONFIG_FILE}")
        print("[*] Using default settings.")
        return _default_config()

    try:
        # Open the file and parse it as JSON
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            config = json.load(f)
        return config

    except json.JSONDecodeError as e:
        # The file exists but isn't valid JSON
        print(f"[!] Config file has a format error: {e}")
        print("[*] Using default settings.")
        return _default_config()

    except Exception as e:
        print(f"[!] Could not read config: {e}")
        return _default_config()


def save_config(config: dict):
    """
    Save the configuration dictionary back to config.json.

    This is called when the user changes a setting.
    We write with indent=2 so the file stays human-readable.
    """
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2)
        print(f"[+] Settings saved to {CONFIG_FILE}")
        return True

    except Exception as e:
        print(f"[!] Could not save config: {e}")
        return False


def resolve_path(path_str: str) -> Path:
    """
    Convert a path string to an absolute Path object.

    Handles the ~ shortcut for the home folder.
    Example: "~/Documents" → "/home/yourname/Documents"
    """
    # os.path.expanduser turns ~ into the actual home folder path
    expanded = os.path.expanduser(path_str)
    return Path(expanded).resolve()


def _default_config() -> dict:
    """
    Return a safe default configuration if config.json is missing or broken.
    This ensures the program always has something to work with.
    """
    return {
        "backup_paths": [
            "~/Documents",
            "~/Desktop"
        ],
        "scan_defaults": {
            "huge_file_mb": 100,
            "stale_backup_days": 7,
            "suspicious_extensions": [
                ".exe", ".bat", ".cmd", ".ps1", ".vbs", ".scr"
            ],
            "skip_folders": []
        },
        "decoys": {
            "base_folder": "~/Documents",
            "folders": [
                "Passwords_OLD",
                "Passwords_DO_NOT_USE",
                "Archive_Login_Backup"
            ]
        },
        "report": {
            "save_folder": "reports",
            "keep_last_n": 30
        },
        "quarantine": {
            "folder": "quarantine",
            "ask_before_moving": True
        }
    }
