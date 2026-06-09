# Noʻeau Knowledge System — Dashboard

> *Local-first personal knowledge base for Cipher · Kali WSL*
> Last updated: auto-generated

---

## Quick Links

| Location | Path | Purpose |
|----------|------|---------|
| 📥 Inbox | `~/Noeau/inbox/` | Drop new notes and PDFs here |
| 🧠 Knowledge | `~/Noeau/knowledge/` | Topic notes and indexes |
| 🔬 Research | `~/Noeau/research/` | PDFs and summaries |
| 📊 Reports | `~/Noeau/reports/` | Daily / weekly / monthly |
| ⚙️ Scripts | `~/Noeau/scripts/` | Automation tools |
| 🔧 Config | `~/Noeau/config/` | Preferences and tracker |

---

## Knowledge Topics

| Topic | Index | Notes |
|-------|-------|-------|
| 🐍 Python | [[python/index]] | Python, pip, venv, scripting |
| 🐧 Linux | [[linux/index]] | Kali, bash, tools, sysadmin |
| 🌐 Networking | [[networking/index]] | TCP/IP, DNS, protocols |
| 🔐 Cybersecurity | [[cybersecurity/index]] | Pentesting, CVEs, defences |
| 🔍 OSINT | [[osint/index]] | Recon, intelligence gathering |
| 📈 Personal Dev | [[personal-development/index]] | Habits, goals, reflection |
| 📚 Research | [[research/index]] | Papers, PDFs, references |

---

## Daily Commands

```bash
# Search your knowledge base
python3 ~/Noeau/scripts/noeau_search.py "keyword"
python3 ~/Noeau/scripts/noeau_search.py "keyword" --topic python
python3 ~/Noeau/scripts/noeau_search.py "keyword" --type md

# Generate today's report
python3 ~/Noeau/scripts/noeau_report.py

# Process PDFs in research/PDFs/
python3 ~/Noeau/scripts/noeau_pdf_collector.py
python3 ~/Noeau/scripts/noeau_pdf_collector.py --list
```

---

## Recent Reports

> Reports are saved to `~/Noeau/reports/daily/YYYY-MM-DD.md`
> Run `python3 ~/Noeau/scripts/noeau_report.py` to generate today's.

---

## Inbox Status

> Drop `.md`, `.txt`, or `.pdf` files into `~/Noeau/inbox/`
> Run `noeau_report.py` — it will log inbox contents in the report.

---

*Noʻeau Knowledge System v1.0 · Local-only · Safe mode: ON*
