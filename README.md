# dot-agents

AI configuration for OpenCode, Claude Code, Pi, and Grok CLI — agents, commands, and skills.

Cloned to `~/.agents` and symlinked into each harness by `setup.sh`.

## Structure

```
~/.agents/
├── agents/       # Custom agent definitions
├── commands/     # Slash commands (/shipit, /test, ...)
├── skills/       # Language/domain skills loaded on demand
├── templates/    # Format templates (ADR, Context Modeling)
├── context.md    # Global instructions for pi and opencode (incl. shared memory rules)
├── memory/       # -> Obsidian _ai/memories/ (symlink, gitignored)
└── setup.sh      # Idempotent install script
```

## Setup

```sh
git clone git@github.com:chadleeshaw/dot-opencode.git ~/.agents
~/.agents/setup.sh
```

`setup.sh` symlinks everything into place. Safe to re-run.

## Shared memory

Claude Code, pi, and opencode share one memory that lives in the Obsidian vault
(`_ai/memories/`), so a fact learned in any harness, in any repo, is known to all
of them. `setup.sh` wires it up:

| Harness | Index loaded via | Rules from |
|---|---|---|
| Claude Code | `autoMemoryDirectory: ~/.agents/memory` in `~/.claude/settings.json` | built-in auto memory + `~/.claude/CLAUDE.md` |
| pi | `~/.pi/agent/APPEND_SYSTEM.md` -> `memory/MEMORY.md` | `~/.pi/agent/AGENTS.md` -> `context.md` |
| opencode | `instructions` in `~/.config/opencode/opencode.json` | `context.md` (also in `instructions`) |

`memory/MEMORY.md` is the index (one line per memory, loaded every session);
each memory is a `<slug>.md` note. Browse and edit them in Obsidian via
`_ai/memories.md`. Override the vault location with `OBSIDIAN_VAULT=... ./setup.sh`.

## Private skills

Proprietary skills must never reach GitHub. They live in
the Obsidian vault at `_ai/skills/<name>/` and `setup.sh` symlinks each one into
`skills/`, adding its name to `.git/info/exclude` — a local-only ignore file — so
neither the content nor the name is ever committed. Eval workspaces
(`skills/*-workspace/`) are ignored too. To add one: create it in `_ai/skills/`
and re-run `setup.sh`.

## Agents

Agents in `agents/` use Claude Code frontmatter (`name`, `description`, `model`, `tools`).

| Agent | Purpose |
|---|---|
| `architect` | Analyze and improve workflows, processes, and system design |
| `bug-finder` | Identify logic errors and potential issues |
| `code-review` | Code review focused on readability and security |
| `documentation` | Write clear, concise README and docs files |
| `domain-modeling` | Build and sharpen a project's domain model |
| `grill-me` | Delegate to `/grilling` for stress-testing a plan |
| `grill-with-docs` | Stress-test a plan and write ADRs as you go |
| `grilling` | Interview the user relentlessly about a plan or design |
| `optimizer` | Analyze runtime performance and identify bottlenecks |
| `refactor` | Improve readability and maintainability |
| `test-coverage` | Audit tests for coverage gaps and quality issues |
| `test-writer` | Write readable, maintainable tests for existing code |

## Commands

Slash commands in `commands/` are invoked manually with `/name`.

| Command | Purpose |
|---|---|
| `/context` | Load AI context notes from Obsidian (`_ai/agents`, `environment`, and the company folder's infrastructure, team, workflows) |
| `/review` | Review staged and unstaged changes against applicable coding skills and best practices |
| `/shipit` | Stage, commit, and push changes with an auto-generated message |
| `/simplify` | Refactor selected code for clarity and simplicity |
| `/test` | Run linting and tests, auto-fix where possible |
| `/zoom-out` | Step back for a higher-level perspective on the current code |

## Skills

Skills in `skills/` are auto-triggered when a task matches their domain.

| Skill | Loaded for |
|---|---|
| `caveman` | Ultra-compressed communication mode |
| `css` | CSS best practices |
| `design-taste-frontend` | Anti-slop frontend and design system guidance |
| `find-skills` | Discover and install agent skills |
| `golang` | Go best practices |
| `html` | HTML best practices |
| `incus` | Incus container and VM management via CLI |
| `javascript` | JS/TS best practices |
| `kubernetes` | kubectl, pods, deployments, ArgoCD, helmfile, and Kafka on k8s |
| `obsidian` | Obsidian notes and knowledge management |
| `python` | Python best practices |
| `saltstack` | SaltStack states, formulas, pillar, and configuration management |
| `terraform` | Terraform HCL, modules, and infrastructure as code |
| `zoom-out` | Higher-level perspective on current code or problem |
