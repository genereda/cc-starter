#!/usr/bin/env bash
set -euo pipefail

# Claude Code Starter Kit — Installer
# Copies CLAUDE.md, settings.json, hooks, and skills into ~/.claude/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"
BACKUP_DIR="$CLAUDE_DIR/backups/starter-kit-$(date +%Y%m%d-%H%M%S)"

echo "Claude Code Starter Kit Installer"
echo "================================="
echo ""

# Check if Claude Code directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating $CLAUDE_DIR ..."
    mkdir -p "$CLAUDE_DIR"
fi

# Backup existing files
backup_needed=false
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    backup_needed=true
fi
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    backup_needed=true
fi

if [ "$backup_needed" = true ]; then
    echo "Backing up existing files to $BACKUP_DIR ..."
    mkdir -p "$BACKUP_DIR"
    [ -f "$CLAUDE_DIR/CLAUDE.md" ] && cp "$CLAUDE_DIR/CLAUDE.md" "$BACKUP_DIR/"
    [ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$BACKUP_DIR/"
    echo "  Backup complete."
    echo ""
fi

# Copy CLAUDE.md
echo "Installing CLAUDE.md ..."
cp "$SCRIPT_DIR/claude-md/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# Copy settings.json (only if none exists — don't overwrite existing config)
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    echo "Skipping settings.json (already exists, backed up above)."
    echo "  Review $SCRIPT_DIR/settings/settings.json and merge manually if desired."
else
    echo "Installing settings.json ..."
    cp "$SCRIPT_DIR/settings/settings.json" "$CLAUDE_DIR/settings.json"
fi

# Copy hooks
echo "Installing hooks ..."
mkdir -p "$HOOKS_DIR"

hooks_count=0
for hook_file in "$SCRIPT_DIR/hooks"/*.sh; do
    [ -f "$hook_file" ] || continue
    hook_name="$(basename "$hook_file")"
    target_file="$HOOKS_DIR/$hook_name"

    if [ -f "$target_file" ]; then
        echo "  Skipping $hook_name (already exists)"
    else
        cp "$hook_file" "$target_file"
        chmod +x "$target_file"
        echo "  Installed $hook_name"
        hooks_count=$((hooks_count + 1))
    fi
done

# Copy skills
echo "Installing skills ..."
mkdir -p "$SKILLS_DIR"

installed_count=0
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    target_dir="$SKILLS_DIR/$skill_name"

    if [ -d "$target_dir" ]; then
        echo "  Skipping $skill_name (already exists)"
    else
        cp -r "$skill_dir" "$target_dir"
        echo "  Installed $skill_name"
        installed_count=$((installed_count + 1))
    fi
done

echo ""
echo "Done!"
echo "  CLAUDE.md: installed"
echo "  Settings:  $([ -f "$BACKUP_DIR/settings.json" ] 2>/dev/null && echo "skipped (backup at $BACKUP_DIR)" || echo "installed")"
echo "  Hooks:     $hooks_count new hook(s) installed"
echo "  Skills:    $installed_count new skill(s) installed"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.claude/CLAUDE.md to customize for your workflow"
echo "  2. Check examples/ for hook templates (Telegram notifications) and infrastructure skills"
echo "  3. Run 'claude' to start a session with your new config"
