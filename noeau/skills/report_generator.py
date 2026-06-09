"""
report_generator.py — Noeau Guardian: Security Report Generator

Assembles all the individual checks (backup, decoys, file scan)
into a single, readable security report and saves it to the
reports/ folder with a timestamp.

Reports are plain text files — readable in any text editor,
easy to archive, and easy to compare over time.
"""

import os
import json
from pathlib import Path
from datetime import datetime
from typing import Optional

# Import our other skill modules so we can run all checks
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from skills import backup_checker, honeytoken
from config.config import load_config, resolve_path


# The folder where reports are saved
REPORTS_FOLDER = Path(__file__).parent.parent / "reports"


def generate_full_report(config: dict) -> str:
    """
    Run all security checks and produce a complete report.

    This calls backup_checker, honeytoken, and collects any
    other status information to build one combined view.

    Returns the full report as a string.
    """

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    report_lines = []

    # ── HEADER ──────────────────────────────────────────────────────────
    report_lines.append("=" * 65)
    report_lines.append("  NOEAU GUARDIAN — DAILY SECURITY REPORT")
    report_lines.append(f"  Generated: {timestamp}")
    report_lines.append(f"  System:    {_get_platform()}")
    report_lines.append("=" * 65)
    report_lines.append("")

    # ── SECTION 1: BACKUP STATUS ─────────────────────────────────────────
    report_lines.append("SECTION 1 — BACKUP STATUS")
    report_lines.append("─" * 65)

    try:
        backup_paths = config.get("backup_paths", [])
        stale_days = config.get("scan_defaults", {}).get("stale_backup_days", 7)

        if backup_paths:
            backup_results = backup_checker.check_backup_paths(backup_paths, stale_days)
            report_lines.extend(_format_backup_section(backup_results))
        else:
            report_lines.append("  No backup paths configured.")
            report_lines.append("  Add paths to config/config.json → backup_paths")

    except Exception as e:
        report_lines.append(f"  [!] Error checking backups: {e}")

    report_lines.append("")

    # ── SECTION 2: DECOY / HONEYTOKEN STATUS ─────────────────────────────
    report_lines.append("SECTION 2 — HONEYTOKEN / DECOY STATUS")
    report_lines.append("─" * 65)

    try:
        decoy_config = config.get("decoys", {})
        base_folder = decoy_config.get("base_folder", "~/Documents")
        folder_names = decoy_config.get("folders", [])

        decoy_results = honeytoken.check_decoys(base_folder, folder_names)
        report_lines.extend(_format_decoy_section(decoy_results))

    except Exception as e:
        report_lines.append(f"  [!] Error checking decoys: {e}")

    report_lines.append("")

    # ── SECTION 3: SYSTEM NOTES ──────────────────────────────────────────
    report_lines.append("SECTION 3 — SYSTEM NOTES")
    report_lines.append("─" * 65)
    report_lines.extend(_format_system_section())
    report_lines.append("")

    # ── SECTION 4: RECOMMENDATIONS ───────────────────────────────────────
    report_lines.append("SECTION 4 — RECOMMENDATIONS")
    report_lines.append("─" * 65)
    report_lines.extend(_generate_recommendations(config))
    report_lines.append("")

    # ── FOOTER ──────────────────────────────────────────────────────────
    report_lines.append("=" * 65)
    report_lines.append("  END OF REPORT")
    report_lines.append(f"  Next recommended check: tomorrow")
    report_lines.append("  Run 'python main.py' and select Security Report")
    report_lines.append("=" * 65)

    return "\n".join(report_lines)


def save_report(report_text: str, config: dict) -> Path:
    """
    Save the report to the reports/ folder.

    Filename format: noeau_report_2025-01-15_14-30.txt

    Also prunes old reports if we have more than the configured limit.
    """

    REPORTS_FOLDER.mkdir(parents=True, exist_ok=True)

    # Create a filename with the current timestamp
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
    filename = f"noeau_report_{timestamp}.txt"
    report_path = REPORTS_FOLDER / filename

    try:
        report_path.write_text(report_text, encoding="utf-8")
        print(f"[+] Report saved: {report_path}")

        # Remove old reports if we have too many
        keep_n = config.get("report", {}).get("keep_last_n", 30)
        _prune_old_reports(keep_n)

        return report_path

    except Exception as e:
        print(f"[!] Could not save report: {e}")
        return None


def view_last_report():
    """Load and display the most recent saved report."""

    REPORTS_FOLDER.mkdir(parents=True, exist_ok=True)

    # Get all report files, sorted by name (which includes timestamp)
    report_files = sorted(REPORTS_FOLDER.glob("noeau_report_*.txt"), reverse=True)

    if not report_files:
        print("[*] No reports found. Generate one first.")
        return

    latest = report_files[0]
    print(f"[*] Loading report: {latest.name}")
    print()

    try:
        content = latest.read_text(encoding="utf-8")
        print(content)
    except Exception as e:
        print(f"[!] Could not read report: {e}")


def list_reports():
    """Show all saved reports with their dates."""

    REPORTS_FOLDER.mkdir(parents=True, exist_ok=True)
    report_files = sorted(REPORTS_FOLDER.glob("noeau_report_*.txt"), reverse=True)

    if not report_files:
        print("[*] No reports found.")
        return

    print(f"\n  Saved Reports ({len(report_files)} total)")
    print("  " + "─" * 40)
    for i, f in enumerate(report_files, 1):
        size_kb = f.stat().st_size / 1024
        print(f"  {i:2}. {f.name}  ({size_kb:.1f} KB)")


# ── FORMATTING HELPERS ───────────────────────────────────────────────────────

def _format_backup_section(backup_results: dict) -> list:
    """Convert backup results into report lines."""
    lines = []
    paths = backup_results.get("paths", [])
    threshold = backup_results.get("stale_threshold_days", 7)

    lines.append(f"  Threshold: {threshold} days")
    lines.append("")

    for p in paths:
        status = p.get("status", "UNKNOWN")
        icon = {"OK": "[OK]", "STALE": "[!!]", "MISSING": "[XX]",
                "EMPTY": "[--]", "ERROR": "[?!]"}.get(status, "[??]")

        lines.append(f"  {icon} {p.get('configured_path', 'Unknown')}")

        if p.get("newest_file_time"):
            age = p.get("newest_file_age_days", "?")
            lines.append(f"       Last modified: {p['newest_file_time']} ({age} days ago)")

        if p.get("total_size_mb"):
            lines.append(f"       Size: {p['total_size_mb']} MB  |  "
                         f"Files: {p.get('file_count', '?')}")

        for note in p.get("notes", []):
            lines.append(f"       Note: {note}")

        lines.append("")

    return lines


def _format_decoy_section(decoy_results: dict) -> list:
    """Convert decoy check results into report lines."""
    lines = []
    alerts = decoy_results.get("alerts", [])

    if decoy_results.get("status") == "no_baseline":
        lines.append("  [--] No baseline found.")
        lines.append("       Run Honeytoken Manager → Create Decoys to set up.")
        return lines

    if not alerts:
        lines.append("  [OK] All decoy files are untouched.")
        lines.append(f"       Checked: {decoy_results.get('checked_time', 'Unknown')}")
    else:
        lines.append(f"  [!!!] {len(alerts)} ALERT(S) DETECTED")
        lines.append("")
        for alert in alerts:
            lines.append(f"  ALERT: {alert.get('message', 'Unknown alert')}")
            lines.append(f"         File: {alert.get('path', 'Unknown')}")
            lines.append(f"         Time: {alert.get('time', 'Unknown')}")
            lines.append(f"         Severity: {alert.get('severity', 'Unknown')}")
            lines.append("")

    return lines


def _format_system_section() -> list:
    """Collect basic system information for the report."""
    lines = []

    import platform

    lines.append(f"  OS:       {platform.system()} {platform.release()}")
    lines.append(f"  Python:   {platform.python_version()}")

    # Note about what's NOT checked (so you know the scope)
    lines.append("")
    lines.append("  NOT checked by this report:")
    lines.append("  • Running processes and services")
    lines.append("  • Network connections")
    lines.append("  • Installed software / update status")
    lines.append("  • Firewall rules")
    lines.append("  For those, use your OS's built-in security tools.")

    return lines


def _generate_recommendations(config: dict) -> list:
    """
    Generate context-aware recommendations based on current configuration.
    These are static best-practice reminders, not dynamic analysis.
    """
    lines = []
    recommendations = []

    # Check if backup paths look configured
    backup_paths = config.get("backup_paths", [])
    if len(backup_paths) <= 1:
        recommendations.append(
            "Add more backup paths in config.json — "
            "consider Pictures, Projects, and any external backup drives."
        )

    # Decoy setup reminder
    decoy_log = Path(__file__).parent.parent / "memory" / "honeytoken_baseline.json"
    if not decoy_log.exists():
        recommendations.append(
            "Decoy baseline not set. Run Honeytoken Manager → Create Decoys."
        )

    # Always-applicable advice
    recommendations.extend([
        "Verify your KeePassXC database is backed up.",
        "Check that your 2FA backup codes are stored securely offline.",
        "Test restoring a file from your backup at least once a month.",
        "Review which apps have permission to access your Documents folder.",
        "If on Kali: run 'sudo apt update && sudo apt upgrade' regularly.",
    ])

    for i, rec in enumerate(recommendations, 1):
        lines.append(f"  {i}. {rec}")

    return lines


def _get_platform() -> str:
    """Return a simple platform description string."""
    import platform
    return f"{platform.system()} {platform.release()} ({platform.machine()})"


def _prune_old_reports(keep_n: int):
    """Delete old report files if we have more than keep_n."""
    report_files = sorted(REPORTS_FOLDER.glob("noeau_report_*.txt"), reverse=True)
    if len(report_files) > keep_n:
        to_delete = report_files[keep_n:]
        for old_file in to_delete:
            try:
                old_file.unlink()
            except Exception:
                pass


def run_interactive(config: dict):
    """Interactive security report menu. Called from main.py."""

    print("\n" + "=" * 50)
    print("  Noeau Security Report Generator")
    print("=" * 50)
    print()
    print("  [1] Generate full security report")
    print("  [2] View most recent report")
    print("  [3] List all saved reports")
    print("  [B] Back")
    print()

    choice = input("  Choose: ").strip().upper()

    if choice == "1":
        print()
        print("[*] Running all checks — this may take a moment...")
        print()

        report_text = generate_full_report(config)

        # Print to screen
        print(report_text)

        # Save to file
        report_path = save_report(report_text, config)
        if report_path:
            print(f"\n[+] Report also saved to: {report_path}")

    elif choice == "2":
        view_last_report()

    elif choice == "3":
        list_reports()

    elif choice == "B":
        return

    else:
        print("[!] Invalid choice.")
