# How to Run Noʻeau — Quick Reference

## The apostrophe problem (and the fix)

The folder `C:\No'eau` contains an apostrophe. PowerShell single-quoted
strings use `'` as a delimiter, so this breaks:

```powershell
# ✗ BAD — PowerShell sees 'C:\No' then an orphan token  'eau'
$Base = 'C:\No'eau'

# ✓ GOOD — apostrophe is a plain character inside double quotes
$Base = "C:\No'eau"
```

The fixed `noeau.ps1` uses double-quoted strings everywhere.

---

## Launch commands

### Option 1 — From any PowerShell terminal

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "C:\No'eau\noeau.ps1"
```

### Option 2 — Navigate first, then run

```powershell
# Note: Set-Location also needs double quotes
Set-Location "C:\No'eau"

# Now you can use relative path
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\noeau.ps1"
```

### Option 3 — One-time execution policy fix (run once as Administrator)

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
# After this you can run: & "C:\No'eau\noeau.ps1"
```

---

## Available commands

```powershell
# Dashboard (default)
pwsh -File "C:\No'eau\noeau.ps1"
pwsh -File "C:\No'eau\noeau.ps1" dashboard

# Verify all paths exist
pwsh -File "C:\No'eau\noeau.ps1" verify

# Quick status
pwsh -File "C:\No'eau\noeau.ps1" status

# Generate today's report
pwsh -File "C:\No'eau\noeau.ps1" report

# Search your knowledge base
pwsh -File "C:\No'eau\noeau.ps1" search "keyword"
pwsh -File "C:\No'eau\noeau.ps1" search "nmap" cybersecurity

# Open a folder in Explorer
pwsh -File "C:\No'eau\noeau.ps1" open base
pwsh -File "C:\No'eau\noeau.ps1" open knowledge
pwsh -File "C:\No'eau\noeau.ps1" open inbox

# Help
pwsh -File "C:\No'eau\noeau.ps1" help
```

---

## Syntax validation command

Run this on your Surface Pro to verify the script has no syntax errors:

```powershell
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    "C:\No'eau\noeau.ps1",
    [ref]$null,
    [ref]$errors
)
if ($errors.Count -eq 0) {
    Write-Host "✓ Syntax OK — no errors found." -ForegroundColor Green
} else {
    $errors | ForEach-Object { Write-Host "✗ $($_.Message)  (line $($_.Extent.StartLineNumber))" -ForegroundColor Red }
}
```

---

## Read the first 50 lines (correct path syntax)

```powershell
# ✗ Wrong — you were in C:\Users\tikih, not in C:\No'eau
Get-Content ".\noeau.ps1" -First 50

# ✓ Correct — use the absolute path
Get-Content "C:\No'eau\noeau.ps1" -First 50
```

---

## Common errors and fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Unexpected token 'eau'` | Single-quoted string: `'C:\No'eau'` | Change to `"C:\No'eau"` |
| `Cannot find path '.\noeau.ps1'` | Wrong working directory | Use absolute path or `Set-Location "C:\No'eau"` first |
| `execution of scripts is disabled` | Execution policy | Run with `-ExecutionPolicy Bypass` flag |
| `File not found` | Path typo or wrong drive | Confirm with `Test-Path "C:\No'eau\noeau.ps1"` |
