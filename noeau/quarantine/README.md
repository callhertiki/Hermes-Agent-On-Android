# Noeau Guardian — Quarantine Folder

⚠ IMPORTANT: Files in this folder have been MOVED here — they are not deleted.

## What Is Quarantine?
Quarantine is a safe holding area for suspicious or unwanted files.
When Noeau moves a file to quarantine:
1. The original file is REMOVED from its original location
2. A copy lands here with a timestamp added to the name
3. Nothing is permanently deleted — you can always move files back

Example: If `invoice_final.exe` is quarantined, it becomes:
```
20250115_143022_invoice_final.exe
```

## How Files Get Here
Files are only moved here if YOU approve it.
The file scanner will ask: "Move to quarantine? [y/N]:"
Noeau will NEVER move a file without your confirmation.

## Recovering a Quarantined File
If you quarantined something by mistake:
1. Find the file in this folder
2. Move it back to where it came from using your file manager
3. Rename it to remove the timestamp prefix if needed

## When to Delete Files From Quarantine
- When you're sure you don't need them
- After verifying they were genuinely suspicious
- You can delete files from this folder manually at any time
- Noeau will NEVER automatically delete files from quarantine

## What This Folder Is NOT
- It is NOT an antivirus quarantine (it doesn't scan for malware)
- It is NOT monitored by Noeau for changes
- Files here are inert — they've just been moved, not analyzed
