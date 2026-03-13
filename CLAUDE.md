# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Collection of reusable Claude Code skills — markdown-based workflow definitions that extend Claude Code's capabilities via the Skill tool.

## Structure

Each skill lives in `skills/<skill-name>/` with:
- `SKILL.md` — the skill definition (frontmatter + instructions)
- `references/` — supporting reference docs the skill reads at runtime

### Current skills

- **claude-memory** — Create and optimize CLAUDE.md files and `.claude/rules/` for projects
- **prompt-crafting** — Interactive workflow to craft optimized prompts for subagents/AI tasks
- **commit** — Quick conventional commit + push (runs on Haiku)

## Skill Anatomy

Skills use YAML frontmatter for metadata:
```yaml
---
name: skill-name
description: When to trigger this skill
argument-hint: [optional usage hint]
model: haiku  # optional model override
allowed-tools: Bash(git :*)  # optional tool restrictions
---
```

The body is markdown instructions that Claude follows when the skill is invoked. Skills can reference their own files via `{SKILL_PATH}/references/`.

## Rules

- Skills are pure markdown — no build step, no dependencies
- Reference files are read lazily by the skill at runtime, not preloaded
- Skill frontmatter `description` field is critical — it determines when Claude auto-triggers the skill
