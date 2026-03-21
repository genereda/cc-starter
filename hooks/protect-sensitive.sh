#!/usr/bin/env bash
# PreToolUse hook: warn or block edits to sensitive files
# Exit 2 = hard block, Exit 0 with stdout = warning Claude sees

set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE" ] && exit 0

BASENAME=$(basename "$FILE")
DIR=$(dirname "$FILE")

# --- Hard block: private keys (exit 2) ---
case "$BASENAME" in
  id_ed25519|id_rsa|id_ecdsa|id_dsa)
    echo "BLOCKED: Refusing to edit SSH private key: $FILE" >&2
    exit 2
    ;;
esac
case "$FILE" in
  *.pem|*.p12|*.pfx)
    echo "BLOCKED: Refusing to edit certificate/key file: $FILE" >&2
    exit 2
    ;;
esac

# --- Strong warning: secrets and credentials (exit 0 with message) ---
WARN=""
case "$BASENAME" in
  .env|.env.*|*.env) WARN="secrets/environment variables" ;;
  *credentials*|*secret*|*token*) WARN="credentials/secrets" ;;
  *.key) WARN="key file" ;;
esac

if [ -n "$WARN" ]; then
  echo "WARNING: You are about to edit a file containing $WARN: $FILE"
  echo "Confirm with the user before proceeding. This file may contain sensitive data."
  exit 0
fi

# --- Soft warning: infrastructure configs ---
case "$FILE" in
  /etc/nginx/*|/etc/ssl/*)
    echo "NOTICE: Editing system config file: $FILE — verify changes with 'nginx -t' after."
    exit 0
    ;;
  */.github/workflows/*)
    echo "NOTICE: Editing CI/CD workflow: $FILE — changes will affect automated pipelines."
    exit 0
    ;;
esac

# --- Per-project protection list ---
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/.claude/protected-files.txt" ]; then
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    [[ "$pattern" == \#* ]] && continue
    # shellcheck disable=SC2254
    case "$FILE" in
      $pattern)
        echo "WARNING: This file matches a project-specific protection rule ($pattern): $FILE"
        echo "Confirm with the user before proceeding."
        exit 0
        ;;
    esac
  done < "$CLAUDE_PROJECT_DIR/.claude/protected-files.txt"
fi

exit 0
