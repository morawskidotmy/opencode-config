# opencode-config

An installable OpenCode configuration bundle focused on lower token usage, better agent ergonomics, and a pragmatic coding-agent workflow.

It installs a small set of global OpenCode skills, a read-only token audit agent, a local audit helper, and coding-agent base personality instructions. Optional flags can tune OpenCode config or skip the base personality.

The base personality, `oracle`, `librarian`, and coding-agent workflow patterns are adapted from Amp-style coding-agent work and reshaped for OpenCode's skill, agent, and config system.

> [!IMPORTANT]
> The default install updates your OpenCode config only to add the coding-agent base instruction file. It does not tune token settings and does not disable MCP servers unless you explicitly edit config yourself.

> [!NOTE]
> This bundle installs global skills named `oracle`, `librarian`, and `coding-agent`. If files with those names already exist in `~/.config/opencode/skills/`, the installer creates dated backups before replacing them.

## What You Get

| Component | Installed To | Purpose |
| --- | --- | --- |
| `token-minimizer` skill | `~/.config/opencode/skills/token-minimizer/` | Token-efficient workflow rules for skills, MCP, CLI, subagents, and tool output hygiene |
| `oracle` skill | `~/.config/opencode/skills/oracle/` | Deep technical review, architecture advice, bug diagnosis, and implementation planning |
| `librarian` skill | `~/.config/opencode/skills/librarian/` | External GitHub repository understanding and architecture tracing |
| `coding-agent` skill | `~/.config/opencode/skills/coding-agent/` | Pair-programming behavior as an on-demand skill |
| coding-agent base instructions | `~/.config/opencode/instructions/coding-agent-personality.md` | Global pair-programming defaults applied through OpenCode `instructions` |
| `token-auditor` agent | `~/.config/opencode/agents/token-auditor.md` | Read-only OpenCode/project token-bloat review |
| `opencode-token-audit` | `~/.local/bin/opencode-token-audit` | CLI summary of installed skills, agents, MCP config signals, and token-saving checks |

## Quick Start

Run a dry run first:

```bash
./install.sh --dry-run
```

Install the bundle:

```bash
./install.sh
```

Restart OpenCode so it reloads global skills, agents, and base instructions.

Run the audit helper:

```bash
opencode-token-audit
```

If `~/.local/bin` is not on your `PATH`, use the full path:

```bash
~/.local/bin/opencode-token-audit
```

## Optional Config Tuning

Use `--tune-config` to back up and merge conservative token-saving settings into `~/.config/opencode/opencode.jsonc`:

```bash
./install.sh --tune-config
```

Merged settings:

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

> [!NOTE]
> `--tune-config` creates a dated backup before writing. The edited config is rewritten as formatted JSON, so JSONC comments and trailing commas are not preserved in the edited file. Restore the backup if you need the original formatting.

## Coding-Agent Base Personality

The `coding-agent` skill is installed by default as an on-demand skill. The installer also enables coding-agent behavior globally by copying `coding-agent-personality.md` to `~/.config/opencode/instructions/` and adding it to the global OpenCode `instructions` array.

To skip the global personality and install only the skills, agent, and audit helper:

```bash
./install.sh --no-coding-agent-personality
```

You can still combine config tuning with the default coding-agent personality:

```bash
./install.sh --tune-config
```

## How To Use In OpenCode

Ask for an audit:

```text
Use token-auditor to review this project for token bloat.
```

Convert repeated work into a skill:

```text
Use token-minimizer and suggest how to turn this repeated workflow into a skill.
```

Ask for a second opinion:

```text
Use oracle to review this implementation plan before I build it.
```

Analyze an external GitHub repo:

```text
Use librarian to explain how owner/repo implements feature X.
```

Use coding-agent behavior on demand:

```text
Use coding-agent and help me implement this with a concise pair-programming workflow.
```

## Design Principles

This project follows the 2026 token-efficiency consensus from recent MCP and agent workflow research:

- Use skills for repeated procedural workflows.
- Use CLI/scripts for deterministic orchestration and local data reduction.
- Use MCP mainly for live, structured, external reads.
- Use subagents for judgment-heavy work where context isolation is worth the cost.
- Avoid loading broad tool schemas, full logs, generated files, lockfiles, and raw JSON dumps unless needed.
- Keep tool outputs filtered, paginated, summarized, and bounded.

## Safety Model

- Default install only copies files.
- Existing installed files are backed up before replacement.
- `token-auditor` denies edits and bash by default.
- MCP servers are never disabled automatically.
- Config changes are opt-in and backed up.
- Uninstall removes installed bundle files but does not rewrite OpenCode config.

## Commands

| Command | Description |
| --- | --- |
| `./install.sh --dry-run` | Show what would be installed |
| `./install.sh` | Install skills, agent, audit helper, and coding-agent base personality |
| `./install.sh --tune-config` | Install and merge token-saving config |
| `./install.sh --no-coding-agent-personality` | Install without global coding-agent base instructions |
| `./install.sh --uninstall` | Remove installed bundle files |
| `./tests/smoke.sh` | Run syntax checks and isolated temp install tests |

## Verify

Run the smoke test before publishing or after making changes:

```bash
./tests/smoke.sh
```

Expected output:

```text
Smoke test passed
```

## Project Layout

```text
opencode-config/
├── install.sh
├── README.md
├── payload/
│   ├── agents/
│   ├── bin/
│   ├── config/
│   ├── instructions/
│   └── skills/
├── scripts/
└── tests/
```

## Uninstall

```bash
./install.sh --uninstall
```

Uninstall removes the coding-agent personality instruction entry from `opencode.jsonc` when `node` is available. If you installed with `--tune-config`, restore the dated config backup if you want to fully revert config tuning.
