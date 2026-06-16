#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
BIN_DIR="${OPENCODE_TOKEN_MINIMIZER_BIN:-$HOME/.local/bin}"
CONFIG_FILE="$CONFIG_DIR/opencode.jsonc"

DRY_RUN=0
TUNE_CONFIG=0
CODING_AGENT_PERSONALITY=1
UNINSTALL=0

usage() {
  printf '%s\n' "Usage: $0 [--dry-run] [--tune-config] [--no-coding-agent-personality] [--uninstall]"
  printf '%s\n' ""
  printf '%s\n' "Installs OpenCode token minimizer skill, Oracle plan agent, auditor agent, and audit helper."
  printf '%s\n' "--tune-config adds conservative tool_output and compaction settings."
  printf '%s\n' "--no-coding-agent-personality skips installing global coding-agent base instructions."
  printf '%s\n' "--uninstall removes files installed by this bundle."
}

log() { printf '%s\n' "$*"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN:'
    for arg in "$@"; do printf ' %q' "$arg"; done
    printf '\n'
  else
    "$@"
  fi
}

copy_file() {
  src="$1"
  dest="$2"
  dir="$(dirname -- "$dest")"
  run mkdir -p "$dir"
  if [ -e "$dest" ]; then
    backup="$dest.bak.$(date +%Y%m%d-%H%M%S)"
    run cp "$dest" "$backup"
    log "Backed up $dest to $backup"
  fi
  run cp "$src" "$dest"
}

remove_path() {
  path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    run rm -rf "$path"
    log "Removed $path"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --tune-config) TUNE_CONFIG=1 ;;
    --coding-agent-personality) CODING_AGENT_PERSONALITY=1 ;;
    --no-coding-agent-personality) CODING_AGENT_PERSONALITY=0 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ ! -f "$ROOT_DIR/payload/skills/token-minimizer/SKILL.md" ]; then
  printf 'ERROR: installer payload not found under %s\n' "$ROOT_DIR" >&2
  exit 1
fi

if [ "$UNINSTALL" -eq 1 ]; then
  if [ -f "$CONFIG_FILE" ] && command -v node >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "DRY-RUN: node $ROOT_DIR/scripts/merge-opencode-config.mjs $CONFIG_FILE --remove-instruction $CONFIG_DIR/instructions/coding-agent-personality.md"
    else
      node "$ROOT_DIR/scripts/merge-opencode-config.mjs" "$CONFIG_FILE" --remove-instruction "$CONFIG_DIR/instructions/coding-agent-personality.md"
    fi
  elif [ -f "$CONFIG_FILE" ]; then
    log "Warning: node not found; uninstall cannot remove coding-agent-personality from $CONFIG_FILE automatically."
  fi
  remove_path "$CONFIG_DIR/skills/token-minimizer"
  remove_path "$CONFIG_DIR/skills/oracle"
  remove_path "$CONFIG_DIR/skills/librarian"
  remove_path "$CONFIG_DIR/skills/coding-agent"
  remove_path "$CONFIG_DIR/agents/plan.md"
  remove_path "$CONFIG_DIR/agents/token-auditor.md"
  remove_path "$CONFIG_DIR/instructions/coding-agent-personality.md"
  remove_path "$BIN_DIR/opencode-token-audit"
  log "Uninstall complete. Restart OpenCode if it is running."
  exit 0
fi

copy_file "$ROOT_DIR/payload/skills/token-minimizer/SKILL.md" "$CONFIG_DIR/skills/token-minimizer/SKILL.md"
copy_file "$ROOT_DIR/payload/skills/oracle/SKILL.md" "$CONFIG_DIR/skills/oracle/SKILL.md"
copy_file "$ROOT_DIR/payload/skills/librarian/SKILL.md" "$CONFIG_DIR/skills/librarian/SKILL.md"
copy_file "$ROOT_DIR/payload/skills/coding-agent/SKILL.md" "$CONFIG_DIR/skills/coding-agent/SKILL.md"
copy_file "$ROOT_DIR/payload/agents/plan.md" "$CONFIG_DIR/agents/plan.md"
copy_file "$ROOT_DIR/payload/agents/token-auditor.md" "$CONFIG_DIR/agents/token-auditor.md"
copy_file "$ROOT_DIR/payload/bin/opencode-token-audit" "$BIN_DIR/opencode-token-audit"

if [ "$DRY_RUN" -eq 0 ]; then
  chmod +x "$BIN_DIR/opencode-token-audit"
fi

if [ "$CODING_AGENT_PERSONALITY" -eq 1 ]; then
  copy_file "$ROOT_DIR/payload/instructions/coding-agent-personality.md" "$CONFIG_DIR/instructions/coding-agent-personality.md"
fi

if [ "$TUNE_CONFIG" -eq 1 ] || [ "$CODING_AGENT_PERSONALITY" -eq 1 ]; then
  if command -v node >/dev/null 2>&1; then
    if [ "$DRY_RUN" -eq 1 ]; then
      extra=""
      [ "$TUNE_CONFIG" -eq 1 ] && extra="$extra --tune-config"
      [ "$CODING_AGENT_PERSONALITY" -eq 1 ] && extra="$extra --coding-agent-personality $CONFIG_DIR/instructions/coding-agent-personality.md"
      log "DRY-RUN: node $ROOT_DIR/scripts/merge-opencode-config.mjs $CONFIG_FILE$extra"
    else
      args=("$CONFIG_FILE")
      [ "$TUNE_CONFIG" -eq 1 ] && args+=("--tune-config")
      [ "$CODING_AGENT_PERSONALITY" -eq 1 ] && args+=("--coding-agent-personality" "$CONFIG_DIR/instructions/coding-agent-personality.md")
      node "$ROOT_DIR/scripts/merge-opencode-config.mjs" "${args[@]}"
    fi
  else
    printf 'ERROR: config merge requires node. Install node or run with --no-coding-agent-personality and without --tune-config.\n' >&2
    exit 1
  fi
fi

log "Installed opencode-config bundle."
log "Skill: $CONFIG_DIR/skills/token-minimizer/SKILL.md"
log "Extra skills: oracle, librarian, coding-agent"
log "Note: existing files with these names are backed up before replacement."
log "Plan mode agent: $CONFIG_DIR/agents/plan.md"
log "Agent: $CONFIG_DIR/agents/token-auditor.md"
log "Audit helper: $BIN_DIR/opencode-token-audit"
if [ "$CODING_AGENT_PERSONALITY" -eq 1 ]; then
  log "Coding-agent personality instructions: $CONFIG_DIR/instructions/coding-agent-personality.md"
fi
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) log "Warning: $BIN_DIR is not on PATH. Run audit helper with: $BIN_DIR/opencode-token-audit" ;;
esac
log ""
log "Next: restart OpenCode so it reloads skills and agents."
log "Then run: opencode-token-audit"
