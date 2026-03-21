# Global Claude Code Instructions

<!-- This is a starter template. Customize each section to match your workflow. -->
<!-- Sections marked with TODO are placeholders for your own content. -->

## Memories, progress, and learnings

- ALWAYS conclude every non-trivial task by logging your progress, as well as any key learnings or decisions, in `CLAUDE.md` or `PRD.md` or `plan.md`

---

## Planning & PRD Requirements

### Default to Plan Mode

- Start EVERY non-trivial task in plan mode (Shift+Tab twice)
- Never begin implementation until the plan is explicitly approved
- Write plans to `plan.md` or `PRD.md` for persistence across sessions

### PRD Generation Protocol

When starting a new project or feature:

1. Use TodoWrite to create a structured PRD before any code
2. Ask clarifying questions using conversational prompts—do NOT assume requirements
3. Minimum PRD sections:
   - Problem Statement & User Need
   - Success Criteria (measurable)
   - Scope: What's IN and OUT
   - Technical Approach (high-level)
   - Edge Cases & Error States
   - Open Questions (flag unknowns explicitly)
4. Get explicit approval on PRD before proceeding
5. Reference PRD throughout implementation; update if scope changes

### Clarifying Questions

- Ask 3-5 targeted questions before complex work
- Prefer specific multiple-choice questions over open-ended ones
- Surface non-obvious assumptions: "I'm assuming X—correct?"
- Never guess at ambiguous requirements—ask first

---

## Subagent Strategy

### Core Principle: Delegate Aggressively

Use subagents to keep the main context window clean and focused. The main agent orchestrates; subagents execute.

### Mandatory Subagent Use Cases

**File Reading & Analysis**

- Use Explore subagent for all codebase research and file discovery
- Summarize findings back to main context—don't load full files into main window
- Specify thoroughness: "quick" for targeted lookups, "thorough" for deep analysis

**Testing**

- Spawn dedicated subagent for test writing and execution
- Subagent runs tests, interprets failures, proposes fixes
- Only surface results and recommendations to main context

**Implementation & Fixes**

- For multi-file changes: plan in main, execute in subagent
- Subagent handles the edit-test-iterate loop
- Return completed diff or summary to main agent

**Code Review & Verification**

- After completing work, spawn verification subagent
- Reviewer subagent checks: correctness, edge cases, style, security
- Fresh context prevents blind spots from implementation fatigue

### Subagent Patterns

- Prefer "Master-Clone" over "Lead-Specialist": spawn general-purpose clones, not rigid specialists
- Chain subagents from main conversation if nested delegation needed
- Use `Ctrl+B` to background long-running subagents while continuing work

---

## Context Management

### Keep Context Lean

- Use `@file` references to inject specific files—don't ask Claude to search
- Scope each session to ONE project/feature
- Use `/compact` when context is cluttered but continuity matters
- Use `/clear` when starting fresh work in same session

### Progressive Disclosure

- Load skill SKILL.md files only when that skill is needed
- Don't front-load all possible context—let it emerge from the task
- Reference files by path; don't paste large code blocks into prompts

### External Memory

- Write working notes to `scratchpad.md` or `notes.md`
- Persist decisions and learnings in project CLAUDE.md
- Use `# <instruction>` to add learnings during session

---

## Quality Standards

### Accuracy Requirements

- Never fabricate tool/API results—if a call fails, say so
- Provide actual error messages, not guessed interpretations
- Acknowledge limitations: "I don't have enough context to determine X"

### Code Quality

- Run linters/formatters via tools—don't manually enforce style
- Verify changes compile/pass tests before declaring done
- Avoid backwards-compatibility code unless explicitly requested
- No unrequested features or over-engineering

### Testing and validation

- Always prefer end-to-end verifiable tests
- Always include testing requirements in project requirements, ensuring you will be able to execute testing autonomously whenever possible
- If it cannot be tested, then it cannot be called complete
- **Browser testing** uses two tools — pick based on context:
  - **Playwright** (default) — headless, no GUI prompts, fully autonomous. Use for all self-testing of code you just wrote.
  - **chrome-cdp** (fallback) — connects to the user's live Chrome session (real cookies, logged-in state). Use when user asks to inspect their browser, or as fallback when Playwright can't access a resource (auth-walled pages, content that won't render headless).
- For desktop and mobile apps, find ways to run and capture screenshots (even if this means a test script for the user)

### Verification Pattern

1. Implement the change
2. Run relevant tests
3. If tests fail, iterate (in subagent if complex)
4. Run linter/formatter
5. Self-review or spawn review subagent
6. Only report completion if tests fully pass

---

## Workflow Patterns

### Git Discipline

- Ensure a git repo is initialized for every project and check status when getting oriented in a new session
- Create feature branches for all non-trivial work
- Commit messages: single line, imperative mood, no emojis
- Commit logical chunks—not giant diffs
- Push and create PR when work is complete
- When merging, always squash and merge, and delete the obsolete branch after a successful merge

### Model Selection

- Use Sonnet for routine execution tasks—it's faster and sufficient
- Escalate to Opus for: complex bugs, architectural decisions, ambiguous requirements
- `/model opus-plan` for planning in Opus, executing in Sonnet

### Extended Thinking

- Use "ultrathink" keyword for problems requiring deep reasoning
- Request extended thinking for: debugging mysteries, architectural trade-offs, security review

---

## Behavioral Rules

### Communication Style

- Be direct—skip preamble and filler
- Ask clarifying questions early, not after failed attempts
- Report blockers immediately, don't spin

### What NOT To Do

- Don't search for files when you can use `@path/to/file`
- Don't load entire codebases into context—use Explore subagent
- Don't implement before planning is approved
- Don't guess at requirements—ask
- Don't skip tests to save time

---

## Deployment & Infrastructure

<!-- TODO: Add your deployment details here. Example sections: -->
<!-- - Server access (SSH, IPs, keys) -->
<!-- - Stack details (OS, runtime, web server) -->
<!-- - Deploy process (CI/CD, manual steps) -->
<!-- - SSL/DNS configuration -->

---

## Directory Structure Reference

<!-- Add your own skills to this list as you create them -->

```
~/.claude/
├── CLAUDE.md              # This file (global instructions)
├── settings.json          # Permissions, hooks, and tool config
├── settings.local.json    # Local/machine-specific settings
├── hooks/                 # Hook scripts (run on tool events)
│   ├── protect-sensitive.sh
│   ├── auto-format.sh
│   └── bash-audit.sh
├── skills/                # Custom skills (SKILL.md per skill)
│   ├── my-skill-one/
│   ├── my-skill-two/
│   └── my-skill-three/
├── memory/                # Auto-memory (persistent across sessions)
├── projects/              # Per-project session data and logs
├── cache/                 # Changelog and other cached data
├── backups/               # Config backups
└── debug/                 # Debug logs
```

---

## Skills

<!-- List your installed skills here for quick reference -->

When available, read SKILL.md before starting specialized tasks:

- Document creation (docx, pdf, pptx)
- Frontend design
- Data analysis

Skills use progressive disclosure—load only when the task matches the skill description.
