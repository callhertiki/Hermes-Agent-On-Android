#!/usr/bin/env python3
"""
noeau_report.py — Daily learning report generator.

Usage:
    python3 ~/Noeau/scripts/noeau_report.py
    python3 ~/Noeau/scripts/noeau_report.py --date 2025-06-08
    python3 ~/Noeau/scripts/noeau_report.py --no-open

Creates:  ~/Noeau/reports/daily/YYYY-MM-DD.md

Safe: reads only inside /home/Cipher/Noeau. No network. No system files.
"""

import sys
import json
import argparse
from pathlib import Path
from datetime import datetime, date

NOEAU_ROOT    = Path("/home/Cipher/Noeau")
REPORTS_DIR   = NOEAU_ROOT / "reports" / "daily"
TRACKER_PATH  = NOEAU_ROOT / "config" / "learning_tracker.json"
PREFS_PATH    = NOEAU_ROOT / "config" / "preferences.json"

_TTY = sys.stdout.isatty()
CYN  = "\033[0;36m" if _TTY else ""
GRN  = "\033[0;32m" if _TTY else ""
YLW  = "\033[1;33m" if _TTY else ""
DIM  = "\033[2m"    if _TTY else ""
BLD  = "\033[1m"    if _TTY else ""
RST  = "\033[0m"    if _TTY else ""

# ── Data helpers ──────────────────────────────────────────────────────────────

def load_prefs() -> dict:
    if PREFS_PATH.exists():
        try:
            return json.loads(PREFS_PATH.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"user": {"name": "Cipher"}, "goals": {"daily_learning_minutes": 60}}

def load_tracker() -> dict:
    if TRACKER_PATH.exists():
        try:
            return json.loads(TRACKER_PATH.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"sessions": []}

def save_tracker(data: dict) -> None:
    TRACKER_PATH.parent.mkdir(parents=True, exist_ok=True)
    TRACKER_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

def ensure_tracker() -> None:
    """Create an empty tracker if it doesn't exist yet."""
    if not TRACKER_PATH.exists():
        save_tracker({"version": "1.0", "sessions": [],
                      "goals": {"daily_minutes": 60},
                      "streaks": {"current": 0, "longest": 0, "last_active": ""}})

# ── File discovery ────────────────────────────────────────────────────────────

def files_modified_on(target_date: str) -> list[Path]:
    """All .md files inside knowledge/ or inbox/ last modified on target_date."""
    found = []
    for folder in [NOEAU_ROOT / "knowledge", NOEAU_ROOT / "inbox"]:
        if not folder.exists():
            continue
        for f in folder.rglob("*.md"):
            try:
                mdate = datetime.fromtimestamp(f.stat().st_mtime).strftime("%Y-%m-%d")
                if mdate == target_date:
                    found.append(f)
            except OSError:
                continue
    return sorted(found, key=lambda f: f.stat().st_mtime, reverse=True)

def new_summaries_on(target_date: str) -> list[Path]:
    """PDF summary .md files created on target_date."""
    found = []
    sumdir = NOEAU_ROOT / "research" / "summaries"
    if not sumdir.exists():
        return found
    for f in sumdir.glob("*.md"):
        try:
            mdate = datetime.fromtimestamp(f.stat().st_mtime).strftime("%Y-%m-%d")
            if mdate == target_date:
                found.append(f)
        except OSError:
            continue
    return found

def inbox_snapshot() -> list[Path]:
    inbox = NOEAU_ROOT / "inbox"
    if not inbox.exists():
        return []
    return sorted(
        (f for f in inbox.iterdir() if f.is_file() and not f.name.startswith(".")),
        key=lambda f: f.stat().st_mtime, reverse=True,
    )

def get_preview(filepath: Path, max_chars: int = 250) -> str:
    try:
        raw = filepath.read_text(encoding="utf-8", errors="ignore")
        # Strip YAML frontmatter
        if raw.startswith("---"):
            end = raw.find("\n---", 3)
            raw = raw[end + 4:].strip() if end > 0 else raw
        lines = [
            ln.strip() for ln in raw.splitlines()
            if ln.strip()
            and not ln.startswith("#")
            and not ln.startswith(">")
            and not ln.startswith("*")
            and not ln.startswith("|")
        ]
        preview = " ".join(lines)[:max_chars]
        return (preview + "…") if len(preview) >= max_chars else preview
    except Exception:
        return ""

def compute_streak(sessions: list[dict]) -> tuple[int, int]:
    """Return (current_streak_days, longest_streak_days)."""
    if not sessions:
        return 0, 0
    dates = sorted({s.get("date", "") for s in sessions if s.get("date")}, reverse=True)
    today     = date.today()
    check     = today
    current   = 0
    for d in dates:
        try:
            dt = date.fromisoformat(d)
        except ValueError:
            continue
        if dt == check or (current == 0 and dt == today - __import__("datetime").timedelta(days=1)):
            current += 1
            check = dt - __import__("datetime").timedelta(days=1)
        elif dt < check:
            break
    return current, current   # longest tracked separately via tracker JSON

# ── Report builder ────────────────────────────────────────────────────────────

def build_report(target_date: str) -> str:
    prefs   = load_prefs()
    tracker = load_tracker()

    modified     = files_modified_on(target_date)
    new_summs    = new_summaries_on(target_date)
    inbox_items  = inbox_snapshot()
    sessions     = [s for s in tracker.get("sessions", [])
                    if s.get("date") == target_date]
    total_min    = sum(int(s.get("duration_minutes", 0)) for s in sessions)
    goal_min     = int(prefs.get("goals", {}).get("daily_learning_minutes", 60))
    pct          = min(100, int(total_min / max(goal_min, 1) * 100))
    topics_used  = sorted({s.get("topic", "—") for s in sessions})
    topics_str   = ", ".join(topics_used) if topics_used else "—"
    streak, _    = compute_streak(tracker.get("sessions", []))

    dt_obj      = datetime.strptime(target_date, "%Y-%m-%d")
    day_display = dt_obj.strftime("%A, %B %-d, %Y")

    out = []
    out += [
        f"# Daily Learning Report — {target_date}",
        "",
        f"> *{day_display}*",
        "",
        "---",
        "",
        "## Summary",
        "",
        "| Field | Value |",
        "|-------|-------|",
        f"| Topics | {topics_str} |",
        f"| Learning time | {total_min} min |",
        f"| Daily goal ({goal_min} min) | {pct}% |",
        f"| Notes modified today | {len(modified)} |",
        f"| New PDF summaries | {len(new_summs)} |",
        f"| Inbox items pending | {len(inbox_items)} |",
        f"| Current streak | {streak} days |",
        "",
        "---",
        "",
    ]

    # Knowledge files touched today
    if modified:
        out += ["## Notes Modified Today", ""]
        for f in modified:
            try:
                rel   = f.relative_to(NOEAU_ROOT)
                topic = f.parent.name
                title = f.stem.lstrip("0123456789-").replace("-", " ").title()
                preview = get_preview(f)
                out += [f"### [{topic}] {title}", "", f"*`{rel}`*", ""]
                if preview:
                    out += [f"> {preview}", ""]
                out += ["---", ""]
            except Exception:
                continue
    else:
        out += ["## Notes Modified Today", "", "_No notes captured or modified today._", "", ""]

    # Learning sessions from tracker
    if sessions:
        out += ["## Learning Sessions", "",
                "| Topic | Minutes | Notes |",
                "|-------|---------|-------|"]
        for s in sessions:
            notes = s.get("notes", "").replace("|", "‌|")
            out.append(f"| {s.get('topic','—')} | {s.get('duration_minutes',0)} | {notes} |")
        out += [""]

    # New PDF summaries
    if new_summs:
        out += ["## New PDF Summaries", ""]
        for s in new_summs:
            out.append(f"- [[research/summaries/{s.name}]]")
        out += [""]

    # Inbox
    if inbox_items:
        out += ["## Inbox  _(needs processing)_", ""]
        for item in inbox_items[:15]:
            size_kb = item.stat().st_size // 1024
            out.append(f"- `{item.name}`  ({size_kb} KB)")
        if len(inbox_items) > 15:
            out.append(f"- … and {len(inbox_items) - 15} more")
        out += [""]

    # Goal progress bar (text)
    filled = min(20, int(pct / 5))
    bar = "█" * filled + "░" * (20 - filled)
    out += [
        "## Goal Progress",
        "",
        f"```",
        f"Daily learning:  {bar}  {total_min}/{goal_min} min  ({pct}%)",
        f"```",
        "",
        "---",
        f"*Generated by Noʻeau Knowledge System — {datetime.now().strftime('%Y-%m-%d %H:%M')}*",
    ]

    return "\n".join(out)

# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Generate a daily markdown learning report.",
    )
    parser.add_argument("--date", default=date.today().strftime("%Y-%m-%d"),
                        help="Target date (YYYY-MM-DD, default: today)")
    parser.add_argument("--no-open", action="store_true",
                        help="Skip the prompt to open the report")
    args = parser.parse_args()

    if not NOEAU_ROOT.exists():
        print(f"ERROR: {NOEAU_ROOT} does not exist.")
        sys.exit(1)

    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    ensure_tracker()

    print(f"\n{CYN}  Generating daily report: {args.date} …{RST}")
    report   = build_report(args.date)
    out_path = REPORTS_DIR / f"{args.date}.md"
    out_path.write_text(report, encoding="utf-8")

    lines = report.count("\n") + 1
    print(f"{GRN}  ✓ Saved:{RST} {out_path}")
    print(f"{DIM}    {lines} lines written{RST}\n")

    if not args.no_open:
        answer = input("  Open report in terminal? [y/N] ").strip().lower()
        if answer == "y":
            print()
            print(report)
            print()


if __name__ == "__main__":
    main()
