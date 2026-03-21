#!/usr/bin/env bash
# Notification hook: send Telegram DM when Claude needs attention
# Exit 0 always — notification failure should never block Claude
#
# Setup:
#   1. Create a Telegram bot via @BotFather and get the token
#   2. Get your chat ID (send a message to @userinfobot)
#   3. Create telegram.env next to this script with:
#        TELEGRAM_BOT_TOKEN=your-bot-token
#        TELEGRAM_CHAT_ID=your-chat-id
#   4. Optional: set TELEGRAM_IDLE_THRESHOLD (seconds, default 120)
#   5. Optional: set TELEGRAM_EXCLUDED_PROJECTS (space-separated project names to skip)
#
# Hook config in settings.json:
#   "Notification": [{
#     "matcher": "",
#     "hooks": [{ "type": "command", "command": "~/.claude/hooks/notify-telegram.sh", "async": true }]
#   }]

set -uo pipefail
# Note: -e omitted intentionally. Hook must always exit 0; we handle errors explicitly.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/telegram.env"

# Load credentials
if [ ! -f "$ENV_FILE" ]; then
  exit 0
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

[ -z "${TELEGRAM_BOT_TOKEN:-}" ] && exit 0
[ -z "${TELEGRAM_CHAT_ID:-}" ] && exit 0

# Skip if user is actively at the Mac (local keyboard/mouse activity)
# HIDIdleTime = seconds since last local input. If low, user sees the terminal directly.
# Threshold is configurable via TELEGRAM_IDLE_THRESHOLD in telegram.env (default: 120s)
IDLE_THRESHOLD="${TELEGRAM_IDLE_THRESHOLD:-120}"
IDLE_SECONDS=$(ioreg -c IOHIDSystem 2>/dev/null | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
if [ -n "$IDLE_SECONDS" ] && [ "$IDLE_SECONDS" -lt "$IDLE_THRESHOLD" ]; then
  exit 0  # User is at the Mac — they'll see the terminal
fi

# Read stdin once (consumed by first cat)
INPUT=$(cat)

# Skip excluded projects
EXCLUDED_PROJECTS="${TELEGRAM_EXCLUDED_PROJECTS:-}"
PEEK_PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
PEEK_PROJECT_NAME=$(basename "$PEEK_PROJECT_DIR")
for EXCL in $EXCLUDED_PROJECTS; do
  [ "$PEEK_PROJECT_NAME" = "$EXCL" ] && exit 0
done

# Debounce: skip if last notification was <10 seconds ago
LAST_SENT_FILE="$SCRIPT_DIR/.telegram-last-sent"
NOW=$(date +%s)
if [ -f "$LAST_SENT_FILE" ]; then
  LAST_SENT=$(cat "$LAST_SENT_FILE" 2>/dev/null || echo 0)
  ELAPSED=$((NOW - LAST_SENT))
  [ "$ELAPSED" -lt 10 ] && exit 0
fi

# Parse notification
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // .hook_event_name // "notification"')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
PROJECT_NAME=$(basename "$PROJECT_DIR")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' | cut -c1-8)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
MESSAGE_TEXT=$(echo "$INPUT" | jq -r '.notification_message // .message // empty')

# Map notification types to human-friendly labels + emoji
case "$NOTIFICATION_TYPE" in
  permission_prompt)  LABEL="Waiting for permission" ; ICON="🔐" ;;
  idle_prompt)        LABEL="Idle — waiting for input" ; ICON="💤" ;;
  auth_success)       LABEL="Auth succeeded" ; ICON="✅" ;;
  auth_failure)       LABEL="Auth failed" ; ICON="❌" ;;
  stop|Stop)          LABEL="Task finished" ; ICON="🏁" ;;
  *)                  LABEL="$NOTIFICATION_TYPE" ; ICON="🔔" ;;
esac

# Build message with available context
MESSAGE="${ICON} *${LABEL}*"
MESSAGE="${MESSAGE}
📁 \`${PROJECT_NAME}\`"

[ -n "$TOOL_NAME" ] && MESSAGE="${MESSAGE}
🔧 Tool: \`${TOOL_NAME}\`"

[ -n "$MESSAGE_TEXT" ] && MESSAGE="${MESSAGE}
💬 ${MESSAGE_TEXT}"

[ -n "$SESSION_ID" ] && MESSAGE="${MESSAGE}
🆔 Session: \`${SESSION_ID}…\`"

# Build JSON payload (handles special chars and newlines correctly)
JSON_PAYLOAD=$(jq -n \
  --arg chat_id "$TELEGRAM_CHAT_ID" \
  --arg text "$MESSAGE" \
  '{chat_id: $chat_id, text: $text, parse_mode: "Markdown"}')

# Update debounce timestamp (before send, to avoid races)
echo "$NOW" > "$LAST_SENT_FILE"

# Send via Telegram Bot API (fire and forget)
curl -s -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  --max-time 5 \
  >/dev/null 2>&1 || true

exit 0
