---
agent: guardian-check
type: output-log
tags: [output, security, backup]
---

# Guardian Check — Outputs

> Daily security and backup audit results appended here.

---

## Example Output

### 2025-01-15 | 08:30

GUARDIAN CHECK — 2025-01-15 08:30
SYSTEM STATUS: 🟡 Yellow — Needs Attention

BACKUP:
Status: Overdue — 12 days since last Git push
Action: **Run `git add -A && git commit -m "vault: backup 2025-01-15" && git push` now.**

SECURITY:
- 2FA on email: Yes → OK
- 2FA on GitHub: Yes → OK
- Password manager: Yes → OK
- Reused passwords: 2 old accounts → **Update both passwords today.**

VAULT HEALTH:
- Inbox items: 3 waiting → Process before end of day
- Broken links: unknown → Run Obsidian link check this week

PRIORITY ACTIONS:
**HIGH:** Git push backup (overdue 12 days) | Update reused passwords on old accounts
MEDIUM: Process inbox (3 items) | Run link check
LOW / OK: 2FA, password manager — working correctly

RE-CHECK: 2025-01-16 morning

---

*Real outputs go below this line.*

---
