---
name: make-skills
description: >-
  Create high-quality Claude Code skills with optimal structure, triggering
  descriptions, and best practices. Use when writing SKILL.md files, creating
  new skills, designing skill architecture, helping with skill development and
  refinement, or optimizing an existing skill's description for better
  triggering accuracy.
---

# Skill Creation Guide

## Skill Structure

```
skill-name/
├── SKILL.md          # Required - instructions Claude follows
├── scripts/          # Optional - executable code (runs without loading into context)
├── references/       # Optional - documentation loaded contextually
└── assets/           # Optional - output templates, not loaded into context
```

Three-level loading: (1) name + description are always in context (~100 words), (2) SKILL.md body loads when triggered (<500 lines ideal), (3) bundled resources load on demand (unlimited). Design for this hierarchy.

## Step 1: Capture Intent

Before writing anything, understand what the skill needs to do. Ask the user:

1. What should this skill enable Claude to do?
2. When should it trigger? (phrases, contexts, file types)
3. What's the expected output format?
4. Are test cases appropriate? (yes for verifiable outputs like file transforms, code generation; no for subjective outputs like writing style)

Proactively ask about edge cases, input/output formats, and success criteria. Don't assume — ask.

## Step 2: Write the SKILL.md

### Frontmatter

```yaml
---
name: lowercase-with-hyphens
description: >-
  [What it does - actions, capabilities in third person].
  Use when [trigger phrases, contexts, file types, user intents].
---
```

- `name`: ≤64 chars, lowercase, hyphens only, gerund form preferred (e.g., `processing-pdfs`, `analyzing-data`)
- `description`: ≤1024 chars, third-person active voice, no XML tags

### Writing Effective Descriptions (Critical)

The description is the triggering mechanism. Claude selects from potentially 100+ skills based on it.

1. **Third person always:** "Processes Excel files" not "I can help you"
2. **Specific actions + trigger phrases:** What it does AND when to invoke
3. **Discoverable terminology:** Include synonyms users might say
4. **Be pushy about triggering.** Claude tends to undertrigger — it won't invoke a skill unless the description clearly matches. Err on the side of listing more trigger contexts, even tangential ones. Example: instead of "Build dashboards for internal data", write "Build dashboards for internal data. Use when the user mentions dashboards, data visualization, internal metrics, charts, or wants to display any kind of data, even if they don't explicitly ask for a 'dashboard.'"

**Strong examples:**

> "Analyze Excel spreadsheets, create pivot tables, generate charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files."

> "Generate descriptive commit messages by analyzing git diffs. Use when user asks for help writing commit messages or reviewing staged changes."

### Writing the Body

**Conciseness is survival.** Every line of a skill loads into context on every invocation — this is a recurring cost. For each line ask: "Does Claude already know this?" If yes, cut it. A 200-line skill that triggers 1000 times costs 200K lines of context. A 150-line skill that's equally effective saves 50K.

**Explain the why, not just the what.** Modern models respond better to reasoning than rigid rules. If you find yourself writing ALWAYS or NEVER in all caps, reframe: explain _why_ the thing matters so the model can generalize to edge cases. Theory of mind beats rote instructions.

**Match specificity to fragility.** Be prescriptive for error-prone or consistency-critical steps. Be flexible for creative or multi-approach tasks.

**Use progressive disclosure.** Keep SKILL.md under 500 lines. Move detailed docs to `references/` with clear pointers. Keep references one level deep (no chains). Include a table of contents for reference files >100 lines.

**Workflow patterns:** For multi-step, quality-critical, template-based, or conditional workflows, see [references/workflow-patterns.md](references/workflow-patterns.md).

**Always use fully qualified MCP tool names** (e.g., `BigQuery:bigquery_schema`, not just `bigquery_schema`).

## Step 3: Test and Iterate

After drafting, create 2-3 realistic test prompts — things a real user would actually say. Run them against the skill:

1. **Does it trigger?** If not, the description needs more/better trigger phrases
2. **Does it produce the right output?** If not, refine instructions
3. **Does it waste effort?** Read the transcript, not just the output — if the skill makes the model do unproductive work, cut those instructions

**Bundled script detection:** If test runs independently produce similar helper scripts, that's a signal to bundle the script into `scripts/` so every future invocation doesn't reinvent it.

Iterate until the skill reliably triggers and produces good output. Then expand the test set for confidence.

## Step 4: Token-Cost Review

Before finalizing, do a conciseness pass on the generated skill:

- Cut lines that teach Claude things it already knows
- Cut examples that illustrate obvious points
- Merge sections that repeat similar information
- Move rarely-needed detail to `references/`
- Verify the skill body is under 500 lines

This step is especially important because it compounds — every token saved here is saved on every future invocation.

## Anti-Patterns

| Anti-Pattern                      | Problem              | Solution                   |
| --------------------------------- | -------------------- | -------------------------- |
| Windows paths (`scripts\file.py`) | Breaks on Unix       | Forward slashes only       |
| Deeply nested references          | Claude partial-reads | One level deep             |
| Vague descriptions                | Never triggers       | Specific + trigger phrases |
| Too many options                  | Confusing            | Default + escape hatch     |
| Inconsistent terminology          | Confuses Claude      | Pick one term throughout   |
| Time-sensitive info               | Becomes wrong        | Use collapsed `<details>`  |
| Magic numbers                     | Unverifiable         | Document why each value    |

**Bad:** "You can use pypdf, or pdfplumber, or PyMuPDF..."
**Good:** "Use pdfplumber for text extraction. For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."

## Validation

```bash
python3 scripts/validate_skill.py [path/to/skill]
```

Checks: name format, description length/quality, body line count, Windows paths, nested references, vague patterns.

## Optional Frontmatter Fields

| Field                   | Effect                                       |
| ----------------------- | -------------------------------------------- |
| `allowed-tools`         | Scoped permissions: `Read,Write,Bash(git:*)` |
| `user-invocable: false` | Hide from slash menu                         |

## Skill Archetypes

Use the templates in `assets/templates/` as starting points:

- **CLI Reference** — [assets/templates/cli-reference.md](assets/templates/cli-reference.md): Commands, flags, workflows. Structure: Auth → Core CRUD → Workflows → Errors.
- **Methodology** — [assets/templates/methodology.md](assets/templates/methodology.md): Processes, principles. Structure: Philosophy → Steps → Before/After → Checklist.
- **Safety/Security** — [assets/templates/safety-tool.md](assets/templates/safety-tool.md): Validation, guardrails. Structure: Threat Model → Block/Allow → Risk Tiers → Escalation.

## Example: Complete Minimal Skill

````markdown
---
name: generating-changelogs
description: >-
  Generate changelogs from git history using conventional commits.
  Use when creating changelogs, release notes, or summarizing changes
  between versions.
---

# Changelog Generation

## Quick start

```bash
git log --oneline v1.0.0..HEAD --format="- %s"
```
````

## Conventional commit types

| Type     | Section          |
| -------- | ---------------- |
| feat     | Features         |
| fix      | Bug Fixes        |
| docs     | Documentation    |
| refactor | Code Refactoring |

## Output format

ALWAYS use this structure:

## [Version] - YYYY-MM-DD

### Features

- feat descriptions

### Bug Fixes

- fix descriptions

```

```
