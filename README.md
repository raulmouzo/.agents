# .agents

Global agent configuration, currently using Claude Code as the harness: a set of shared rules (`AGENTS.md`) and three subagents that split non-trivial work into plan → code → review.

| Agent      | Model  | Role                                                                                  | Can edit files |
| ---------- | ------ | ------------------------------------------------------------------------------------- | -------------- |
| `planner`  | opus   | Reads code and official docs, returns a plan, library alternatives and open questions | No             |
| `coder`    | sonnet | Implements the plan the user approved, nothing more                                   | Yes            |
| `reviewer` | opus   | Checks the result against the plan and `AGENTS.md`, runs typecheck/lint/tests         | No             |

Subagents can't spawn other subagents (the `Agent` tool is disallowed), so the main session orchestrates the flow described in `AGENTS.md`.

## Requirements

Claude Code needs to load `AGENTS.md`, but out of the box it only reads `CLAUDE.md`. Either configure your setup to load `AGENTS.md`, or add this line to `~/.claude/CLAUDE.md` (create the file if it doesn't exist):

```markdown
@AGENTS.md
```

## Install

```bash
./install.sh
```

Copies `AGENTS.md` and the subagents into `~/.claude`, asking before replacing any file that already exists. It also merges the permission rules from `settings.json` into `~/.claude/settings.json` (requires `python3`), adding only the missing rules and leaving every other setting untouched.

## License

MIT
