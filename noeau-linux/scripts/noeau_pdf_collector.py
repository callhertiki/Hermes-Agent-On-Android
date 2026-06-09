#!/usr/bin/env python3
"""
noeau_pdf_collector.py — Collect and summarise PDFs from research/PDFs/

Usage:
    python3 ~/Noeau/scripts/noeau_pdf_collector.py          # process new PDFs
    python3 ~/Noeau/scripts/noeau_pdf_collector.py --list   # list PDFs + status
    python3 ~/Noeau/scripts/noeau_pdf_collector.py --reprocess  # redo all

Safe: only reads PDFs from ~/Noeau/research/PDFs/
      writes summaries to  ~/Noeau/research/summaries/
      No network. No system file access.

If pdfplumber is not installed, creates a placeholder summary so the workflow
continues.  Install later with:  pip install pdfplumber
"""

import sys
import json
import argparse
import re
from pathlib import Path
from datetime import datetime

NOEAU_ROOT    = Path("/home/Cipher/Noeau")
PDFS_DIR      = NOEAU_ROOT / "research" / "PDFs"
SUMMARIES_DIR = NOEAU_ROOT / "research" / "summaries"
PREFS_PATH    = NOEAU_ROOT / "config" / "preferences.json"

_TTY = sys.stdout.isatty()
CYN  = "\033[0;36m" if _TTY else ""
GRN  = "\033[0;32m" if _TTY else ""
YLW  = "\033[1;33m" if _TTY else ""
RED  = "\033[0;31m" if _TTY else ""
DIM  = "\033[2m"    if _TTY else ""
BLD  = "\033[1m"    if _TTY else ""
RST  = "\033[0m"    if _TTY else ""

# ── PDF backend ────────────────────────────────────────────────────────────────

try:
    import pdfplumber as _pdfplumber
    PDF_BACKEND = "pdfplumber"
except ImportError:
    _pdfplumber = None
    PDF_BACKEND = None

# ── Topic detection ────────────────────────────────────────────────────────────

_TOPIC_KW: dict[str, list[str]] = {
    "python":              ["python","django","flask","numpy","pandas","pip","async","venv"],
    "linux":               ["linux","bash","chmod","grep","sudo","systemctl","apt","kali","debian"],
    "networking":          ["tcp","ip address","dns","dhcp","http","subnet","router","vlan","protocol","osi"],
    "cybersecurity":       ["exploit","vulnerability","cve","pentest","payload","malware","firewall","zero-day"],
    "osint":               ["osint","reconnaissance","shodan","footprint","intelligence","maltego"],
    "lds-studies":         ["latter-day saints","book of mormon","scriptures","covenant","priesthood","gospel"],
    "personal-development":["habit","productivity","mindset","discipline","growth","motivation","journal"],
}

def detect_topic(text: str) -> str:
    lower = text.lower()
    scores = {t: sum(1 for kw in kws if kw in lower) for t, kws in _TOPIC_KW.items()}
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else "research"

# ── Text extraction ────────────────────────────────────────────────────────────

def extract_text(pdf_path: Path) -> tuple[str, int]:
    """Returns (full_text, page_count). Requires pdfplumber."""
    pages = []
    with _pdfplumber.open(pdf_path) as pdf:
        count = len(pdf.pages)
        for page in pdf.pages:
            t = page.extract_text()
            if t:
                pages.append(t)
    return "\n\n".join(pages), count

def extract_key_points(text: str, n: int = 8) -> list[str]:
    """Pull the N most 'important-looking' sentences from text."""
    sentences = re.split(r"(?<=[.!?])\s+", text)
    sentences = [s.strip() for s in sentences if 50 < len(s.strip()) < 300]

    signals = ["important","note that","key","critical","define","means",
               "therefore","conclusion","first","second","third","must","always"]

    def score(s: str) -> int:
        low = s.lower()
        return sum(2 for w in signals if w in low) + (1 if re.search(r"\b\d+\b", s) else 0)

    return sorted(sentences, key=score, reverse=True)[:n]

# ── Already processed? ────────────────────────────────────────────────────────

def summary_exists(pdf_path: Path) -> bool:
    return any(SUMMARIES_DIR.glob(f"*{pdf_path.stem}*summary.md"))

# ── Summary writer ─────────────────────────────────────────────────────────────

def create_summary(pdf_path: Path) -> Path:
    today = datetime.now().strftime("%Y-%m-%d")
    stem  = pdf_path.stem

    if PDF_BACKEND:
        try:
            text, pages = extract_text(pdf_path)
            words       = len(text.split())
            topic       = detect_topic(text)
            key_points  = extract_key_points(text)
            method      = "pdfplumber"
        except Exception as e:
            text, pages, words = "", 0, 0
            topic, key_points  = "research", []
            method = f"error ({e})"
    else:
        text, pages, words = "", 0, 0
        topic, key_points  = "research", []
        method = "placeholder"

    # Key points section
    if key_points:
        kp_block = "\n".join(f"- {p}" for p in key_points)
    else:
        kp_block = (
            "- *(No text extracted — pdfplumber not installed)*\n"
            "- Install with:  `pip install pdfplumber`  then re-run this script."
        )

    # Text preview section
    if text.strip():
        preview = text[:2500] + ("…" if len(text) > 2500 else "")
        preview = preview.replace("```", "~~~")
        text_block = f"## Text Preview\n\n```text\n{preview}\n```\n"
    else:
        text_block = (
            "## Text Preview\n\n"
            "> **No text extracted.**\n"
            "> This may be an image-based/scanned PDF.\n"
            "> Install `pdfplumber` (`pip install pdfplumber`) and re-run,\n"
            "> or use OCR software (e.g. `tesseract`) to convert it first.\n"
        )

    summary = (
        f"---\n"
        f'title: "{stem}"\n'
        f"date: {today}\n"
        f"topic: {topic}\n"
        f'source: "{pdf_path.name}"\n'
        f"pages: {pages}\n"
        f"words: {words}\n"
        f"extract_method: {method}\n"
        f"type: pdf-summary\n"
        f"---\n\n"
        f"# {stem}\n\n"
        f"> **Source:** `{pdf_path.name}`  \n"
        f"> **Pages:** {pages}  ·  **Words:** ~{words:,}  \n"
        f"> **Topic:** {topic}  \n"
        f"> **Processed:** {datetime.now().strftime('%Y-%m-%d %H:%M')}  \n"
        f"> **Method:** {method}  \n\n"
        f"---\n\n"
        f"## Key Points\n\n"
        f"{kp_block}\n\n"
        f"---\n\n"
        f"{text_block}\n"
        f"---\n"
        f"*Summary created by Noʻeau PDF Collector*\n"
    )

    out = SUMMARIES_DIR / f"{today}-{stem}-summary.md"
    out.write_text(summary, encoding="utf-8")
    return out

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Summarise PDFs in ~/Noeau/research/PDFs/",
    )
    parser.add_argument("--list", action="store_true",
                        help="List PDFs and their status without processing")
    parser.add_argument("--reprocess", action="store_true",
                        help="Re-generate summaries for already-processed PDFs")
    args = parser.parse_args()

    PDFS_DIR.mkdir(parents=True, exist_ok=True)
    SUMMARIES_DIR.mkdir(parents=True, exist_ok=True)

    pdfs = sorted(PDFS_DIR.glob("*.pdf"))

    print(f"\n{CYN}  Noʻeau PDF Collector{RST}")
    print(f"{DIM}  PDFs folder:  {PDFS_DIR}{RST}\n")

    if not pdfs:
        print(f"  {YLW}No PDFs found in research/PDFs/{RST}")
        print(f"  Drop PDF files into:  {PDFS_DIR}")
        print()
        return

    # -- list mode
    if args.list:
        print(f"  {len(pdfs)} PDF(s) found:\n")
        for p in pdfs:
            done   = summary_exists(p)
            status = f"{GRN}[done]{RST}" if done else f"{YLW}[new] {RST}"
            size   = p.stat().st_size // 1024
            print(f"    {status}  {p.name}  ({size} KB)")
        print()
        return

    # -- backend info
    if PDF_BACKEND:
        print(f"  Backend: {GRN}pdfplumber{RST}  (full text extraction)\n")
    else:
        print(f"  Backend: {YLW}placeholder mode{RST} — text will NOT be extracted.")
        print(f"  {DIM}Install pdfplumber for full extraction:  pip install pdfplumber{RST}\n")

    processed = 0
    skipped   = 0
    errors    = 0

    for pdf in pdfs:
        if summary_exists(pdf) and not args.reprocess:
            print(f"  {DIM}↷ Already done: {pdf.name}{RST}")
            skipped += 1
            continue

        print(f"  {CYN}⏳{RST} {pdf.name}")
        try:
            out = create_summary(pdf)
            print(f"  {GRN}✓{RST} Summary: {out.name}")
            processed += 1
        except Exception as e:
            print(f"  {RED}✗ Failed: {e}{RST}")
            errors += 1

    print()
    parts = [f"{GRN}{processed} processed{RST}"]
    if skipped:  parts.append(f"{DIM}{skipped} skipped{RST}")
    if errors:   parts.append(f"{RED}{errors} errors{RST}")
    print(f"  Done — {', '.join(parts)}")

    if not PDF_BACKEND:
        print(f"\n  {YLW}Tip:{RST} install pdfplumber to get real text extraction:")
        print(f"       pip install pdfplumber")
    print()


if __name__ == "__main__":
    main()
