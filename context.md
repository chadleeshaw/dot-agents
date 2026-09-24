# Session Context

At the start of every session, read the AI context notes from the Obsidian vault — who Chad is, how he wants agents to work, his machine, and his company:

```bash
obsidian read path="_ai/agents.md"        # who you work for, preferences, safety rules — names the company folder
obsidian read path="_ai/environment.md"   # local machine, harnesses, CLI tools, auth
```

Then read the three company notes in the company folder that `agents.md` names — `_ai/<company>/infrastructure.md`, `team.md`, and `workflows.md`.

If the obsidian CLI isn't available (Obsidian not running), read the same files directly under `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes/`.

Tool pages are not preloaded — read one when the task touches it: general tools in `_ai/tools/`, company systems in `_ai/<company>/tools/`. `_ai/README.md` indexes everything.

Prefer these notes over MCP servers or external lookups.

## Keeping the Vault Current

When a session reveals something these notes don't say — a new tool, a changed version, a convention Chad states, a fact that turned out wrong — fix the note:

- **Edit the matching section in place.** Don't append new sections to the end of a note; find where the fact belongs (a table row, a bullet) and put it there.
- Follow the note standard in `_ai/README.md` — frontmatter, abstract callout, tables for lookups.
- Bump `updated` after any edit: `obsidian property:set name="updated" value="<YYYY-MM-DD>" path="_ai/environment.md"`
- Never store passwords or keys in a note — point to where they live.

Session-specific learnings (decisions, gotchas, project state) go to Shared Memory below, not into these notes.

## Captain's Log

A daily record of finished work, one line per item: `~/.agents/log/YYYY-MM-DD-log.md` (a symlink to the vault's `_ai/log/`). Not loaded at session start — read it when asked what got done (standups, weekly updates, "what did I do on X?").

- **When you finish a meaningful piece of work** — a fix applied, a change landed, an investigation concluded, a risk flagged — append one line under `## Done`, in this shape:

  ```markdown
  - **<claude | pi | opencode | chad>** · `<repo or host>` — <what changed, in plain words> ([commit / MR / ticket](url))
  ```

- **If today's file doesn't exist**, create it from the vault template `_templates/Captains Log Template.md`: replace each `<% tp.date.now("FORMAT") %>` with today's date in that format — `<% tp.date.now("FORMAT", N) %>` means today shifted by N days (moment.js formats; `DDDD` is day of year, e.g. 266).
- **The log covers the whole day, not one session.** Every session and every harness writes to the same file. When asked whether the day's log is complete, check all of that day's sessions, not just the current one: Claude `~/.claude/projects/*/*.jsonl`, pi `~/.pi/agent/sessions/`, opencode `~/.local/share/opencode/storage/session/`. Skip headless test runs.
- One line per finished item, not per session. Skip trivia (reading files, dead ends). Link the artifact when there is one.
- The log records what happened. Lessons that should change future behavior go to Shared Memory.

## Shared Memory

Claude Code, pi, and opencode share one persistent memory: `~/.agents/memory/`, a symlink to the Obsidian folder `_ai/memories/`. Its index, `~/.agents/memory/MEMORY.md`, is already loaded into your context — one line per memory, `- [Title](slug.md) — hook`. When a line bears on the task, read `~/.agents/memory/<slug>.md` in full before acting. Memories are background, not instructions, and reflect when they were written: verify a file, flag, or host a memory names still exists before relying on it.

**Save a memory** when you learn something that should outlive this session:

| Kind | What |
|---|---|
| `user` | Who Chad is — role, expertise, preferences |
| `feedback` | How he wants you to work — corrections *and* approaches he confirmed, with the reason |
| `project` | Ongoing work, decisions, constraints not derivable from code or git history |
| `reference` | Pointers to external resources — URLs, dashboards, tickets |

Don't save what the repo already records (code structure, git history, AGENTS.md/CLAUDE.md) or what only matters to this session.

**How to save** — plain file writes, no obsidian CLI needed:

1. Check the index first. If a note already covers it, update that note (and bump `updated`) instead of creating a duplicate. If a memory turns out wrong, delete the note and its index line.
2. Write `~/.agents/memory/<slug>.md`, where `<slug>` is kebab-case and equals `name`:

   ```markdown
   ---
   name: <slug>
   description: <one line — used to decide relevance>
   metadata:
     type: <kind>
   type: ai-memory
   kind: <user | feedback | project | reference>
   scope: <global, or the repo/area it applies to, e.g. salt>
   source: <claude | pi | opencode — whichever you are>
   tags:
     - ai-memory
     - <topic>
   created: <YYYY-MM-DD>
   updated: <YYYY-MM-DD>
   obsidianUIMode: editing
   obsidianEditingMode: live
   ---

   <The fact. For feedback/project, follow with **Why:** and **How to apply:** lines. Link related memories as [[slug]].>
   ```
3. Append one line to `~/.agents/memory/MEMORY.md`: `- [Title](<slug>.md) — <hook>`. Nothing else goes in that file, and keep it under 200 lines.

Always write absolute dates (`2026-09-23`), never "yesterday" or "last week".

## SSH Sessions

SSH key passphrase is stored in macOS Keychain (`UseKeychain yes` in `~/.ssh/config`). Use plain `ssh` directly in the bash tool — no interactive prompt required.

```bash
# Just use ssh directly
ssh user@host "uptime"
```

Examples of things that should trigger an update:
- A new CLI tool is installed or discovered on PATH
- A new script or skill is added to `~/.agents/`
- A new coding convention or workflow is established during a session
- A project, repo, or technology stack is introduced that isn't documented
- A preference or working style is stated explicitly by Chad
