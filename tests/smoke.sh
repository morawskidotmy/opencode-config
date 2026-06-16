#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/opencode-config-smoke.$$"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_DIR"

bash -n "$ROOT_DIR/install.sh"
bash -n "$ROOT_DIR/payload/bin/opencode-token-audit"
node --check "$ROOT_DIR/scripts/merge-opencode-config.mjs"

"$ROOT_DIR/install.sh" --dry-run >/dev/null
"$ROOT_DIR/install.sh" --dry-run --tune-config >/dev/null
"$ROOT_DIR/install.sh" --dry-run --no-coding-agent-personality >/dev/null

OPENCODE_CONFIG_DIR="$TMP_DIR/config" OPENCODE_TOKEN_MINIMIZER_BIN="$TMP_DIR/bin" \
  "$ROOT_DIR/install.sh" --tune-config >/dev/null

test -f "$TMP_DIR/config/skills/token-minimizer/SKILL.md"
test -f "$TMP_DIR/config/skills/oracle/SKILL.md"
test -f "$TMP_DIR/config/skills/librarian/SKILL.md"
test -f "$TMP_DIR/config/skills/coding-agent/SKILL.md"
test -f "$TMP_DIR/config/agents/plan.md"
test -f "$TMP_DIR/config/agents/token-auditor.md"
test -f "$TMP_DIR/config/instructions/coding-agent-personality.md"
test -x "$TMP_DIR/bin/opencode-token-audit"

OPENCODE_CONFIG_DIR="$TMP_DIR/config" "$TMP_DIR/bin/opencode-token-audit" >/dev/null

node -e 'const fs=require("fs"); const cfg=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); if(!cfg.tool_output||!cfg.compaction||!cfg.instructions?.length) process.exit(1)' "$TMP_DIR/config/opencode.jsonc"

OPENCODE_CONFIG_DIR="$TMP_DIR/config-no-personality" OPENCODE_TOKEN_MINIMIZER_BIN="$TMP_DIR/bin-no-personality" \
  "$ROOT_DIR/install.sh" --no-coding-agent-personality >/dev/null
node -e 'const fs=require("fs"); const p=process.argv[1]; if(fs.existsSync(p)){ const cfg=JSON.parse(fs.readFileSync(p,"utf8")); if(cfg.instructions?.length) process.exit(1) }' "$TMP_DIR/config-no-personality/opencode.jsonc"

OPENCODE_CONFIG_DIR="$TMP_DIR/config" OPENCODE_TOKEN_MINIMIZER_BIN="$TMP_DIR/bin" \
  "$ROOT_DIR/install.sh" --uninstall >/dev/null

test ! -e "$TMP_DIR/config/skills/token-minimizer"
test ! -e "$TMP_DIR/config/skills/oracle"
test ! -e "$TMP_DIR/config/skills/librarian"
test ! -e "$TMP_DIR/config/skills/coding-agent"
test ! -e "$TMP_DIR/config/agents/plan.md"
test ! -e "$TMP_DIR/config/agents/token-auditor.md"
test ! -e "$TMP_DIR/bin/opencode-token-audit"
node -e 'const fs=require("fs"); const cfg=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); if(cfg.instructions?.includes(process.argv[2])) process.exit(1)' "$TMP_DIR/config/opencode.jsonc" "$TMP_DIR/config/instructions/coding-agent-personality.md"

printf '%s\n' "Smoke test passed"
