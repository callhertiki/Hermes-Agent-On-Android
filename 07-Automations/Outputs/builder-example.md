---
agent: Builder
type: example-output
tags: [example, builder]
---

# Builder — Example Output

> This shows what a good Builder response looks like.

---

## Example: Scoping Noʻeau OS Phase 2

**Prompt sent:** `Scope Phase 2 of Noʻeau OS. Phase 1 is done: vault structure, 6 agents, templates, dashboards. Phase 2 should add PowerShell automation.`

---

## Project Scope: Noʻeau OS Phase 2

**One-sentence goal:** Automate the 4 most-used agents (accountability, reflection, learning coach, scribe) to run from a single PowerShell menu without manual prompt-copying.

**Done looks like:** Running one `.ps1` script opens a menu, you pick an agent, it reads your vault context, presents the prefilled prompt, appends the log, and saves the output — all without opening Obsidian.

---

### MVP (Ship This First)
A single PowerShell script that:
1. Shows a numbered menu of agents
2. Opens the correct prompt file in Notepad
3. Appends a timestamped entry to the matching log file
4. Opens the matching output file ready to paste

No API calls. No auto-sending. You still copy-paste to AI. But the friction is removed.

---

### Milestones

**Phase 2.1 — Runner Script (1–2 sessions)**
- [ ] Write `run-noeau-agent.ps1` with menu for 4 agents
- [ ] Test each agent: prompt opens, log appends, output opens
- [ ] Validate on Windows 11 — no admin required

**Phase 2.2 — Context Injection (1 session)**
- [ ] Script reads today's daily note filename automatically
- [ ] Script inserts current date/time into prompt template
- [ ] Script inserts agent name into log header

**Phase 2.3 — Archive + Safety (1 session)**
- [ ] Script checks if output file exists before creating
- [ ] Script never deletes — moves stale outputs to Archive/
- [ ] Script logs every run to a master run-history file

---

### Out of Scope (Phase 2)
- API calls — Phase 3
- Scheduled triggers — Phase 3
- Linux/WSL integration — Phase 4

---

### Biggest Risk
**Vault path is different on different machines.** Fix: make vault root a configurable variable at the top of the script, not hardcoded.

---

*Builder output — Noʻeau OS Phase 1*
