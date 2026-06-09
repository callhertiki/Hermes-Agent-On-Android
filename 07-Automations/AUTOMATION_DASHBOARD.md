# Noʻeau Automation Dashboard

> Phase 1 — All agents run manually. You run the script, you copy the prompt, you paste the output.
> Previous version backed up to: `Archive/AUTOMATION_DASHBOARD-backup-2025-06-09.md`

---

## The 8 Automation Agents

| # | Agent | Purpose | Cadence | Prompt | Log | Output |
|---|-------|---------|---------|--------|-----|--------|
| 1 | [[Active/accountability-check\|Accountability Check]] | Plan vs. reality — one verdict | Every 30 min | [[Prompts/accountability-check-prompt\|Prompt]] | [[Logs/accountability-check-log\|Log]] | [[Outputs/accountability-check-output\|Output]] |
| 2 | [[Active/executive-coach\|Executive Coach]] | Goals → top priority → next actions | Every 3 hours | [[Prompts/executive-coach-prompt\|Prompt]] | [[Logs/executive-coach-log\|Log]] | [[Outputs/executive-coach-output\|Output]] |
| 3 | [[Active/learning-coach\|Learning Coach]] | Quiz me — check real understanding | After study | [[Prompts/learning-coach-prompt\|Prompt]] | [[Logs/learning-coach-log\|Log]] | [[Outputs/learning-coach-output\|Output]] |
| 4 | [[Active/reflection-agent\|Reflection Agent]] | End-of-day review + tomorrow's move | Evening | [[Prompts/reflection-agent-prompt\|Prompt]] | [[Logs/reflection-agent-log\|Log]] | [[Outputs/reflection-agent-output\|Output]] |
| 5 | [[Active/source-monitor\|Source Monitor]] | Research queue + summaries + Discord notes | Every 8 hours | [[Prompts/source-monitor-prompt\|Prompt]] | [[Logs/source-monitor-log\|Log]] | [[Outputs/source-monitor-output\|Output]] |
| 6 | [[Active/task-renewer\|Task Renewer]] | Review stale tasks, carry forward or archive | Every 2 days | [[Prompts/task-renewer-prompt\|Prompt]] | [[Logs/task-renewer-log\|Log]] | [[Outputs/task-renewer-output\|Output]] |
| 7 | [[Active/guardian-check\|Guardian Check]] | Backup + security + vault health | Daily | [[Prompts/guardian-check-prompt\|Prompt]] | [[Logs/guardian-check-log\|Log]] | [[Outputs/guardian-check-output\|Output]] |
| 8 | [[Active/scribe-cleanup\|Scribe Cleanup]] | Format rough notes → clean Obsidian + Discord | Daily | [[Prompts/scribe-cleanup-prompt\|Prompt]] | [[Logs/scribe-cleanup-log\|Log]] | [[Outputs/scribe-cleanup-output\|Output]] |

---

## Daily Agent Schedule (Manual — Phase 1)

| Time | Agent | What You Need |
|------|-------|--------------|
| Morning start | Guardian Check | Backup status, security status |
| Morning start | Executive Coach | Goals list, what's been done |
| Every 30 min | Accountability Check | Today's plan + honest "what am I doing?" |
| Every 3 hours | Executive Coach | Goals + completed items |
| After study | Learning Coach | Study notes + 5 honest answers |
| When inbox is full | Scribe Cleanup | Raw notes from inbox |
| Every 8 hours | Source Monitor | Reading queue + any completed sources |
| Every 2 days | Task Renewer | Incomplete tasks from recent daily notes |
| Evening | Reflection Agent | Full daily note + honest summary |

---

## Runner Script

→ [[Scripts/run-noeau-agent\|run-noeau-agent.ps1]]

```powershell
# Open PowerShell and run:
cd "C:\Path\To\Your\Vault"
.\07-Automations\Scripts\run-noeau-agent.ps1
```

---

## AI Team Activation Prompts (Identity-Based)

For setting up full agent personas — use these at the start of a new chat:

| Agent | Prompt |
|-------|--------|
| Kumu | [[Prompts/kumu-activation\|kumu-activation]] |
| Kiaʻi | [[Prompts/kiai-activation\|kiai-activation]] |
| Mea Kākau | [[Prompts/mea-kakau-activation\|mea-kakau-activation]] |
| Alakaʻi | [[Prompts/alakai-activation\|alakai-activation]] |
| Mea Huli | [[Prompts/mea-huli-activation\|mea-huli-activation]] |
| Builder | [[Prompts/builder-activation\|builder-activation]] |

---

## Archive

→ [[Archive/Index|Archive folder]] — old prompts, backups, superseded scripts

---

## Safety Rules (Non-Negotiable)

1. No files are ever deleted by these agents
2. Outputs are appended with timestamps — never overwritten
3. No scheduling is active yet — everything is manual
4. Cybersecurity content is defensive and educational only
5. All prompts are reviewed by you before being sent to any AI

---

## Phase Roadmap

- [x] Phase 1 — Manual runner + 8 agents + all prompts/logs/outputs
- [ ] Phase 2 — Windows Task Scheduler for timed agents
- [ ] Phase 3 — Claude API integration — auto-send and receive
- [ ] Phase 4 — WSL/Linux integration
- [ ] Phase 5 — Full background operation
