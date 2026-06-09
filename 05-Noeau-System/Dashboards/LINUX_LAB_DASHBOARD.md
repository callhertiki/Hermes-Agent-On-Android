# Linux Lab Dashboard

> Your command-line learning hub. Build real terminal skills — on WSL first, then native Linux later.

---

## Lab Status

| Component | Status | Notes |
|-----------|--------|-------|
| WSL2 installed | [ ] | Enable in Windows Features |
| Ubuntu distro set up | [ ] | `wsl --install -d Ubuntu` |
| Terminal configured | [ ] | Windows Terminal recommended |
| First command run | [ ] | `pwd` or `ls` |

---

## Setup Guide

```powershell
# Run in PowerShell as Administrator (first time only)
wsl --install

# After restart, install Ubuntu specifically:
wsl --install -d Ubuntu

# Check what's installed:
wsl --list --verbose

# Open Ubuntu:
wsl
```

---

## Core Commands — Learn These First

| Command | What It Does | Example |
|---------|-------------|---------|
| `pwd` | Print working directory (where am I?) | `pwd` |
| `ls` | List files in current directory | `ls -la` |
| `cd` | Change directory | `cd ~/Documents` |
| `mkdir` | Make a directory | `mkdir my-project` |
| `touch` | Create a blank file | `touch notes.txt` |
| `cat` | Read a file | `cat notes.txt` |
| `cp` | Copy a file | `cp a.txt b.txt` |
| `mv` | Move or rename | `mv old.txt new.txt` |
| `rm` | Delete (careful!) | `rm file.txt` |
| `man` | Manual for any command | `man ls` |

---

## Linux Skill Progression

### Stage 1 — Navigation (Start Here)
- [ ] Navigate to any folder using only the terminal
- [ ] List files including hidden files (`ls -la`)
- [ ] Create, move, copy, and delete files
- [ ] Understand absolute vs. relative paths
- [ ] Use `man` to look up any command

### Stage 2 — File Management
- [ ] Use `grep` to search inside files
- [ ] Use `find` to locate files by name or type
- [ ] Understand file permissions (`chmod`, `chown`)
- [ ] Read and write files with `cat`, `nano`, or `vim`
- [ ] Use pipes (`|`) to chain commands

### Stage 3 — Scripting Basics
- [ ] Write a simple bash script (`.sh` file)
- [ ] Use variables in bash
- [ ] Write an if/else in bash
- [ ] Use a for loop in bash
- [ ] Make a script executable with `chmod +x`

### Stage 4 — Networking + Security
- [ ] Use `ping`, `traceroute`, `nslookup`
- [ ] Use `netstat` or `ss` to view connections
- [ ] Understand `iptables` basics
- [ ] Use `nmap` for local network scanning (your own network only)
- [ ] Set up and use `ssh` to connect between machines

---

## Lab Notes

Store lab sessions here:
- [[../../08-Linux-Lab/Index\|Linux Lab Folder]]

---

## Tools to Learn (In Order)

1. `bash` — your shell
2. `vim` or `nano` — terminal text editors
3. `git` — version control from the terminal
4. `python3` — scripting from Linux
5. `nmap` — network scanning (ethical/local use only)
6. `wireshark` — packet analysis (with Kiaʻi's guidance)
