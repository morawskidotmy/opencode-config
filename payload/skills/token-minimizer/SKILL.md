---
name: token-minimizer
description: Use when minimizing OpenCode token usage, auditing MCP/server/tool bloat, converting repeated workflows into skills, or choosing between MCP, CLI, skills, and subagents.
---

# Token Minimizer

Use this skill whenever the user asks to reduce token usage, context bloat, MCP cost, tool output size, repeated workflow overhead, or agent efficiency in OpenCode.

## Core Rule

Minimize what enters the model context. Preserve capability by loading detail only when the task needs it.

## Decision Matrix

Use the smallest abstraction that fits the job:

| Need | Prefer | Why |
| --- | --- | --- |
| Repeated procedure | Skill | Loads metadata first, full instructions only on demand |
| Local orchestration | CLI or script | Reduces data before model injection |
| Live API/data read | MCP | Good for structured external access |
| Huge API surface | Tool search, proxy, or code mode | Avoids upfront schema tax |
| Judgment-heavy parallel research | Subagent | Isolates context and reasoning |
| Deterministic workflow | Skill or script | Avoid subagent token cost |

## Default Behavior

1. Prefer `glob`, `grep`, and targeted reads over broad file reads.
2. Ask for scope before scanning large repos or many directories.
3. Use scripts or shell pipelines to summarize large data before reading it.
4. Avoid loading full logs, lockfiles, build artifacts, vendored code, or generated files unless necessary.
5. When using MCP, call only the server needed for the current step.
6. Prefer skills for repeated workflows like deploys, audits, data extraction, formatting, reports, and release checks.
7. Prefer CLI tools for orchestration: `git`, `gh`, `jq`, `rg`, package managers, test runners, database CLIs.
8. Prefer MCP for live, authenticated, structured reads where CLI setup would be brittle.
9. Keep tool results bounded. Request summaries, filters, limits, pagination, or specific fields.
10. Use subagents only when independent judgment or context isolation is worth the extra tokens.

## MCP Token Tax Checklist

Before adding or using an MCP server, check:

1. Does this server expose more than 20 tools?
2. Does the task need live external data?
3. Can a CLI do the same job with less context?
4. Can a skill encode the workflow and call a smaller tool surface?
5. Can the server return filtered fields instead of raw JSON?
6. Can the server paginate or summarize by default?
7. Has this server been used in the last two weeks?

If the answer to 2 is no, avoid MCP for that task.

## Patterns To Recommend

**Skill-first workflow** - Turn repeated step-by-step work into a skill with concise frontmatter and supporting scripts. The model pays only metadata cost until the skill is relevant.

**CLI orchestration** - Let the model write or run a shell/script pipeline that reduces data locally, then return a compact result.

**MCP for reads** - Keep MCP servers for live data access, API discovery, and structured reads, not for every local operation.

**Progressive disclosure** - Load names, summaries, or search indexes first. Load full schemas, docs, or file content only after a narrowed choice.

**Response shaping** - Return decision-shaped answers: counts, summaries, top N rows, selected fields, and links to raw data instead of huge payloads.

**Session hygiene** - Start a fresh session after a large investigation, after context compaction, or when the active goal changes sharply.

## OpenCode Config Suggestions

Conservative global settings:

```jsonc
{
  "tool_output": {
    "max_lines": 200,
    "max_bytes": 8192
  },
  "compaction": {
    "auto": true,
    "prune": true,
    "tail_turns": 2
  }
}
```

Do not disable user MCP servers automatically. Audit first, then recommend specific disables.

## Audit Prompt

When asked to reduce token use in a project, inspect only config and structure first:

1. `~/.config/opencode/opencode.jsonc`
2. project `opencode.json`, `opencode.jsonc`, `.opencode/`
3. `AGENTS.md` or instruction files
4. MCP server count and scope
5. skills and commands already installed

Return a short ranked list:

1. Biggest token leak
2. Safest quick win
3. Workflow that should become a skill
4. MCP server to disable or scope
5. Tool output or compaction setting to change
