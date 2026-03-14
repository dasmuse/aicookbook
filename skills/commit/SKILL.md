---
name: commit
description: Quick commit with minimal, clean messages
model: haiku
allowed-tools: Bash(git :*), Bash(npm :*), Bash(pnpm :*)
---

# Commit

Quick commit with conventional message format.

## Context

- Git state: !`git status`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Recent commits: !`git log --oneline -5`
- Current branch: !`git branch --show-current`

## Workflow

1. **Analyze**: Review git status
   - Nothing staged but unstaged changes exist: `git add .`
   - Nothing to commit: inform user and exit

2. **Generate commit message**:
   - Format: `type(scope): brief description`
   - Types: `feat`, `fix`, `update`, `docs`, `chore`, `refactor`, `test`, `perf`, `revert`
   - Under 72 chars, imperative mood, lowercase after colon
   - Example: `update(statusline): refresh spend data`

3. **Commit**: `git commit -m "message"`

## Rules

- SPEED OVER PERFECTION: Generate one good message and commit
- NO INTERACTION: Never ask questions - analyze and commit
- AUTO-STAGE: If nothing staged, stage everything
- NO-PUSH: Never push after committing
- IMPERATIVE MOOD: "add", "update", "fix" not past tense
