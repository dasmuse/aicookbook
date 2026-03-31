---
name: secrets-guard
description: "Install and configure secrets-guard PreToolUse hooks to prevent Claude from accessing sensitive files (.env, private keys, credentials, cloud configs, shell history — 70+ patterns). Use this skill whenever the user wants to protect secrets, guard sensitive files, set up security hooks, block access to credentials or API keys, or mentions 'secrets-guard'. Also trigger when the user asks about preventing accidental file exposure, securing their Claude Code environment, or adding file access controls."
argument-hint: "[install | test | customize | uninstall]"
---

# secrets-guard

Installs a PreToolUse hook that intercepts `Read`, `Write`, `Edit`, `NotebookEdit`, `Bash`, `Glob`, and `Grep` tool calls and denies access when file paths or commands match sensitive patterns (70+ regex patterns covering env files, private keys, cloud credentials, shell history, and more).

## On invoke (default: install)

1. **Check prerequisites** — verify `jq` is installed:
   ```bash
   command -v jq
   ```
   If missing, tell the user: "jq is required — install with `brew install jq` (macOS) or `apt install jq` (Linux)" and stop.

2. **Run the installer:**
   ```bash
   bash "{SKILL_PATH}/scripts/install.sh" "{SKILL_PATH}"
   ```

3. **Run the test suite** to verify everything works:
   ```bash
   bash "{SKILL_PATH}/scripts/test_guard.sh" ".claude/hooks/secrets-guard/guard.sh"
   ```

4. **Report results.** Tell the user:
   - The hook is active — it will block access to sensitive files on every tool call
   - Patterns can be customized at `.claude/hooks/secrets-guard/patterns.txt`
   - This is a deterrent layer, not a sandbox — Bash obfuscation techniques (variable indirection, encoding, symlinks) can bypass string-pattern matching

## If argument is "test"

Run the test suite against the installed guard:

```bash
bash "{SKILL_PATH}/scripts/test_guard.sh" ".claude/hooks/secrets-guard/guard.sh"
```

Report pass/fail results.

## If argument is "customize"

1. Read `.claude/hooks/secrets-guard/patterns.txt`
2. Show the current patterns organized by category
3. Ask what the user wants to add or remove
4. Edit the patterns file
5. Run the test suite to verify nothing broke

## If argument is "uninstall"

```bash
bash "{SKILL_PATH}/scripts/uninstall.sh"
```

Report what was removed.

## What gets protected

| Category | Examples |
|---|---|
| Environment files | `.env`, `.env.*`, `.flaskenv` |
| Private keys | `.pem`, `.key`, `.p12`, SSH keys |
| SSH | `.ssh/` directory |
| App secrets | `credentials.json`, `secrets.yml`, `master.key`, `token.json` |
| Cloud credentials | `.aws/credentials`, `.kube/config`, `.config/gcloud/`, `.azure/` |
| Infrastructure | `.tfvars`, `terraform.tfstate`, `ansible-vault` |
| Shell history | `.bash_history`, `.zsh_history`, `.psql_history` |
| Package auth | `.npmrc`, `.pypirc`, `.gem/credentials` |
| Encryption | `.gpg`, `.asc`, `.age`, keystores |

Full pattern list: `{SKILL_PATH}/references/default-patterns.txt`

## How it works

The guard script receives tool invocation JSON on stdin. It extracts the relevant path or command depending on the tool type, then matches against regex patterns loaded from `patterns.txt`. On match, it returns a JSON deny response that Claude Code's hook system understands. On no match, it exits silently (allow).

The guard is **fail-closed**: if `patterns.txt` is missing, all operations are blocked for safety.
