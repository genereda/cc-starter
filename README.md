# Claude Code Starter Kit

Curated customizations for productive agentic coding with [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

This repo is both a **clone-and-go starter kit** and a **documented reference**. It gives you a tuned `CLAUDE.md`, sensible plugin settings, and a set of skills (specialized knowledge modules) that make Claude Code significantly more effective out of the box.

---

## Quick Start

```bash
git clone https://github.com/err2x/claude-code-starter-kit.git
cd claude-code-starter-kit
bash install.sh
```

The install script copies files into `~/.claude/`, which is where Claude Code looks for global configuration and skills. It will not overwrite existing files without asking.

After installing, open any project and start a Claude Code session. The new instructions and skills take effect immediately.

---

## What's Inside

The kit has three main pieces:

1. **`claude-md/CLAUDE.md`** -- A global instructions template that shapes how Claude behaves across all sessions: planning before coding, using subagents for delegation, committing in logical chunks, managing context, and more.

2. **`settings/settings.json`** -- Recommended plugin configuration. Enables useful official plugins (Playwright for browser testing, code review, security guidance, frontend design) and sets sensible defaults.

3. **`skills/`** -- Seven specialized knowledge modules Claude can load on demand. Each one makes Claude an expert in a specific domain -- from React performance to web security to generating visual diagrams.

---

## Claude Code Concepts

If you are new to Claude Code, here is a crash course on the key ideas.

### CLAUDE.md

Claude Code reads a file called `CLAUDE.md` to understand how you want it to work. There are two levels:

- **Global** (`~/.claude/CLAUDE.md`) -- Applies to every session, in every project. This is where you put your general workflow preferences: how you like commits structured, when to ask clarifying questions, how to manage context, coding standards, and so on.

- **Project-level** (`your-repo/CLAUDE.md`) -- Lives in the root of a specific repository. Adds context about that codebase: what the project does, how to build and test it, deployment details, conventions. Claude reads both the global and project-level files, so they layer together.

Think of the global file as "how I work" and the project file as "how this project works."

### Skills

A skill is a `SKILL.md` file inside `~/.claude/skills/<name>/`. Each one is a specialized knowledge module that Claude loads **on demand** -- only when the task matches the skill's description. This is called progressive disclosure.

For example, if you ask Claude to review your React component for performance issues, it will automatically load the `vercel-react-best-practices` skill, which contains 45 optimization rules from Vercel Engineering. If you ask it to generate a diagram, it loads `visual-explainer`. You do not need to tell Claude to use a skill -- the description in the SKILL.md frontmatter acts as a trigger.

Skills can include supporting files: reference docs in a `references/` subdirectory, executable scripts in `scripts/`, and output templates in `assets/`. The SKILL.md itself stays lean and points to these resources as needed.

### Subagents

Claude can spawn sub-processes (subagents) to handle tasks while keeping the main conversation context clean. This is critical because Claude has a finite context window, and loading it up with test output, file contents, and intermediate work degrades performance.

The pattern is **delegate, don't accumulate**:

- **Research** -- Spawn a subagent to explore the codebase and summarize findings, rather than reading dozens of files into the main context.
- **Testing** -- A subagent runs tests, interprets failures, and proposes fixes. Only the results come back to the main conversation.
- **Multi-file implementations** -- Plan in the main context, execute the changes in a subagent.
- **Code review** -- After finishing work, a fresh subagent reviews it. New context prevents blind spots from implementation fatigue.

The `CLAUDE.md` template in this kit includes subagent delegation patterns.

### Context Management

Claude has a finite context window. When it fills up, Claude starts losing track of earlier details. The instructions in `CLAUDE.md` help manage this:

- **Scope sessions to one task** -- Do not try to fix three bugs, add a feature, and refactor in the same session.
- **Use `@file` references** -- Point Claude at specific files by path rather than asking it to search the whole codebase.
- **Use `/compact`** -- When the context gets cluttered but you want to continue the conversation, `/compact` summarizes and frees up space.
- **Use `/clear`** -- Starts fresh within the same session when switching to unrelated work.
- **Delegate to subagents** -- Offload heavy lifting so the main context stays clean and focused.

### Plan Mode

For complex tasks, enter plan mode by pressing `Shift+Tab` twice. In plan mode, Claude explores the codebase and designs an approach **before** writing any code. This prevents wasted effort from diving in without understanding the full picture.

The `CLAUDE.md` template enforces this by default: Claude starts every non-trivial task in plan mode and waits for your approval before implementing.

---

## Skills Inventory

| Skill | Purpose | When to Use It |
|-------|---------|----------------|
| **karen** | Validates actual vs. claimed completion. Runs the code, tests edge cases, produces a gap report with severity ratings and a prioritized action plan. | When checking if something is really done. When a task is "complete" but you want proof it actually works end-to-end. |
| **make-skills** | Meta-skill for creating new skills. Covers SKILL.md structure, frontmatter validation, triggering descriptions, progressive disclosure patterns, and anti-patterns to avoid. Includes a validation script and starter templates. | When writing a new SKILL.md or refining an existing one. |
| **test-loop** | Iterative test-fix cycle via subagents. Runner subagent executes tests and diagnoses failures; Fixer subagent implements fixes and re-runs. Loops up to 5 iterations, keeping the main context clean. | When running a test suite and fixing failures iteratively. When debugging flaky tests. |
| **vercel-react-best-practices** | 45 React and Next.js performance optimization rules from Vercel Engineering, organized by impact priority: eliminating waterfalls, bundle size, server-side performance, re-render optimization, and more. | When writing, reviewing, or refactoring React/Next.js code. |
| **vibesec** | Web application security guide from a bug hunter's perspective. Covers access control, XSS, CSRF, SSRF, SQL injection, JWT security, file uploads, path traversal, and more with concrete checklists and bypass techniques to block. | When building web apps, doing security review, or preparing for a pre-merge/pre-release audit. |
| **visual-explainer** | Generates self-contained HTML pages for diagrams, architecture overviews, data tables, flowcharts, and dashboards. Uses Mermaid, Chart.js, and CSS-only approaches depending on the diagram type. Produces polished, themed output. | When you need visual explanations of technical concepts, architecture diagrams, comparison tables, or any structured visualization. |
| **web-design-guidelines** | Reviews UI code against the Vercel Web Interface Guidelines. Fetches the latest rules from the source repo and outputs findings in a terse `file:line` format. | When doing UI/UX audits, checking accessibility, or reviewing frontend code against best practices. |

---

## Customizing

This kit is a starting point, not a finished product. Make it your own:

- **Edit `CLAUDE.md`** to reflect your workflow preferences. Change the commit style, adjust the planning requirements, add your preferred tech stack conventions.
- **Add project-specific sections** for deployment targets, infrastructure details, CI/CD pipelines, or team conventions.
- **Create your own skills** for tools and workflows you use repeatedly. If you find yourself giving Claude the same context over and over, that is a skill waiting to be written.
- **Check `examples/`** for inspiration. The `firewalla-ssh` example shows a skill for managing a specific network device. The `local-test` example shows a skill for a Docker-based testing environment that mirrors a production server. The `sample-project-claude-md.md` file shows what a project-level CLAUDE.md looks like in practice.

---

## Creating New Skills

Skills are the highest-leverage customization. Here is the short version:

### 1. Create the directory and file

```bash
mkdir -p ~/.claude/skills/my-skill
touch ~/.claude/skills/my-skill/SKILL.md
```

### 2. Write the frontmatter

The `description` field is the most important part. Claude uses it to decide when to load the skill. Be specific about what the skill does and include trigger phrases that match how you would naturally ask for help.

```yaml
---
name: my-skill
description: >-
  Do X and Y for Z situations. Use when working on A,
  building B, or when the user asks for C.
---
```

### 3. Write the body

Keep the SKILL.md itself under 500 lines. Include the essential instructions and examples. For detailed reference material, put it in a `references/` subdirectory and link to it from SKILL.md. For scripts that Claude should execute, put them in `scripts/`.

```
my-skill/
├── SKILL.md            # Core instructions (loaded into context)
├── references/         # Detailed docs (loaded on demand)
│   └── api-guide.md
└── scripts/            # Executable tools (run, not loaded)
    └── validate.py
```

### 4. Validate

Use the `make-skills` skill to check your work:

```
/make-skills
```

It will verify name format, description quality, body length, and common anti-patterns.

### Key principles

- **Progressive disclosure** -- Do not front-load everything into SKILL.md. Claude is already intelligent; only document what it does not inherently know.
- **Triggering matters** -- A vague description like "helps with code" will never trigger. Be specific: actions, contexts, file types, and phrases the user might say.
- **Conciseness is survival** -- Every token in SKILL.md competes with your actual work for context window space. Challenge each line: does Claude need this?

---

## Tips for Getting the Most Out of Claude Code

**Start sessions with clear, specific instructions.** "Fix the login bug where users get a 500 error after OAuth redirect" works much better than "fix the login."

**Use plan mode before complex tasks.** Press `Shift+Tab` twice. Let Claude explore the codebase and propose an approach before writing code. Review the plan, ask questions, then approve.

**Let Claude commit in logical chunks.** Do not wait until everything is done and make one giant commit. Ask Claude to commit after each logical piece of work. This gives you clean history and easy rollback points.

**Use `@file` to point Claude at specific files.** Instead of "look at the auth module," try `@src/auth/handler.ts`. Direct file references are faster and use less context than searching.

**Scope sessions to one task or feature.** Claude works best when focused. If you need to switch to something unrelated, use `/clear` to start fresh rather than cramming both tasks into one conversation.

**Use `/compact` when context gets cluttered.** If the conversation is getting long but you want to keep going, `/compact` summarizes the history and frees up context space. Use `/clear` for a full reset.

**Read the terminal output.** Claude shows you what it is doing. If something looks wrong, interrupt early rather than letting it go down the wrong path. You can press `Escape` to stop Claude mid-action.

**Write project-level CLAUDE.md files.** Every repo benefits from a CLAUDE.md that explains what the project is, how to build it, how to test it, and any conventions. This saves you from repeating the same context at the start of every session.

---

## Examples

The `examples/` directory contains real-world references:

- **`firewalla-ssh/`** -- A skill for SSH access to a Firewalla router, including UniFi controller management and MongoDB queries. Shows how to document device-specific workflows.
- **`local-test/`** -- A skill for a Docker Compose testing environment that mirrors a production VPS. Shows how to document infrastructure with verification checklists.
- **`sample-project-claude-md.md`** -- A complete project-level CLAUDE.md for a real codebase. Use it as a template for your own projects.

These are included as learning references, not installed by `install.sh`.

---

## License

MIT. Use it, modify it, share it.
