#!/usr/bin/env bash
# PreToolUse hook: notify via Telegram when chrome-cdp is invoked
# so the user knows to approve the "Allow debugging" prompt in Chrome.
# Exit 0 always — notification failure should never block Claude.
#
# Setup: requires telegram.env next to this script (same as notify-telegram.sh)
#
# Hook config in settings.json:
#   "PreToolUse": [{
#     "matcher": "Bash",
#     "hooks": [{ "type": "command", "command": "~/.claude/hooks/cdp-notify.sh", "async": true }]
#   }]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/telegram.env"

# Read stdin
INPUT=$(cat)

# Only care about Bash commands that invoke cdp.mjs
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ "$COMMAND" != *cdp.mjs* ]] && exit 0

# Skip stop — it never triggers Allow prompts
[[ "$COMMAND" == *"cdp.mjs stop"* ]] && exit 0

# Load Telegram credentials
[ ! -f "$ENV_FILE" ] && exit 0
# shellcheck source=/dev/null
source "$ENV_FILE"
[ -z "${TELEGRAM_BOT_TOKEN:-}" ] && exit 0
[ -z "${TELEGRAM_CHAT_ID:-}" ] && exit 0

# Debounce: only notify once per 60 seconds
LAST_SENT_FILE="$SCRIPT_DIR/.cdp-notify-last-sent"
NOW=$(date +%s)
if [ -f "$LAST_SENT_FILE" ]; then
  LAST_SENT=$(cat "$LAST_SENT_FILE" 2>/dev/null || echo 0)
  ELAPSED=$((NOW - LAST_SENT))
  [ "$ELAPSED" -lt 60 ] && exit 0
fi

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
PROJECT_NAME=$(basename "$PROJECT_DIR")

MESSAGE="🌐 *Chrome CDP invoked*
📁 \`${PROJECT_NAME}\`
🔧 \`${COMMAND}\`

You may need to approve the \"Allow debugging\" prompt in Chrome."

JSON_PAYLOAD=$(jq -n \
  --arg chat_id "$TELEGRAM_CHAT_ID" \
  --arg text "$MESSAGE" \
  '{chat_id: $chat_id, text: $text, parse_mode: "Markdown"}')

echo "$NOW" > "$LAST_SENT_FILE"

curl -s -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  --max-time 5 \
  >/dev/null 2>&1 || true

exit 0
