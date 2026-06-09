---
agent: Kiaʻi
type: example-output
tags: [example, guardian]
---

# Kiaʻi — Example Output

---

## Example: Monthly Security Audit

**Prompt sent:** `Last backup was 12 days ago via Git. 2FA enabled on GitHub and email. Using same password for 2 old accounts I forgot about. No known incidents. Give me an audit.`

---

**SYSTEM STATUS: 🟡 Yellow — Needs Attention**

---

### What's Working
- 2FA enabled on GitHub and email — the two most critical accounts. Good.
- Git backup method is solid when used — version history is valuable.

### Needs Attention

**HIGH — Backup frequency**
12 days without a backup is too long. A vault that changes daily should be backed up daily.
→ Action: Run `git add -A && git commit -m "vault: backup" && git push` today.
→ Action: Set a recurring reminder: every Sunday at 9pm — vault backup.

**HIGH — Reused passwords on old accounts**
Even "forgotten" accounts are attack vectors. If those accounts share an email, a breach gives access to your email.
→ Action: Log into both accounts. Change passwords to unique, generated passwords via your password manager.
→ Action: If accounts are genuinely unused — delete them. Fewer accounts = smaller attack surface.

**MEDIUM — No backup schedule**
A manual backup you have to remember is a backup that will be missed.
→ Action: Phase 2 of Noʻeau OS includes a scheduled Git backup. Prioritize this.

### Already Good — No Action Needed
- No known incidents
- 2FA on critical accounts
- Using a password manager (implied by generated passwords)

---

**Re-check in:** 30 days, or immediately after any of the High items are resolved.

---

*Kiaʻi output — Noʻeau OS Phase 1*
