# Noʻeau Automation Dashboard

> *Noʻeau* — wisdom, wit, clever skill. This system turns your Obsidian vault into an AI accountability team.

---

## System Status

| Agent | Purpose | Prompt | Log | Output |
|-------|---------|--------|-----|--------|
| [[Active/accountability-check\|Accountability Check]] | Compares plan vs. reality every 30 min | [[Prompts/accountability-check.prompt\|Prompt]] | [[Logs/accountability-check.log\|Log]] | [[Outputs/accountability-check.output\|Output]] |
| [[Active/learning-coach\|Learning Coach]] | Quizzes you on what you're studying | [[Prompts/learning-coach.prompt\|Prompt]] | [[Logs/learning-coach.log\|Log]] | [[Outputs/learning-coach.output\|Output]] |
| [[Active/reflection-agent\|Reflection Agent]] | End-of-day review and tomorrow's plan | [[Prompts/reflection-agent.prompt\|Prompt]] | [[Logs/reflection-agent.log\|Log]] | [[Outputs/reflection-agent.output\|Output]] |
| [[Active/scribe-agent\|Scribe Agent]] | Converts rough notes to clean outputs | [[Prompts/scribe-agent.prompt\|Prompt]] | [[Logs/scribe-agent.log\|Log]] | [[Outputs/scribe-agent.output\|Output]] |

---

## How to Run an Agent (Manual)

1. Open **PowerShell** (or terminal)
2. Navigate to this vault's Scripts folder
3. Run: `pwsh Scripts/run-noeau-agent.ps1`
4. Choose an agent from the menu
5. Copy the generated prompt
6. Paste into your AI chat (Claude, ChatGPT, etc.)
7. Paste the AI response back into the Output file

> Automation scheduling comes later. Right now everything is manual and safe.

---

## Folder Map

```
07-Automations/
├── AUTOMATION_DASHBOARD.md      ← You are here
├── Active/                      ← Agent profile cards
│   ├── accountability-check.md
│   ├── learning-coach.md
│   ├── reflection-agent.md
│   └── scribe-agent.md
├── Prompts/                     ← Actual AI prompt text
│   ├── accountability-check.prompt.md
│   ├── learning-coach.prompt.md
│   ├── reflection-agent.prompt.md
│   └── scribe-agent.prompt.md
├── Logs/                        ← When each agent was run (append-only)
│   ├── accountability-check.log.md
│   ├── learning-coach.log.md
│   ├── reflection-agent.log.md
│   └── scribe-agent.log.md
├── Outputs/                     ← AI responses saved here
│   ├── accountability-check.output.md
│   ├── learning-coach.output.md
│   ├── reflection-agent.output.md
│   └── scribe-agent.output.md
└── Scripts/
    └── run-noeau-agent.ps1      ← Manual runner (PowerShell)
```

---

## Safety Rules (Non-Negotiable)

1. **No files are ever deleted by these agents**
2. **No files are overwritten — outputs are appended with timestamps**
3. **No scheduling is active yet — everything is manual**
4. **Cybersecurity topics stay ethical and defensive only**
5. **All prompts are visible before being sent — you review, you send**

---

## What to Build Next

After validating each agent works manually:

- [ ] Schedule `accountability-check` to trigger every 30 min via Task Scheduler or cron
- [ ] Build a Templater/QuickAdd hook to auto-open prompts from Obsidian
- [ ] Connect to Claude API for fully automated runs
- [ ] Add a nightly Git auto-commit to back up vault state
- [ ] Build a weekly summary that reads all logs and generates a report

---

*Part of the [[../Noeau-OS/_Dashboard|Noʻeau OS]] system.*
