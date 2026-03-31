#!/usr/bin/env bash
# secrets-guard uninstaller
# Removes the hook files and the PreToolUse entry from settings.json.

set -euo pipefail

PROJECT_ROOT="$(pwd)"
HOOK_DIR="$PROJECT_ROOT/.claude/hooks/secrets-guard"
SETTINGS="$PROJECT_ROOT/.claude/settings.json"

removed=()

# ── Remove hook from settings.json ──────────────────────────────────────────

if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
  if jq -e '.hooks.PreToolUse' "$SETTINGS" &>/dev/null; then
    jq --arg guard_dir "secrets-guard" '
      .hooks.PreToolUse = [.hooks.PreToolUse[] | select(.hooks[0].command | contains($guard_dir) | not)] |
      # Clean up empty arrays
      if (.hooks.PreToolUse | length) == 0 then del(.hooks.PreToolUse) else . end |
      if (.hooks | length) == 0 then del(.hooks) else . end
    ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    removed+=("Hook entry from $SETTINGS")
  fi
fi

# ── Remove hook files ───────────────────────────────────────────────────────

if [[ -d "$HOOK_DIR" ]]; then
  rm -rf "$HOOK_DIR"
  removed+=("$HOOK_DIR")
fi

# ── Report ──────────────────────────────────────────────────────────────────

if [[ ${#removed[@]} -eq 0 ]]; then
  echo "secrets-guard was not installed in this project."
else
  echo "secrets-guard uninstalled:"
  for item in "${removed[@]}"; do
    echo "  Removed: $item"
  done
fi
