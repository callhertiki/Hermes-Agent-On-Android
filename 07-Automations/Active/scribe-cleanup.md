---
agent: scribe-cleanup
role: Daily Note Cleaner
cadence: daily
status: active
phase: 1-manual
tags: [automation-agent, scribe, notes, cleanup]
---

# Scribe Cleanup

> *"Rough notes are ore. This runs the refinery."*

---

## Purpose

Once per day, this agent processes any rough notes in `00-Inbox` and any learning or capture notes marked as "raw" or "needs formatting." It produces clean Obsidian notes and Discord-ready versions of anything worth sharing.

---

## What It Reads

- All notes in `00-Inbox/`
- Learning notes marked `status: raw` in frontmatter
- Discord captures that haven't been formatted yet
- Any note with `#needs-cleanup` tag

## What It Writes

- Clean formatted versions of each rough note
- Discord-ready summaries of shareable content
- Updated frontmatter: `status: permanent` for cleaned notes
- Appended entry to scribe-cleanup log

---

## Output Format

For each note processed:
```
SCRIBE CLEANUP — [DATE] [TIME]
Source: [filename or description]
Action: [Formatted / Summarized / Discord note created / Archived]

[CLEAN NOTE CONTENT HERE]

--- DISCORD VERSION (if applicable) ---
[Under 1800 chars, bold headers, flat bullets]
— Noʻeau OS 🌺
```

---

## Processing Rules

1. Clean notes go to their proper folder (03-Learning, 06-Research, etc.)
2. Discord notes are saved to `02-Discord-Captures/`
3. Original raw notes are either updated in place or archived
4. Nothing is deleted — marked as processed with timestamp

---

## Style Rules

- Never invents content — marks gaps `[UNCLEAR]`
- Preserves the original meaning even when restructuring
- Action steps are specific ("re-read section 3" not "study more")
- Discord notes must be under 1800 characters

---

## Files

- Prompt: [[../Prompts/scribe-cleanup-prompt|scribe-cleanup-prompt.md]]
- Log: [[../Logs/scribe-cleanup-log|scribe-cleanup-log.md]]
- Output: [[../Outputs/scribe-cleanup-output|scribe-cleanup-output.md]]
