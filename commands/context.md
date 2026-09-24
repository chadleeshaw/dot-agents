---
description: Load Chad's AI context notes from Obsidian (agents, environment, and company infrastructure, team, workflows)
---

Read and internalize these context notes from the Obsidian vault (`_ai/` in the Notes vault):

## agents.md — who you work for and how
!`cat "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes/_ai/agents.md"`

## environment.md — local machine, harnesses, tools, auth
!`cat "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes/_ai/environment.md"`

## Company notes — infrastructure, team, workflows (from the company folder named in agents.md)
!`for f in "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes/_ai"/*/{infrastructure,team,workflows}.md; do [ -f "$f" ] && { echo "### ${f##*/_ai/}"; cat "$f"; }; done`

Use these notes as the source of truth for the rest of this session. Tool pages load on demand: general tools in `_ai/tools/`, company systems in `_ai/<company>/tools/`.
