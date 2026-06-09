# Noeau Guardian — Memory Folder

This folder stores the "memory" of the Noeau Guardian system.
It contains small JSON files that track the current state of your security setup.

## Files Stored Here

### `honeytoken_baseline.json`
- Created when you run: Honeytoken Manager → Create Decoys (or Update Baseline)
- Stores the last-known size and modification time of every decoy file
- Used to detect if a decoy file was touched since the baseline was set
- Safe to delete if you want to reset the decoy system (just re-run Create Decoys)

### `honeytoken_alerts.json`
- Grows over time as alerts are detected
- Each entry is a JSON object with: type, severity, message, path, time
- You can clear this file if you've reviewed all alerts and want a fresh start
- Safe to delete — Noeau will create a new one when the next alert occurs

## What This Folder Is NOT For
- It does NOT store real passwords or credentials (those go in KeePassXC)
- It does NOT store personal files
- It does NOT send data anywhere — everything stays on your machine

## Backup Note
You do NOT need to back up this folder regularly.
If lost, just re-run "Create Decoys" to rebuild the baseline.
