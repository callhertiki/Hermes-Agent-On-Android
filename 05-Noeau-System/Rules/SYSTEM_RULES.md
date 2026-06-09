# Noʻeau OS — System Rules

> These rules govern every agent, every automation, every script, and every note in this vault. They are not suggestions.

---

## Rule 1 — Never Delete Without Backup

Before any file is deleted, moved to 99-Archive, or overwritten:
- Create a copy in `99-Archive/` with the date appended to the filename
- Log the action in the relevant agent's log file
- State why the file was archived

**Applies to:** All scripts, all agents, all automations.

---

## Rule 2 — Always Explain Changes

Every automated action, every agent output, every script run must produce a readable record:
- What happened
- When it happened
- What file was affected
- What the output was

**Applies to:** All PowerShell scripts, all log files.

---

## Rule 3 — One Topic Per File

Each note covers exactly one topic, concept, or subject.
- If a note grows beyond its topic, split it
- Use `[[links]]` to connect related notes
- Do not create "catch-all" notes except in `00-Inbox/`

**Applies to:** All notes in 03-Learning, 04-Cybersecurity, 06-Research.

---

## Rule 4 — Discord Summaries for Shareable Content

Any knowledge worth sharing in a study community should have a Discord-ready version:
- Under 1800 characters
- **Bold headers**, flat bullets, no nested lists
- End with `— Noʻeau OS 🌺`
- Created by Mea Kākau or Scribe Agent

**Applies to:** Lessons, research summaries, how-to guides.

---

## Rule 5 — Cybersecurity Is Ethical, Defensive, and Educational Only

This vault is for learning and defense. All security content follows this framework:
- **Ethical**: Never test systems you do not own or have explicit written permission to test
- **Defensive**: The goal is protection, detection, and response — not exploitation
- **Educational**: CTF and lab environments are allowed; production systems are not
- **Legal**: Know the laws in your jurisdiction — ignorance is not a defense

Kiaʻi and Guardian Check enforce this rule. Any agent asked to help with offensive techniques will decline and redirect to the defensive equivalent.

---

## Rule 6 — Build Slowly and Safely

- No automation goes live until it has been tested manually at least 3 times
- No script runs with admin privileges unless absolutely necessary
- New features are added one at a time — not all at once
- Each phase of Noʻeau OS is validated before the next begins

---

## Rule 7 — Keep Notes Short and Organized

- Aim for notes under 500 words (except research deep-dives)
- Use the right template for every note type
- Process the Inbox daily — nothing stays in `00-Inbox/` for more than 48 hours
- File notes in the correct folder immediately

---

## Rule 8 — Agents Do Not Act Without You

In Phase 1, every agent run is manual. You review the prompt, you send it, you save the output.
- Agents do not auto-send to any external service
- Agents do not modify your vault files without you reading the output first
- No scheduling is active until Phase 2

---

## Violation Handling

If any rule is broken — even by accident:
1. Stop what you're doing
2. Document what happened in the relevant log
3. Restore from the most recent backup if data was lost
4. Update this rules file if the rule needs clarification

---

*Last reviewed: [[../../05-Noeau-System/Dashboards/NOEAU_COMMAND_CENTER|Command Center]]*
