---
tags: [system, backup]
agent: Kiaʻi
last_backup: 
---

# Backup Log

> Monitored by [[../Agents/Kiai|Kiaʻi — The Guardian]]. Update this file every time a backup is confirmed.

---

## Backup Status

| Method | Status | Last Run | Frequency | Notes |
|--------|--------|----------|-----------|-------|
| Git Push | | | | |
| Cloud Sync | | | | |
| Manual Export | | | | |
| External Drive | | | | |

---

## Backup Methods

### Git (Recommended for this vault)
This vault lives in a git repository. Backing up means committing and pushing changes.

```bash
# Commit and push all vault changes
git add -A
git commit -m "vault: backup $(date +%Y-%m-%d)"
git push
```

### Obsidian Sync
If using Obsidian Sync, verify the sync icon shows as active (cloud icon in bottom right of Obsidian).

### Manual Export
Periodically export the entire vault folder to an external drive or cloud storage (iCloud, Google Drive, etc.).

---

## Backup History

| Date | Method | Confirmed By | Notes |
|------|--------|-------------|-------|
| | | | |

---

## Recovery Plan

> Where would I restore from if this vault was lost?

1. **Primary source:** 
2. **Secondary source:** 
3. **Last known good backup:** 

---

## Alerts

> Log any backup failures or warnings here:

| Date | Alert | Resolved |
|------|-------|----------|
| | | Yes / No |

---

## Quick Links

- [[Vault-Health|Vault Health]]
- [[../Agents/Kiai|Kiaʻi — Guardian Agent]]
- [[../_Dashboard|Dashboard]]
