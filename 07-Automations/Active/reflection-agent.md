---
agent: reflection-agent
role: End-of-Day Reviewer
cadence: end of day
status: active
phase: 1-manual
tags: [automation-agent, reflection, review]
---

# Reflection Agent

> *"A day unexamined is a day you can't learn from."*

---

## Purpose

At the end of each day, this agent reads your daily note and any other notes you created that day. It produces a structured summary: what you learned, what you avoided, what needs review, and your single most important first move for tomorrow.

---

## What It Reads

- Today's completed daily note (morning plan + evening close-out)
- Any learning notes, research notes, or captures created today
- Your honest answers: did you finish your Top 3? What did you skip?

## What It Writes

- DAILY REFLECTION with 4 sections
- Appended to today's daily note (you paste it)
- Appended to the reflection log with timestamp

---

## Output Format

```
DAILY REFLECTION
Date: [date] | Reviewed at: [time]

WHAT I LEARNED
- [specific, not "studied Python"]

WHAT I AVOIDED
- [task] — [one-word label: Procrastination / Distraction / Unclear / Overwhelmed / Forgot]

WHAT NEEDS REVIEW
- [topics that didn't fully land]

TOMORROW'S FIRST MOVE
[One action, specific enough to start without thinking]

OVERALL DAY RATING: [1–10]
ONE-LINE SUMMARY: [honest, not motivational]
```

---

## Style Rules

- Names avoidance without shame — just names it
- Tomorrow's move must be a SPECIFIC action, not a goal
- One-line summary must be accurate, not aspirational
- If the day was genuinely good, says so

---

## Files

- Prompt: [[../Prompts/reflection-agent-prompt|reflection-agent-prompt.md]]
- Log: [[../Logs/reflection-agent-log|reflection-agent-log.md]]
- Output: [[../Outputs/reflection-agent-output|reflection-agent-output.md]]
