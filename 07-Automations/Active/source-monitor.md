---
agent: source-monitor
role: Source Monitor
cadence: every 8 hours
status: active
phase: 1-manual
tags: [automation-agent, research, sources]
---

# Source Monitor

> *"Your reading queue is not a wishlist. It is a commitment."*

---

## Purpose

Every 8 hours (or once per work day), this agent reviews your research queue, selects the highest-priority unread source, summarizes it if you've already read it, and creates a Discord-ready note. It keeps research from stacking up unprocessed.

---

## What It Reads

- Your reading queue (from Mea Huli's tracker or `06-Research/Index`)
- Any books, papers, or articles marked "reading" or "unread"
- Notes you've taken on sources already read

## What It Writes

- Research summary in Mea Huli's RESEARCH NOTE format
- Discord-ready version of the summary
- Updates to the reading tracker (you add them)
- Appended entry to the source-monitor log

---

## Output Format

```
SOURCE MONITOR CHECK — [DATE] [TIME]

QUEUE STATUS: [X unread / X in progress / X completed this week]
NEXT UP: [highest-priority unread source — title + why it's next]

--- IF SUMMARIZING A COMPLETED SOURCE ---

RESEARCH NOTE
Topic: [topic]
Source: [title — author]

Central Claim: [one sentence]
Key Findings:
- [finding 1]
- [finding 2]
- [finding 3]
Gaps: [what it doesn't cover]
Next Read: [what to read next]

--- DISCORD VERSION ---
[Under 1800 characters, bold headers, flat bullets]
— Noʻeau OS 🌺
```

---

## Style Rules

- Never summarizes without reading the source first
- Marks [UNCLEAR] rather than guessing at unclear sections
- Recommends what to read next based on the queue, not random suggestions
- Creates Discord-ready version for any summary worth sharing

---

## Files

- Prompt: [[../Prompts/source-monitor-prompt|source-monitor-prompt.md]]
- Log: [[../Logs/source-monitor-log|source-monitor-log.md]]
- Output: [[../Outputs/source-monitor-output|source-monitor-output.md]]
