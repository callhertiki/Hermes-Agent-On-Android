# Noeau Guardian — Decoys Folder

This folder is the management home for the Noeau Guardian decoy/honeytoken system.

## What Are Decoys?
Decoys (also called honeytokens) are fake files designed to look like they contain
real credentials or passwords — but they don't.

If an unauthorized person accesses your computer and goes looking for passwords,
they will likely open files named things like "Passwords_OLD" or "Archive_Login_Backup."
When those files are touched, Noeau Guardian logs an alert.

## Where Are the Actual Decoy Files?
The decoy FILES are placed in your Documents folder (or wherever you configure).
By default: `~/Documents/Passwords_OLD/`, `~/Documents/Passwords_DO_NOT_USE/`, etc.

This folder (`noeau/decoys/`) is the management area — not where the decoys live.

## What's Stored Here
- Copies or metadata about your decoy setup (for future features)
- You can manually place notes here about your decoy configuration

## The Baseline and Alert Files
The system that detects if decoys were touched is stored in `memory/`:
- `memory/honeytoken_baseline.json` — what the files looked like when set up
- `memory/honeytoken_alerts.json` — any detections logged here

## Safety Rules for Decoys
- Decoy files contain NO real usernames, passwords, or credentials
- Every decoy file is clearly marked as DECOY inside (NOEAU_HONEYTOKEN_MARKER)
- The decoy system is DETECTION ONLY — it cannot block access or run code
- If you see an alert, investigate manually and decide what to do

## Running the Decoy System
From Noeau Guardian main menu:
1. Choose [3] Honeytoken Manager
2. Choose [1] Create decoy files (first-time setup)
3. After that, choose [2] Check if decoys were touched (run daily)
