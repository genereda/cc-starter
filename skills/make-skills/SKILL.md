---
name: make-skills
description: >-
  Create high-quality Claude Code skills with optimal structure, triggering descriptions, and best practices. Use when writing SKILL.md files, creating new skills, designing skill architecture, or helping with skill development and refinement.
---

# Skill Creation Guide

## Why This Exists

Skills transform Claude from a general-purpose model into a domain expert with procedural knowledge. A well-crafted skill loads only when needed, costs minimal context, and reliably triggers on relevant requests. This guide encodes the patterns that make skills effective.

## Quick Start

```
skill-name/
├── SKILL.md          # Required - instructions Claude follows
├── scripts/          # Optional - executable code (deterministic, reusable)
├── references/       # Optional - documentation loaded contextually
└── assets/           # Optional - output templates, not loaded into context
```

## THE EXACT FRONTMATTER

```yaml
---
name: lowercase-with-hyphens
description: >-
  [What it does - actions, capabilities in third person].
  Use when [trigger phrases, contexts, file types, user intents].
---
```

**Validation:**
- `name`: ≤64 characters, lowercase, hyphens only, no reserved terms
- `description`: ≤1024 characters, third-person active voice, no XML tags

## Writing Effective Descriptions (Critical)

The description is the triggering mechanism. Claude uses it to select from potentially 100+ skills.

### Rules

1. **Third person always:** "Processes Excel files" not "I can help you"
2. **Specific actions + trigger phrases:** What it does AND when to invoke
3. **Discoverable terminology:** Include synonyms users might say

### Strong Examples

> "Analyze Excel spreadsheets, create pivot tables, generate charts. Use when analyzing Excel files, spreadsheets, tabular data, or .xlsx files."

> "Generate descriptive commit messages by analyzing git diffs. Use when user asks for help writing commit messages or reviewing staged changes."

### Weak Examples (Never Do This)

- "Helps with documents" (too vague, never triggers)
- "Processes data" (what data? how?)
- "Does stuff with files" (useless)

## Core Principles

### 1. Conciseness is Survival

Context window is shared. Claude is already intelligent—only document what it doesn't inherently know.

**Bad** (~150 tokens):
> "PDF (Portable Document Format) files are a common file format that contains text, images..."

**Good** (~50 tokens):
> "Use pdfplumber for extraction: `[code example]`"

Challenge each line: Does Claude need this? Does it justify its token cost?

### 2. Progressive Disclosure

Never front-load everything. Structure for on-demand loading.

```markdown
## Quick start
[Essential example - <50 lines]

## Features
- **Feature A**: See [references/A.md](references/A.md)
- **Feature B**: See [references/B.md](references/B.md)
```

**Rules:**
- Keep references ONE level deep from SKILL.md (no chains)
- Include table of contents for files >100 lines
- Target <500 lines in SKILL.md body

### 3. Degrees of Freedom

Match specificity to task fragility:

| Freedom | When | Example |
|---------|------|---------|
| High | Multiple valid approaches | Code review guidelines |
| Medium | Preferred pattern, variation OK | Report templates |
| Low | Consistency critical, error-prone | Database migrations |

## Workflow Patterns

### Checklist Pattern (Multi-Step Tasks)

```markdown
## Processing workflow

- [ ] Step 1: Analyze input
- [ ] Step 2: Transform data
- [ ] Step 3: Validate output
- [ ] Step 4: Write results
```

### Feedback Loop Pattern (Quality-Critical)

```markdown
## Validation loop

1. Make changes
2. **Validate immediately**: `python scripts/validate.py`
3. If validation fails → fix → validate again
4. **Only proceed when validation passes**
```

### Template Pattern (Consistent Output)

```markdown
## Output structure

ALWAYS use this template:

## Section 1
[Content specification]

## Section 2
[Content specification]
```

### Conditional Workflow Pattern

```markdown
## Workflow selection

1. Determine type:
   - **Creating new?** → Follow "Creation workflow"
   - **Modifying existing?** → Follow "Modification workflow"
```

## Bundled Resources

### scripts/ — Executable Code

**When:** Same code repeatedly needed; deterministic reliability required.

```markdown
## In SKILL.md
Run `python scripts/validate.py input.pdf` to validate.
```

Scripts execute without loading into context—token efficient and consistent.

### references/ — Contextual Documentation

**When:** Documentation Claude should reference while working.

```markdown
## Available guides
- **API usage**: See [references/api.md](references/api.md)
- **Error codes**: See [references/errors.md](references/errors.md)

## Quick search
```bash
grep -i "keyword" references/
```
```

### assets/ — Output Templates

Files used in output, not loaded. Claude copies/modifies as needed.

## Anti-Patterns (Avoid)

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Windows paths (`scripts\file.py`) | Breaks on Unix | Forward slashes only |
| Deeply nested references | Claude partial-reads | One level deep |
| Vague descriptions | Never triggers | Specific + trigger phrases |
| Too many options | Confusing | Default + escape hatch |
| Inconsistent terminology | Confuses Claude | Pick one term throughout |
| Time-sensitive info | Becomes wrong | Use collapsed `<details>` |
| Magic numbers | Unverifiable | Document why each value |

**Bad:** "You can use pypdf, or pdfplumber, or PyMuPDF..."

**Good:** "Use pdfplumber for text extraction. For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."

## Validation

Run the validation script to check for common issues:

```bash
python3 scripts/validate_skill.py [path/to/skill]
```

**What it checks:**
- Name format (≤64 chars, lowercase, hyphens only)
- Description length (≤1024 chars) and quality (third-person, trigger phrases)
- Body line count (<500 target)
- Windows paths, nested references, vague patterns

### Manual Checklist

```
□ Scripts: tested, explicit error handling
□ Consistent terminology throughout
□ Examples concrete and copy-paste ready
```

## Development Process

1. **Complete task without skill** — Note what context you repeatedly provide
2. **Identify reusable pattern** — What would help future similar tasks?
3. **Create minimal skill** — Just enough to address gaps
4. **Test with fresh instance** — Does it trigger? Apply rules correctly?
5. **Iterate** — What did it miss? What confused it?

## Naming Conventions

Use gerund form (verb + -ing):

**Good:** `processing-pdfs`, `analyzing-data`, `testing-code`, `managing-config`

**Bad:** `helper`, `utils`, `tools`, `documents`, `my-stuff`

## Optional Frontmatter Fields

| Field | Effect |
|-------|--------|
| `allowed-tools` | Scoped permissions: `Read,Write,Bash(git:*)` |
| `user-invocable: false` | Hide from slash menu |

## MCP Tool References

Always use fully qualified names:

**Good:** "Use the `BigQuery:bigquery_schema` tool"

**Bad:** "Use the bigquery_schema tool"

## Skill Archetypes

Use the templates in `assets/templates/` as starting points:

### CLI Reference Skill
**Template:** [assets/templates/cli-reference.md](assets/templates/cli-reference.md)

For tools with commands, flags, and workflows. Structure: Auth → Core CRUD → Workflows → Errors.

### Methodology Skill
**Template:** [assets/templates/methodology.md](assets/templates/methodology.md)

For processes, principles, and approaches. Structure: Philosophy → Steps → Before/After → Checklist.

### Safety/Security Skill
**Template:** [assets/templates/safety-tool.md](assets/templates/safety-tool.md)

For validation, guardrails, and risk management. Structure: Threat Model → Block/Allow → Risk Tiers → Escalation.

## Example: Complete Minimal Skill

```markdown
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

## Conventional commit types

| Type | Section |
|------|---------|
| feat | Features |
| fix | Bug Fixes |
| docs | Documentation |
| refactor | Code Refactoring |

## Output format

ALWAYS use this structure:

## [Version] - YYYY-MM-DD

### Features
- feat descriptions

### Bug Fixes
- fix descriptions
```
