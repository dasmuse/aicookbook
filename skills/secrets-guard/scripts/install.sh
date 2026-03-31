#!/usr/bin/env bash
# secrets-guard installer
# Usage: bash install.sh <SKILL_PATH> [--force]
#
# Copies guard.sh + patterns.txt into .claude/hooks/secrets-guard/
# and registers the PreToolUse hook in .claude/settings.json.

set -euo pipefail

SKILL_PATH="${1:?Usage: install.sh <SKILL_PATH> [--force]}"
FORCE=false
[[ "${2:-}" == "--force" ]] && FORCE=true

PROJECT_ROOT="$(pwd)"
HOOK_DIR="$PROJECT_ROOT/.claude/hooks/secrets-guard"
SETTINGS="$PROJECT_ROOT/.claude/settings.json"
GUARD_CMD="$HOOK_DIR/guard.sh"

# ── Prerequisites ───────────────────────────────────────────────────────────

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

# ── Check existing installation ─────────────────────────────────────────────

if [[ -f "$GUARD_CMD" ]] && [[ "$FORCE" == false ]]; then
  echo "secrets-guard is already installed at $HOOK_DIR"
  echo "Run with --force to reinstall."
  exit 0
fi

# ── Copy hook files ─────────────────────────────────────────────────────────

mkdir -p "$HOOK_DIR"
cp "$SKILL_PATH/scripts/guard.sh" "$HOOK_DIR/guard.sh"
chmod +x "$HOOK_DIR/guard.sh"

# Only copy default patterns if no custom patterns exist (or forcing)
if [[ ! -f "$HOOK_DIR/patterns.txt" ]] || [[ "$FORCE" == true ]]; then
  cp "$SKILL_PATH/references/default-patterns.txt" "$HOOK_DIR/patterns.txt"
fi

# ── Configure settings.json ─────────────────────────────────────────────────

NEW_HOOK=$(jq -nc --arg cmd "$GUARD_CMD" '{
  "matcher": "Read|Write|Edit|NotebookEdit|Glob|Grep|Bash",
  "hooks": [{"type": "command", "command": $cmd}]
}')

if [[ -f "$SETTINGS" ]]; then
  # Check if secrets-guard hook is already registered
  if jq -e --arg cmd "$GUARD_CMD" '
    .hooks.PreToolUse // [] | any(.hooks[]?; .command == $cmd)
  ' "$SETTINGS" &>/dev/null && [[ "$FORCE" == false ]]; then
    echo "Hook already registered in $SETTINGS"
  else
    # Remove any existing secrets-guard entry, then add the new one
    jq --argjson hook "$NEW_HOOK" --arg guard_dir "secrets-guard" '
      # Ensure hooks.PreToolUse exists
      .hooks //= {} |
      .hooks.PreToolUse //= [] |
      # Remove existing secrets-guard entries (by command path containing secrets-guard)
      .hooks.PreToolUse = [.hooks.PreToolUse[] | select(.hooks[0].command | contains($guard_dir) | not)] |
      # Append new hook
      .hooks.PreToolUse += [$hook]
    ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    echo "Hook registered in $SETTINGS"
  fi
else
  mkdir -p "$(dirname "$SETTINGS")"
  jq -n --argjson hook "$NEW_HOOK" '{
    "hooks": {
      "PreToolUse": [$hook]
    }
  }' > "$SETTINGS"
  echo "Created $SETTINGS with hook"
fi

# ── Done ────────────────────────────────────────────────────────────────────

echo ""
echo "secrets-guard installed successfully"
echo "  Guard:    $HOOK_DIR/guard.sh"
echo "  Patterns: $HOOK_DIR/patterns.txt ($(grep -cvE '^\s*(#|$)' "$HOOK_DIR/patterns.txt") active patterns)"
echo "  Settings: $SETTINGS"
