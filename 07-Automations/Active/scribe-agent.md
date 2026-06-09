---
agent: scribe-agent
role: Note Formatter
cadence: on-demand
status: active
tags: [agent, scribe, formatting, discord, notes]
---

# Scribe Agent — The Formatter

> "Raw notes are ore. This agent turns them into something usable."

---

## Purpose

You take rough notes during learning, research, or conversation. Scribe Agent takes that raw material and produces clean, structured outputs in five formats — whatever you need for that moment. It works closely with [[../../Noeau-OS/Agents/Mea-Kakau|Mea Kākau]] but adds specific formatting modes for Discord and accountability workflows.

---

## How It Works

1. You paste in your raw notes (doesn't matter how messy)
2. You choose the output format (see below)
3. The agent produces a clean, ready-to-use version
4. You save it to the Outputs file and/or paste it where you need it

---

## Output Formats

Choose one or more per run:

| Format | What You Get | Use For |
|--------|-------------|---------|
| **Discord Note** | Short, scannable, with bold headers and bullet points. No markdown that breaks in Discord. | Sharing in a study server, accountability channel |
| **Obsidian Note** | Full markdown, YAML frontmatter, internal links, tags | Adding to your vault as a permanent note |
| **Summary** | 3–5 bullet executive summary, high signal only | Quick reference, future review |
| **Reflection** | What you understood, what was unclear, what it connects to | Adding to a learning note |
| **Action Steps** | Numbered, specific, ordered by priority | What to do with this information |

---

## Discord Note Rules

Discord notes follow these rules:
- No nested bullet points (Discord renders them badly)
- Bold (`**text**`) for headers instead of `#`
- Max 5 bullet points per section
- Code blocks use triple backtick
- Total length: under 1800 characters (Discord limit safety)
- End with: `— Noʻeau OS 🌺`

---

## Obsidian Note Rules

Obsidian notes follow these rules:
- YAML frontmatter (date, tags, source, status)
- H1 title, H2 sections
- Key concepts in bold on first use
- `[[double brackets]]` for internal links to related notes
- Source/reference at the bottom
- Tags: lowercase, hyphenated

---

## Style Guide

- Does not add opinions — only formats what you give it
- Does not invent content — if something is unclear in your notes, it flags it with `[UNCLEAR]`
- Preserves your voice and meaning
- Action steps are specific: not "study more" but "re-read Chapter 4, section on memory allocation"

---

## Input Required

When running this agent, have ready:

1. Your raw notes (can be bullet points, stream of consciousness, fragments)
2. The source (book title, article URL, conversation topic)
3. Which output format(s) you want

---

## Safety Rules

- Does not modify your original notes
- Outputs are saved to [[../Outputs/scribe-agent.output|scribe-agent.output.md]] with timestamps
- Original input is preserved in the output file for reference
- Nothing is auto-posted to Discord — you copy and paste manually

---

## Files

- Prompt: [[../Prompts/scribe-agent.prompt|scribe-agent.prompt.md]]
- Log: [[../Logs/scribe-agent.log|scribe-agent.log.md]]
- Output: [[../Outputs/scribe-agent.output|scribe-agent.output.md]]

---

## Linked Notes

- [[../../Noeau-OS/Agents/Mea-Kakau|Mea Kākau — Scribe Agent]]
- [[../../Noeau-OS/Templates/Research|Research Template]]
- [[../../Noeau-OS/Templates/Learning|Learning Template]]
- [[../AUTOMATION_DASHBOARD|Automation Dashboard]]
