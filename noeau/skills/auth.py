"""
auth.py — Noeau Guardian: Startup PIN Protection

Protects Noeau Guardian with a PIN code on every launch.
Without the correct PIN, the program exits immediately.

HOW IT WORKS:
  1. First time you run Noeau, it asks you to create a PIN
  2. Every time after that, it asks for your PIN before the menu appears
  3. 3 wrong attempts = program closes
  4. The PIN is stored as a SHA-256 hash — never in plaintext
  5. Even if someone finds the auth.json file, they cannot reverse the hash
     back into your PIN (that's what hashing is for)

WHAT IS A HASH?
  A hash is a one-way mathematical transformation.
  "1234" → SHA-256 → "03ac674216f3e15c761ee..."
  You cannot go backwards from the hash to get "1234".
  So storing the hash is safe. Storing the PIN directly would NOT be.

CHANGING YOUR PIN:
  Go to Settings → Change Noeau PIN
"""

import hashlib
import json
import secrets
import sys
from pathlib import Path


# Where the hashed PIN is stored
AUTH_FILE = Path(__file__).parent.parent / "memory" / "auth.json"

# How many wrong attempts before the program closes
MAX_ATTEMPTS = 3


def is_pin_set() -> bool:
    """Check whether a PIN has been created yet."""
    return AUTH_FILE.exists()


def verify_on_startup() -> bool:
    """
    Called once when Noeau Guardian launches.

    If no PIN is set: walks you through creating one.
    If a PIN is set: asks for it and checks it.

    Returns True if access is granted, False if denied.
    The caller should exit the program if this returns False.
    """

    if not is_pin_set():
        # First run — no PIN exists yet, set one up
        return _first_time_setup()

    # PIN exists — verify it
    return _ask_for_pin()


def change_pin() -> bool:
    """
    Change an existing PIN.
    Requires the current PIN before allowing a change.
    Called from the Settings menu.
    """

    if not is_pin_set():
        print()
        print("  [*] No PIN is set yet. Let's create one.")
        return _first_time_setup()

    stored = _load_auth()
    if not stored:
        print("  [!] Could not read PIN file.")
        return False

    print()
    print("  Change Noeau PIN")
    print("  " + "─" * 34)
    print()

    # Must verify current PIN before changing
    current = input("  Current PIN: ").strip()
    if _hash_pin(current, stored["salt"]) != stored["hash"]:
        print("  [!] Incorrect PIN. Change cancelled.")
        return False

    print("  [+] Current PIN verified.")
    print()

    return _create_new_pin()


def remove_pin() -> bool:
    """
    Remove PIN protection entirely.
    Requires the current PIN to confirm.
    """

    if not is_pin_set():
        print("  [*] No PIN is currently set.")
        return True

    stored = _load_auth()
    if not stored:
        return False

    print()
    confirm_pin = input("  Enter current PIN to confirm removal: ").strip()
    if _hash_pin(confirm_pin, stored["salt"]) != stored["hash"]:
        print("  [!] Incorrect PIN. Removal cancelled.")
        return False

    try:
        AUTH_FILE.unlink()
        print("  [+] PIN removed. Noeau Guardian will not ask for a PIN on next launch.")
        print("  [*] You can re-enable it from Settings → Set PIN.")
        return True
    except Exception as e:
        print(f"  [!] Could not remove PIN file: {e}")
        return False


# ── INTERNAL HELPERS ─────────────────────────────────────────────────────────

def _first_time_setup() -> bool:
    """
    Walk the user through creating a PIN for the first time.
    Returns True when PIN is successfully saved.
    """

    print()
    print("  ╔══════════════════════════════════════╗")
    print("  ║  Welcome to Noeau Guardian           ║")
    print("  ║  First-time setup: create a PIN      ║")
    print("  ╚══════════════════════════════════════╝")
    print()
    print("  Your PIN protects this tool on every launch.")
    print("  Use 4–12 characters (numbers, letters, or both).")
    print("  This is stored as a hash — NOT in plain text.")
    print()

    return _create_new_pin()


def _create_new_pin() -> bool:
    """
    Ask for a new PIN twice and save it.
    Returns True if saved successfully.
    """

    for _ in range(3):  # Allow up to 3 mismatches before giving up
        pin = input("  Create PIN: ").strip()

        if len(pin) < 4:
            print("  [!] PIN must be at least 4 characters. Try again.")
            continue

        if len(pin) > 12:
            print("  [!] PIN must be 12 characters or fewer. Try again.")
            continue

        confirm = input("  Confirm PIN: ").strip()

        if pin != confirm:
            print("  [!] PINs do not match. Try again.")
            continue

        # Generate a random salt — makes each stored hash unique
        # even if two users pick the same PIN
        salt = secrets.token_hex(16)
        pin_hash = _hash_pin(pin, salt)

        AUTH_FILE.parent.mkdir(parents=True, exist_ok=True)

        try:
            with open(AUTH_FILE, "w", encoding="utf-8") as f:
                json.dump({"salt": salt, "hash": pin_hash}, f)
            print()
            print("  [+] PIN set. Noeau Guardian is now protected.")
            return True
        except Exception as e:
            print(f"  [!] Could not save PIN: {e}")
            return False

    print("  [!] Too many failed attempts. PIN not set.")
    return False


def _ask_for_pin() -> bool:
    """
    Prompt for the PIN and compare to stored hash.
    Returns True if correct within MAX_ATTEMPTS tries.
    """

    stored = _load_auth()
    if not stored:
        print("  [!] PIN file is unreadable. Access denied.")
        return False

    print()
    print("  Noeau Guardian is PIN-protected.")
    print()

    for attempt in range(1, MAX_ATTEMPTS + 1):
        pin = input("  Enter PIN: ").strip()

        if _hash_pin(pin, stored["salt"]) == stored["hash"]:
            print("  [+] Access granted.")
            print()
            return True

        remaining = MAX_ATTEMPTS - attempt
        if remaining > 0:
            print(f"  [!] Wrong PIN. {remaining} attempt(s) left.")
        else:
            print("  [!] Too many wrong attempts. Closing.")

    return False


def _hash_pin(pin: str, salt: str) -> str:
    """
    Hash a PIN with its salt using SHA-256.
    SHA-256 is a one-way function — the original PIN cannot be recovered.
    """
    combined = (salt + pin).encode("utf-8")
    return hashlib.sha256(combined).hexdigest()


def _load_auth() -> dict:
    """Load the stored salt+hash from the auth file."""
    try:
        with open(AUTH_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}
