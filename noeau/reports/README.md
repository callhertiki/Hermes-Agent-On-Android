# Noeau Guardian — Reports Folder

This folder stores your security reports as plain text files.

## Filename Format
Reports are named like this:
```
noeau_report_2025-01-15_14-30.txt
```
The date and time in the name tells you exactly when each report was generated.

## How Reports Are Generated
Run Noeau Guardian → Security Report → Generate full security report.

The report includes:
- Backup health (are your folders recently updated?)
- Honeytoken status (were any decoy files touched?)
- System notes (OS, Python version, what's NOT checked)
- Recommendations (best-practice reminders)

## How Many Reports Are Kept
By default, Noeau keeps the last 30 reports and deletes older ones automatically.
You can change this in Settings → config/config.json → "report" → "keep_last_n".

## Reading Reports
Reports are plain .txt files. Open them in any text editor:
- Windows: Notepad, VS Code, Notepad++
- Linux/Kali: nano, gedit, VS Code

They are also printed to the screen when generated.

## Sharing Reports
These reports contain your system's folder structure and file modification times.
Do NOT share them with anyone you don't fully trust.
They do NOT contain passwords or credentials.
