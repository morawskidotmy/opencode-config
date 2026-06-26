# opencode-config

An installable OpenCode configuration bundle focused on lower token usage, better agent ergonomics, and a pragmatic coding-agent workflow.

It installs a small set of global OpenCode skills, Oracle and Librarian subagents, an Oracle-style plan mode agent, and coding-agent base personality instructions. Optional flags can tune OpenCode config or skip the base personality.

The base personality, Oracle/Librarian agents, and coding-agent workflow patterns are adapted from Amp-style coding-agent work and reshaped for OpenCode's agent, skill, and config system.

> [!IMPORTANT]
> The default install updates your OpenCode config only to add the coding-agent base instruction file. It does not tune token settings and does not disable MCP servers unless you explicitly edit config yourself.

> [!NOTE]
> This bundle installs a global skill named `coding-agent`, global agents named `oracle` and `librarian`, and overrides the global `plan` agent. If matching files already exist under `~/.config/opencode/skills/` or `~/.config/opencode/agents/`, the installer creates dated backups before replacing them. Older installs that created `oracle` and `librarian` skills are cleaned up by `./uninstall.sh` or `./install.sh --uninstall`.

## What You Get

| Component | Installed To | Purpose |
| --- | --- | --- |
| `oracle` agent | `~/.config/opencode/agents/oracle.md` | Subagent version of Oracle for direct OpenCode agent invocation |
| Oracle plan agent | `~/.config/opencode/agents/plan.md` | Makes OpenCode plan mode use the Oracle technical-advisor personality while preserving read-only edits |
| `librarian` agent | `~/.config/opencode/agents/librarian.md` | Subagent version of Librarian for direct OpenCode agent invocation |
| `coding-agent` skill | `~/.config/opencode/skills/coding-agent/` | Pair-programming behavior as an on-demand skill |
| coding-agent base instructions | `~/.config/opencode/instructions/coding-agent-personality.md` | Global pair-programming defaults applied through OpenCode `instructions` |

## Quick Start

Run a dry run first:

```bash
./install.sh --dry-run
```

Install the bundle:

```bash
./install.sh
```

Restart OpenCode so it reloads global skills, agents, plan mode, and base instructions.

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

To skip the global personality and install only the skill and agents:

```bash
./install.sh --no-coding-agent-personality
```

You can still combine config tuning with the default coding-agent personality:

```bash
./install.sh --tune-config
```

## How To Use In OpenCode

Ask for a second opinion:

```text
Use oracle to review this implementation plan before I build it.
```

OpenCode plan mode also uses the Oracle personality by default after installation.

Use Oracle as a direct subagent:

```text
Use the oracle agent to review this architecture before I implement it.
```

Analyze an external GitHub repo:

```text
Use librarian to explain how owner/repo implements feature X.
```

Use Librarian as a direct subagent:

```text
Use the librarian agent to trace how owner/repo handles authentication.
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
- MCP servers are never disabled automatically.
- Config changes are opt-in and backed up.
- Uninstall removes installed bundle files but does not rewrite OpenCode config.

## Commands

| Command | Description |
| --- | --- |
| `./install.sh --dry-run` | Show what would be installed |
| `./install.sh` | Install skill, plan agent, agents, and coding-agent base personality |
| `./install.sh --tune-config` | Install and merge token-saving config |
| `./install.sh --no-coding-agent-personality` | Install without global coding-agent base instructions |
| `./install.sh --uninstall` | Remove installed bundle files |
| `./uninstall.sh` | Remove installed bundle files, including old Oracle/Librarian skill installs |
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

Or use the standalone uninstall script:

```bash
./uninstall.sh
```

Uninstall removes the coding-agent personality instruction entry from `opencode.jsonc` when `node` is available. It also removes old `oracle` and `librarian` skill directories from previous versions. If you installed with `--tune-config`, restore the dated config backup if you want to fully revert config tuning.
