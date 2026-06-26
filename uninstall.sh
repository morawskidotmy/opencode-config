#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
CONFIG_FILE="$CONFIG_DIR/opencode.jsonc"
DRY_RUN=0

usage() {
  printf '%s\n' "Usage: $0 [--dry-run]"
  printf '%s\n' ""
  printf '%s\n' "Removes files installed by this bundle, including old oracle/librarian skill installs."
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
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ -f "$CONFIG_FILE" ] && command -v node >/dev/null 2>&1; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "DRY-RUN: node $ROOT_DIR/scripts/merge-opencode-config.mjs $CONFIG_FILE --remove-instruction $CONFIG_DIR/instructions/coding-agent-personality.md"
  else
    node "$ROOT_DIR/scripts/merge-opencode-config.mjs" "$CONFIG_FILE" --remove-instruction "$CONFIG_DIR/instructions/coding-agent-personality.md"
  fi
elif [ -f "$CONFIG_FILE" ]; then
  log "Warning: node not found; uninstall cannot remove coding-agent-personality from $CONFIG_FILE automatically."
fi

remove_path "$CONFIG_DIR/skills/oracle"
remove_path "$CONFIG_DIR/skills/librarian"
remove_path "$CONFIG_DIR/skills/coding-agent"
remove_path "$CONFIG_DIR/agents/plan.md"
remove_path "$CONFIG_DIR/agents/oracle.md"
remove_path "$CONFIG_DIR/agents/librarian.md"
remove_path "$CONFIG_DIR/instructions/coding-agent-personality.md"
log "Uninstall complete. Restart OpenCode if it is running."
