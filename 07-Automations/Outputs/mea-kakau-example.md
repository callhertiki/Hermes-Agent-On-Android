---
agent: Mea Kākau
type: example-output
tags: [example, scribe]
---

# Mea Kākau — Example Output

---

## Example: Formatting Raw Notes on DNS

**Raw notes input:**
```
dns = domain name system
converts names to ip addresses
like a phonebook for the internet
when you type google.com it finds the ip
dns resolver = your isp usually handles it
root servers = 13 of them
TLD servers = .com .org etc
authoritative servers = knows the actual answer
record types: A record (ipv4), AAAA (ipv6), MX (mail), CNAME (alias)
dns can be poisoned = attacker gives wrong ip
DNSSEC = security extension, digitally signs records
```

---

### Obsidian Note Output

```markdown
---
date: 2025-01-15
tags: [networking, dns, cybersecurity]
source: Personal lecture notes
status: permanent
---

# DNS — Domain Name System

**DNS** converts human-readable domain names into IP addresses. When you type `google.com`, DNS finds the corresponding IP address so your device knows where to connect.

## How DNS Resolution Works

1. Your device asks the **DNS resolver** (usually your ISP)
2. Resolver asks a **root server** (13 exist globally)
3. Root refers to a **TLD server** (`.com`, `.org`, etc.)
4. TLD refers to the **authoritative server** — the one that knows the actual answer
5. IP address is returned to your device

## Record Types

| Record | Purpose |
|--------|---------|
| A | Maps domain to IPv4 address |
| AAAA | Maps domain to IPv6 address |
| MX | Mail server for a domain |
| CNAME | Alias — one domain pointing to another |

## Security: DNS Poisoning + DNSSEC

**DNS poisoning** — an attacker injects false records, redirecting users to a malicious IP.
**DNSSEC** — digitally signs DNS records so clients can verify they haven't been tampered with.

## Sources
- Personal lecture notes, 2025-01-15
```

---

### Discord Note Output

```
**DNS — Domain Name System**

**What it does:** Converts domain names (google.com) to IP addresses. It's the internet's phonebook.

**How resolution works:**
- Your ISP's resolver asks a root server
- Root → TLD server (.com/.org) → Authoritative server (real answer)
- IP address returned to you

**Key record types:**
- A = domain → IPv4 | AAAA = domain → IPv6
- MX = mail servers | CNAME = alias/redirect

**Security notes:**
- DNS Poisoning = fake records redirect to malicious IP
- DNSSEC = digitally signed records prevent tampering

— Noʻeau OS 🌺
```

---

*Mea Kākau output — Noʻeau OS Phase 1*
