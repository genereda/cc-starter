---
name: new-project-onboarding
description: >
  Scaffold a new project with standard structure: CLAUDE.md, settings, scratchpad, plan template, git init.
  Use when starting a new project from scratch, bootstrapping a workspace, or initializing a project directory.
  Triggers on: "new project", "start a project", "scaffold", "bootstrap", "init project", "set up a new repo".
---

# Project Bootstrap Skill

## Workflow

1. **Gather project info** (ask if not provided):
   - Project name (lowercase-hyphenated)
   - Project type: swift-ios | react-nextjs | python-cli | static-site | general
   - One-line description of what it does
   - Will it be deployed to a server? (yes/no)

2. **Create project directory:**

   ```
   ~/projects/<project-name>/
   ```

3. **Scaffold files based on project type:**

### All projects get:

**CLAUDE.md** — Project instructions for Claude Code:

```markdown
# CLAUDE.md

## Project Purpose

<one-line description>

## Environment Context

- **Platform:** macOS (Darwin), Apple Silicon
- **Shell:** zsh

## Technical Approach

<to be filled during planning>

## Conventions

- Record completed work and decisions in `scratchpad.md`
- Log key learnings in this file
```

**scratchpad.md** — Working notes:

```markdown
# Scratchpad

Working notes for <project-name>.
```

**plan.md** — Planning template:

```markdown
# Plan: <project-name>

## Problem Statement

<what problem does this solve?>

## Success Criteria

- [ ] <measurable outcome 1>
- [ ] <measurable outcome 2>

## Scope

### IN

-

### OUT

-

## Technical Approach

<high-level design>

## Open Questions

-
```

**.gitignore** — Project-type-appropriate ignores (see below).

**.claude/settings.local.json** — Project-type-appropriate permissions (see below).

### Type-specific additions:

**swift-ios:**

- .gitignore: `.build/`, `.swiftpm/`, `*.xcodeproj/xcuserdata/`, `DerivedData/`, `.DS_Store`
- settings.local.json permissions: `Bash(swift:*)`, `Bash(xcodebuild:*)`, `Bash(xcrun:*)`, `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git push:*)`, `Bash(git diff:*)`, `Bash(git status:*)`, `Bash(git log:*)`
- CLAUDE.md additions: Xcode build conventions, simulator targets

**react-nextjs:**

- .gitignore: `node_modules/`, `.next/`, `out/`, `.env*.local`, `.DS_Store`
- settings.local.json permissions: `Bash(npm:*)`, `Bash(npx:*)`, `Bash(node:*)`, `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git push:*)`, `Bash(git diff:*)`, `Bash(git status:*)`, `Bash(git log:*)`
- CLAUDE.md additions: Build/dev commands, deployment target

**python-cli:**

- .gitignore: `venv/`, `__pycache__/`, `*.pyc`, `.ruff_cache/`, `dist/`, `*.egg-info/`, `.DS_Store`
- settings.local.json permissions: `Bash(python3:*)`, `Bash(pip:*)`, `Bash(pytest:*)`, `Bash(ruff:*)`, `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git push:*)`, `Bash(git diff:*)`, `Bash(git status:*)`, `Bash(git log:*)`
- CLAUDE.md additions: Python version, venv conventions

**static-site:**

- .gitignore: `.DS_Store`, `node_modules/`
- settings.local.json permissions: `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git push:*)`, `Bash(git diff:*)`, `Bash(git status:*)`, `Bash(git log:*)`
- CLAUDE.md additions: Hosting target (subdirectory or dedicated domain)

**general:**

- .gitignore: `.DS_Store`, `.env`
- settings.local.json permissions: `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git push:*)`, `Bash(git diff:*)`, `Bash(git status:*)`, `Bash(git log:*)`

### Server-deployed projects additionally get:

- CLAUDE.md section referencing deploy instructions and server access details
- SSH target and deploy process documentation

4. **Initialize git:**

   ```bash
   cd ~/projects/<project-name>
   git init
   git add -A
   git commit -m "Initial project scaffold"
   ```

5. **Report what was created** — list all files with brief descriptions.

## What this skill does NOT do:

- Create source code (use the framework's scaffolding: `npx create-next-app`, `swift package init`, etc.)
- Run package managers (`npm install`, `pip install`)
- Create GitHub repos (user requests that separately)
- Set up CI/CD pipelines
