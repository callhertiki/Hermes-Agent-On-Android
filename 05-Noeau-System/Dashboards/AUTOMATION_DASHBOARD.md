# Automation Dashboard

> Phase 1: All agents are manual. You run them, you review the output, you save it.
> Phase 2: PowerShell scheduling. Phase 3: API integration.

---

## Active Agents

| Agent | Purpose | Cadence | Prompt | Log | Output |
|-------|---------|---------|--------|-----|--------|
| Accountability Check | Plan vs. actual | Every 30 min | [[../../07-Automations/Prompts/accountability-check.prompt\|Prompt]] | [[../../07-Automations/Logs/accountability-check.log\|Log]] | [[../../07-Automations/Outputs/accountability-check.output\|Output]] |
| Learning Coach | Quiz me on what I learned | After study | [[../../07-Automations/Prompts/learning-coach.prompt\|Prompt]] | [[../../07-Automations/Logs/learning-coach.log\|Log]] | [[../../07-Automations/Outputs/learning-coach.output\|Output]] |
| Reflection Agent | End-of-day review | Evening | [[../../07-Automations/Prompts/reflection-agent.prompt\|Prompt]] | [[../../07-Automations/Logs/reflection-agent.log\|Log]] | [[../../07-Automations/Outputs/reflection-agent.output\|Output]] |
| Scribe Agent | Format rough notes | On demand | [[../../07-Automations/Prompts/scribe-agent.prompt\|Prompt]] | [[../../07-Automations/Logs/scribe-agent.log\|Log]] | [[../../07-Automations/Outputs/scribe-agent.output\|Output]] |

---

## Activation Prompts (Phase 1 — Identity-based)

| Agent | Activation Prompt |
|-------|------------------|
| Kumu | [[../../07-Automations/Prompts/kumu-activation\|kumu-activation]] |
| Kiaʻi | [[../../07-Automations/Prompts/kiai-activation\|kiai-activation]] |
| Mea Kākau | [[../../07-Automations/Prompts/mea-kakau-activation\|mea-kakau-activation]] |
| Alakaʻi | [[../../07-Automations/Prompts/alakai-activation\|alakai-activation]] |
| Mea Huli | [[../../07-Automations/Prompts/mea-huli-activation\|mea-huli-activation]] |
| Builder | [[../../07-Automations/Prompts/builder-activation\|builder-activation]] |

---

## Scripts

| Script | Purpose | Status |
|--------|---------|--------|
| [[../../07-Automations/Scripts/run-noeau-agent.ps1\|run-noeau-agent.ps1]] | Manual agent runner (4 agents) | Active — Phase 1 |

---

## How to Run an Agent (Phase 1)

```
1. Open PowerShell
2. cd to your vault folder
3. Run: .\07-Automations\Scripts\run-noeau-agent.ps1
4. Pick an agent
5. Copy the prompt → paste into AI chat
6. Paste AI response → Output file
7. Log is updated automatically
```

---

## Archive

Old outputs and deprecated files: [[../../07-Automations/Archive/Index\|Archive]]

---

## Phase Roadmap

- [x] Phase 1 — Manual runner + all agent prompts
- [ ] Phase 2 — Scheduled runs (Task Scheduler / cron)
- [ ] Phase 3 — Claude API — auto-send and receive
- [ ] Phase 4 — WSL integration
- [ ] Phase 5 — Full autonomous background operation
