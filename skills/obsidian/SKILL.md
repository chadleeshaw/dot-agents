---
name: obsidian
description: Obsidian second brain - notes, dashboards, tasks, and knowledge management via CLI
license: MIT
---

# Obsidian — Chad's Vault

Delegate to the official sub-skills for all technical detail:

| Skill | Use for |
|---|---|
| `obsidian:obsidian-cli` | CLI commands — read, create, search, tasks, properties, daily notes |
| `obsidian:obsidian-markdown` | Obsidian-flavored markdown — wikilinks, callouts, embeds, frontmatter |
| `obsidian:obsidian-bases` | `.base` files — table/card views, filters, formulas |
| `obsidian:json-canvas` | `.canvas` files — visual maps, flowcharts, node graphs |
| `obsidian:defuddle` | Fetch web URLs as clean markdown (use instead of WebFetch for articles/docs) |

## Vault

- **Name:** Notes
- **Path:** `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes`
- **Target with:** `vault=Notes` if needed

## Orient first

Before acting, read the relevant `_ai/` context note:

```bash
obsidian read file="environment"    # tools, auth, machine
obsidian read file="infrastructure" # k8s, GCP, Vault
obsidian read file="team"           # repos, CI/CD
obsidian read file="workflows"      # how we work
```

Then orient to the vault if needed:

```bash
obsidian folders
obsidian recents
```

## Key structure

| Folder | Purpose |
|---|---|
| `_ai/` | Agent context — `agents.md`, `environment.md`, `memories.md`; index in `README.md` |
| `_ai/<company>/` | Company context — infrastructure, team, workflows (folder named in `_ai/agents.md`) |
| `_ai/tools/`, `_ai/<company>/tools/` | Tool pages — general tools and company systems |
| `_ai/memories/` | Shared agent memory — one note per memory plus the `MEMORY.md` index |
| `work/` | Work notes |
| `programming/` | Dev references |
| `_archive/` | Old notes |

## Frontmatter conventions

```yaml
type: note|project|meeting|reference|dashboard|ai-context|ai-tool|ai-memory
status: active|someday|done|archived
```
