#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Edit/Write
# Exit 0 always — formatting should never block Claude

set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
[ -z "$FILE" ] && exit 0
# Skip if file doesn't exist (was deleted)
[ -f "$FILE" ] || exit 0
# Skip vendor/generated directories
case "$FILE" in
  */node_modules/*|*/.git/*|*/dist/*|*/build/*|*/.next/*|*/venv/*|*/__pycache__/*) exit 0 ;;
esac
# Skip large files (>1MB)
FILE_SIZE=$(stat -f%z "$FILE" 2>/dev/null || echo 0)
[ "$FILE_SIZE" -gt 1048576 ] && exit 0

# Format based on extension
case "$FILE" in
  *.js|*.ts|*.jsx|*.tsx|*.css|*.scss|*.json|*.md|*.html|*.yaml|*.yml)
    prettier --write "$FILE" >/dev/null 2>&1 || true
    ;;
  *.py)
    ruff format "$FILE" >/dev/null 2>&1 || true
    ;;
  *.swift)
    swiftformat "$FILE" >/dev/null 2>&1 || true
    ;;
esac

exit 0
