#!/usr/bin/env bash
# PostToolUse hook: log all Bash commands for audit trail
# Exit 0 always — logging should never block Claude

set -euo pipefail

LOG_FILE="$HOME/.claude/bash-audit.log"
MAX_SIZE=10485760  # 10MB

# Size-based rotation
if [ -f "$LOG_FILE" ]; then
  FILE_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
  if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
    [ -f "${LOG_FILE}.2" ] && mv "${LOG_FILE}.2" "${LOG_FILE}.3"
    [ -f "${LOG_FILE}.1" ] && mv "${LOG_FILE}.1" "${LOG_FILE}.2"
    mv "$LOG_FILE" "${LOG_FILE}.1"
  fi
fi

# Parse and log
INPUT=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

printf '%s\t%s\t%s\t%s\n' "$TIMESTAMP" "$SESSION_ID" "$PROJECT_DIR" "$COMMAND" >> "$LOG_FILE"

exit 0
