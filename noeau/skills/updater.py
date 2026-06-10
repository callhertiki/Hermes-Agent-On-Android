"""
updater.py — Noeau Guardian: Auto-Update on Launch

Runs `git pull` automatically every time Noeau starts.
If new code is available, it downloads it silently in the background
so you always have the latest version without doing anything manually.

HOW IT WORKS:
  1. Noeau finds the root of the git repository she lives in
  2. She runs `git pull` against the remote branch
  3. If new files were downloaded, she tells you and restarts herself
  4. If already up to date, she continues silently
  5. If git is not installed or there's no internet, she skips the check

SAFETY:
  - This only pulls code from the same remote branch you cloned from
  - It will never push or modify remote files
  - If the pull fails for any reason, Noeau starts normally anyway
  - You can disable auto-update in Settings
"""

import os
import sys
import subprocess
from pathlib import Path


def check_for_updates(noeau_root: Path, silent: bool = False) -> bool:
    """
    Run `git pull` from the repo root and apply any available updates.

    Parameters:
        noeau_root — Path to the noeau/ folder (used to find repo root)
        silent     — If True, only print when an update is found

    Returns:
        True  — An update was applied (caller should restart)
        False — Already up to date or update failed
    """

    # The git repo root is one level up from noeau/
    repo_root = noeau_root.parent

    if not (repo_root / ".git").exists():
        if not silent:
            print("  [*] No git repo found — skipping update check.")
        return False

    if not silent:
        print("  [*] Checking for updates...", end=" ", flush=True)

    try:
        # Run git pull — capture output so we can check what happened
        result = subprocess.run(
            ["git", "pull"],
            cwd=str(repo_root),
            capture_output=True,
            text=True,
            timeout=15  # Don't wait more than 15 seconds
        )

        output = result.stdout.strip()

        # "Already up to date." means nothing new
        if "Already up to date" in output or "Already up-to-date" in output:
            if not silent:
                print("already up to date.")
            return False

        # Any other output means files were updated
        if result.returncode == 0 and output:
            print()
            print("  [+] UPDATE APPLIED — Noeau has been updated.")
            print(f"  [*] {output.splitlines()[0]}")
            print("  [*] Restarting with new version...")
            print()
            _restart()
            return True

        # Non-zero return code means something went wrong
        if result.returncode != 0:
            if not silent:
                err = result.stderr.strip().splitlines()
                first_err = err[0] if err else "unknown error"
                print(f"could not pull ({first_err})")
            return False

    except FileNotFoundError:
        # git is not installed
        if not silent:
            print("git not found — skipping.")
        return False

    except subprocess.TimeoutExpired:
        if not silent:
            print("timed out — skipping.")
        return False

    except Exception as e:
        if not silent:
            print(f"skipped ({e})")
        return False

    return False


def _restart():
    """
    Restart the current Python process with the same arguments.
    This loads the newly downloaded code without you doing anything.
    """
    python = sys.executable  # Path to the current Python interpreter
    os.execv(python, [python] + sys.argv)
