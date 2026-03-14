# aicookbook

Collection of reusable Claude Code skills — markdown-based workflow definitions that extend Claude Code's capabilities.

## Available Skills

| Skill | Description |
|-------|-------------|
| `claude-memory` | Create and optimize CLAUDE.md files and `.claude/rules/` for projects |
| `prompt-crafting` | Interactive workflow to craft optimized prompts for subagents/AI tasks |
| `commit` | Quick conventional commit + push (runs on Haiku) |

## Installation

### Plugin marketplace (recommended)

Install all skills at once via the built-in Claude Code plugin system:

```
/plugin marketplace add dasmuse/aicookbook
/plugin install aicookbook@aicookbook-marketplace
```

To update:

```
/plugin marketplace update aicookbook-marketplace
```

### Vercel skills CLI

Install all skills or pick specific ones:

```bash
# All skills
npx skills add dasmuse/aicookbook

# A specific skill
npx skills add dasmuse/aicookbook --skill prompt-crafting

# Install globally (available in all projects)
npx skills add dasmuse/aicookbook -g
```

To update, re-run the same command.

### Manual

```bash
git clone https://github.com/dasmuse/aicookbook.git
cp -r aicookbook/skills/claude-memory ~/.claude/skills/
```

## Adding a Skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`)
2. Optionally add a `references/` directory for supporting docs
3. Bump `version` in `.claude-plugin/marketplace.json`
4. Commit and push — both distribution channels pick it up automatically

## Note

Skills are optimized for Claude Code. Other agents (Cursor, Codex, etc.) can use them via `npx skills add` but may ignore Claude Code-specific frontmatter like `model` and `allowed-tools`.
