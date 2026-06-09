---
agent: guardian-check
role: Daily Guardian
cadence: daily
status: active
phase: 1-manual
tags: [automation-agent, security, backup, health]
---

# Guardian Check

> *"Security is a practice. You either have the practice, or you have a vulnerability."*

---

## Purpose

Once per day, this agent checks your backup status, reviews your current security habits, assesses vault health, and delivers a prioritized list of anything that needs attention. It runs Kiaʻi's logic on a daily cadence.

---

## What It Reads

- Last backup date (from `07-Automations/Logs` or `Noeau-OS/System/Backup-Log`)
- Vault stats: note count, any known broken links
- Security checklist status (from Kiaʻi's profile)
- Any recent incidents or concerns

## What It Writes

- SYSTEM STATUS (Green / Yellow / Red)
- Prioritized action list (High / Medium / Low)
- Appended entry to guardian-check log

---

## Output Format

```
GUARDIAN CHECK — [DATE] [TIME]
SYSTEM STATUS: 🟢 Green / 🟡 Yellow / 🔴 Red

BACKUP:
- Last backup: [date]
- Status: [OK / Overdue / Unknown]
- Action: [if needed]

SECURITY:
- [item]: [status] → [action if needed]

VAULT HEALTH:
- Notes: [count if known]
- Inbox status: [empty / items waiting]
- Action: [if needed]

PRIORITY ACTIONS:
HIGH: [list]
MEDIUM: [list]
LOW / OK: [list]

RE-CHECK: [date of next check or trigger]
```

---

## Style Rules

- Always states overall status in the first line
- High priority items are bolded and listed first
- Never alarming without cause — only flags real issues
- All cybersecurity advice is defensive only

---

## Safety Rules

- Does not assess external systems
- Security audit data stays in this vault
- No credentials, IPs, or sensitive system info in AI chat prompts

---

## Files

- Prompt: [[../Prompts/guardian-check-prompt|guardian-check-prompt.md]]
- Log: [[../Logs/guardian-check-log|guardian-check-log.md]]
- Output: [[../Outputs/guardian-check-output|guardian-check-output.md]]
