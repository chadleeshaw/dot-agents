#!/usr/bin/env zsh
# setup.sh — install agent config for OpenCode, Claude Code, Pi, and Grok CLI
#
# Idempotent: safe to re-run. Creates symlinks and installs dependencies.
# Called by ~/src/chadleeshaw/dotfiles/bootstrap.sh, or run standalone:
#
#   ~/.agents/setup.sh

set -e

AGENTS_DIR="${AGENTS_DIR:-$HOME/.agents}"
OPENCODE_CONFIG="$HOME/.config/opencode"
CLAUDE_CONFIG="$HOME/.claude"
PI_CONFIG="$HOME/.pi/agent"
GROK_CONFIG="$HOME/.grok"
LOCAL_BIN="$HOME/.local/bin"
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes}"
MEMORY_DIR="$OBSIDIAN_VAULT/_ai/memories"

info()    { echo "==> [dot-agents] $*"; }
success() { echo "    ✓ $*"; }
skip()    { echo "    – $* (already done)"; }

# ── pre-flight ────────────────────────────────────────────────────────────────

info "Setting up dot-agents from $AGENTS_DIR"

if [ ! -d "$AGENTS_DIR/.git" ]; then
  echo "dot-agents: error: $AGENTS_DIR is not a git repo" >&2
  echo "  Clone it first:" >&2
  echo "    git clone git@github.com:chadleeshaw/dot-opencode.git ~/.agents" >&2
  exit 1
fi

# Pull latest if we're in a clean state
if git -C "$AGENTS_DIR" diff --quiet && git -C "$AGENTS_DIR" diff --cached --quiet; then
  info "Pulling latest from origin..."
  git -C "$AGENTS_DIR" pull --quiet --ff-only 2>/dev/null || true
fi

# ── directories ───────────────────────────────────────────────────────────────

mkdir -p "$OPENCODE_CONFIG"
mkdir -p "$CLAUDE_CONFIG"
mkdir -p "$PI_CONFIG"
mkdir -p "$GROK_CONFIG"
mkdir -p "$LOCAL_BIN"

# ── symlink helper ────────────────────────────────────────────────────────────

symlink() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    skip "$dst"
  else
    # Remove real dir or symlink (ln -sf won't replace a symlink-to-dir)
    [ -L "$dst" ] && rm "$dst"
    [ -e "$dst" ] && rm -rf "$dst"
    ln -s "$src" "$dst"
    success "$dst -> $src"
  fi
}

# ── opencode config symlinks ──────────────────────────────────────────────────

info "Symlinking opencode config directories..."

symlink "$AGENTS_DIR/agents"   "$OPENCODE_CONFIG/agents"
symlink "$AGENTS_DIR/commands" "$OPENCODE_CONFIG/commands"
symlink "$AGENTS_DIR/skills"   "$OPENCODE_CONFIG/skills"

# ── claude config symlinks ───────────────────────────────────────────────────

info "Symlinking claude config directories..."

symlink "$AGENTS_DIR/agents"   "$CLAUDE_CONFIG/agents"
symlink "$AGENTS_DIR/commands" "$CLAUDE_CONFIG/commands"
symlink "$AGENTS_DIR/skills"   "$CLAUDE_CONFIG/skills"

# ── pi config symlinks ───────────────────────────────────────────────────────

info "Symlinking pi config directories..."

symlink "$AGENTS_DIR/agents"   "$PI_CONFIG/agents"
symlink "$AGENTS_DIR/commands" "$PI_CONFIG/prompts"
symlink "$AGENTS_DIR/skills"   "$PI_CONFIG/skills"

symlink "$AGENTS_DIR/context.md" "$PI_CONFIG/AGENTS.md"

# ── grok config symlinks ─────────────────────────────────────────────────────

info "Symlinking grok config directories..."

symlink "$AGENTS_DIR/commands" "$GROK_CONFIG/commands"

# ── shared memory ────────────────────────────────────────────────────────────
# One memory folder in the Obsidian vault, loaded by every harness:
#   Claude   — autoMemoryDirectory in settings.json (built-in auto memory)
#   pi       — APPEND_SYSTEM.md -> the index, rules come from AGENTS.md
#   opencode — the index listed in opencode.json "instructions"

# Set a JSON config value only if it differs (keeps re-runs quiet and files untouched).
json_ensure() {
  python3 - "$@" <<'PY'
import json, os, sys
path, mode, key, value = sys.argv[1:5]
data = json.load(open(path)) if os.path.exists(path) else {}
if mode == "set":
    if data.get(key) == value:
        sys.exit(1)
    data[key] = value
elif mode == "dictset":  # key is a dotted path to a dict; value is "entry=setting"
    node = data
    for part in key.split("."):
        node = node.setdefault(part, {})
    entry, _, setting = value.rpartition("=")
    if node.get(entry) == setting:
        sys.exit(1)
    node[entry] = setting
else:  # append to list
    items = data.setdefault(key, [])
    if value in items:
        sys.exit(1)
    items.append(value)
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
}

info "Linking shared agent memory..."

if [ -d "$MEMORY_DIR" ]; then
  symlink "$MEMORY_DIR"                  "$AGENTS_DIR/memory"
  symlink "$AGENTS_DIR/memory/MEMORY.md" "$PI_CONFIG/APPEND_SYSTEM.md"
  [ -d "${MEMORY_DIR%/memories}/log" ] && symlink "${MEMORY_DIR%/memories}/log" "$AGENTS_DIR/log"

  # Private skills: proprietary, so they live in the vault (_ai/skills/) and are
  # linked in. Their names go to .git/info/exclude (local-only, never committed)
  # so neither the content nor the name ever reaches GitHub.
  exclude="$AGENTS_DIR/.git/info/exclude"
  for skill in "${MEMORY_DIR%/memories}"/skills/*/SKILL.md(N); do
    name="${${skill:h}:t}"
    symlink "${skill:h}" "$AGENTS_DIR/skills/$name"
    grep -qxF "/skills/$name" "$exclude" 2>/dev/null || { echo "/skills/$name" >> "$exclude"; success "git exclude /skills/$name"; }
  done

  if json_ensure "$CLAUDE_CONFIG/settings.json" set autoMemoryDirectory "~/.agents/memory"; then
    success "claude settings.json: autoMemoryDirectory = ~/.agents/memory"
  else
    skip "claude settings.json autoMemoryDirectory"
  fi

  if [ -f "$OPENCODE_CONFIG/opencode.json" ]; then
    if json_ensure "$OPENCODE_CONFIG/opencode.json" append instructions "~/.agents/memory/MEMORY.md"; then
      success "opencode.json: instructions += ~/.agents/memory/MEMORY.md"
    else
      skip "opencode.json instructions"
    fi
    # opencode asks before touching paths outside the project (and auto-rejects headless),
    # so allow exactly what agents read and write: the _ai notes, shared memory, and the rules file.
    for dir in "~/.agents/memory/**" "~/.agents/log/**" "~/.agents/context.md" "${MEMORY_DIR%/memories}/**" "$OBSIDIAN_VAULT/_templates/Captains Log Template.md"; do
      dir="${dir/#$HOME/~}"
      if json_ensure "$OPENCODE_CONFIG/opencode.json" dictset permission.external_directory "$dir=allow"; then
        success "opencode.json: external_directory allow $dir"
      else
        skip "opencode.json external_directory $dir"
      fi
    done
  fi
else
  echo "    ! $MEMORY_DIR not found — skipping shared memory."
  echo "      Open the vault in Obsidian (or set OBSIDIAN_VAULT) and re-run."
fi

# ── PATH check ────────────────────────────────────────────────────────────────

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$LOCAL_BIN"; then
  echo ""
  echo "    WARNING: $LOCAL_BIN is not in your PATH."
  echo "    Add this to your ~/.zshrc:"
  echo ""
  echo "      export PATH=\"\$PATH:$LOCAL_BIN\""
  echo ""
fi

# ── done ─────────────────────────────────────────────────────────────────────

echo ""
info "Done."
echo ""
echo "  Claude agents:     $CLAUDE_CONFIG/agents      -> $AGENTS_DIR/agents"
echo "  Claude commands:   $CLAUDE_CONFIG/commands    -> $AGENTS_DIR/commands"
echo "  Claude skills:     $CLAUDE_CONFIG/skills      -> $AGENTS_DIR/skills"
echo "  OpenCode agents:   $OPENCODE_CONFIG/agents    -> $AGENTS_DIR/agents"
echo "  OpenCode commands: $OPENCODE_CONFIG/commands  -> $AGENTS_DIR/commands"
echo "  OpenCode skills:   $OPENCODE_CONFIG/skills    -> $AGENTS_DIR/skills"
echo "  Pi agents:         $PI_CONFIG/agents          -> $AGENTS_DIR/agents"
echo "  Pi prompts:        $PI_CONFIG/prompts         -> $AGENTS_DIR/commands"
echo "  Pi skills:         $PI_CONFIG/skills          -> $AGENTS_DIR/skills"
echo "  Pi context:        $PI_CONFIG/AGENTS.md        -> $AGENTS_DIR/context.md"
echo "  Grok commands:     $GROK_CONFIG/commands      -> $AGENTS_DIR/commands"
echo "  Shared memory:     $AGENTS_DIR/memory         -> $MEMORY_DIR"
echo "  Work log:          $AGENTS_DIR/log            -> ${MEMORY_DIR%/memories}/log"
echo "  Private skills:    $AGENTS_DIR/skills/<name>  -> ${MEMORY_DIR%/memories}/skills/<name>"
echo "  Pi memory index:   $PI_CONFIG/APPEND_SYSTEM.md -> $AGENTS_DIR/memory/MEMORY.md"
echo ""
