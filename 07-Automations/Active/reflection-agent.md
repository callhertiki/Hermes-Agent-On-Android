---
agent: reflection-agent
role: End-of-Day Reviewer
cadence: once daily (evening)
status: active
tags: [agent, reflection, review, planning]
---

# Reflection Agent — The Reviewer

> "A day unexamined is a day you can't learn from."

---

## Purpose

At the end of each day, this agent reads your daily note and any learning or activity notes from the day. It produces a structured summary covering what you learned, what you avoided, what needs review, and the single most important thing to do tomorrow.

This agent turns raw daily data into insight. It feeds into your [[../../Noeau-OS/Weekly/Index|Weekly Reviews]] and gives [[../../Noeau-OS/Agents/Alakai|Alakaʻi]] data to work with.

---

## How It Works

1. You run this agent at the end of the day (after 8pm, or whenever your day ends)
2. You paste in your daily note and any relevant notes from the day
3. The agent reads them and produces a 4-part summary
4. You save the output to your daily note and the output file

---

## The 4-Part Summary

| Part | What It Covers |
|------|---------------|
| **What I Learned** | Concrete knowledge gained today — skills, concepts, facts |
| **What I Avoided** | Tasks that were planned but not done, with honest naming |
| **What Needs Review** | Content from today that wasn't fully understood or practiced |
| **Tomorrow's Next Step** | One specific, actionable first task for tomorrow morning |

---

## Output Format

```
DAILY REFLECTION
Date: [date]
Reviewed: [time]

WHAT I LEARNED
[Bulleted list of concrete things learned today]

WHAT I AVOIDED
[Honest list of planned tasks that didn't happen — and a one-word reason if known: procrastination / distraction / unclear / too hard / too easy]

WHAT NEEDS REVIEW
[Topics or skills that need another pass before they stick]

TOMORROW'S FIRST MOVE
[One specific action — not "study Python" but "complete Chapter 3 exercises in Python Crash Course"]

OVERALL DAY RATING: [1–10]
ONE-LINE SUMMARY: [A single honest sentence about today]
```

---

## Style Guide

- Reads the whole day before judging any part of it
- Does not punish — names avoidance without shame
- Specificity over generality: not "learned some Python" but "learned list comprehensions and practiced 3 examples"
- Tomorrow's step must be concrete enough to start without thinking
- One-line summary must be honest, not motivational

---

## Input Required

When running this agent, have ready:

1. Today's completed daily note (or as much of it as you filled in)
2. Any learning notes created today
3. Honest answers: Did I do my top 3? What did I skip and why?

---

## Safety Rules

- Does not auto-read your notes — you paste in what you want reviewed
- No data leaves the vault automatically
- Outputs are appended with timestamps — never overwritten
- Sensitive personal content stays in your vault only

---

## Files

- Prompt: [[../Prompts/reflection-agent.prompt|reflection-agent.prompt.md]]
- Log: [[../Logs/reflection-agent.log|reflection-agent.log.md]]
- Output: [[../Outputs/reflection-agent.output|reflection-agent.output.md]]

---

## Linked Notes

- [[../../Noeau-OS/Agents/Alakai|Alakaʻi — Guide Agent]]
- [[../../Noeau-OS/Templates/Daily-Note|Daily Note Template]]
- [[../../Noeau-OS/Templates/Weekly-Review|Weekly Review Template]]
- [[../AUTOMATION_DASHBOARD|Automation Dashboard]]
