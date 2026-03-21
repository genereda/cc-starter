# Workflow Patterns for Skills

Use these patterns when structuring multi-step or quality-critical skill workflows.

## Checklist Pattern (Multi-Step Tasks)

```markdown
## Processing workflow

- [ ] Step 1: Analyze input
- [ ] Step 2: Transform data
- [ ] Step 3: Validate output
- [ ] Step 4: Write results
```

## Feedback Loop Pattern (Quality-Critical)

```markdown
## Validation loop

1. Make changes
2. **Validate immediately**: `python scripts/validate.py`
3. If validation fails → fix → validate again
4. **Only proceed when validation passes**
```

## Template Pattern (Consistent Output)

```markdown
## Output structure

ALWAYS use this template:

## Section 1

[Content specification]

## Section 2

[Content specification]
```

## Conditional Workflow Pattern

```markdown
## Workflow selection

1. Determine type:
   - **Creating new?** → Follow "Creation workflow"
   - **Modifying existing?** → Follow "Modification workflow"
```
