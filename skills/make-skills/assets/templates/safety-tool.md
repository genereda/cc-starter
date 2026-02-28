---
name: validating-DOMAIN
description: >-
  Validate [operations/requests] for [safety/security/compliance] concerns.
  Use when [trigger phrases], before executing [risky operations],
  or reviewing [artifacts] for [risk type].
---

# DOMAIN Safety

## Why This Exists

[2-3 sentences on the threat model. What bad outcomes does this prevent? Who/what is protected?]

## What It Blocks

| Pattern | Risk | Example |
|---------|------|---------|
| [Dangerous pattern] | [Consequence] | `[concrete example]` |
| [Dangerous pattern] | [Consequence] | `[concrete example]` |
| [Dangerous pattern] | [Consequence] | `[concrete example]` |

## What It Allows

| Pattern | Why Safe | Example |
|---------|----------|---------|
| [Safe pattern] | [Reasoning] | `[concrete example]` |
| [Safe pattern] | [Reasoning] | `[concrete example]` |
| [Safe pattern] | [Reasoning] | `[concrete example]` |

## Risk Tiers

| Tier | Description | Required Approval | Examples |
|------|-------------|-------------------|----------|
| **Critical** | [Impact description] | [Who must approve] | [Examples] |
| **High** | [Impact description] | [Who must approve] | [Examples] |
| **Medium** | [Impact description] | [Who must approve] | [Examples] |
| **Low** | [Impact description] | [Who must approve] | [Examples] |

## Validation Workflow

1. **Classify** — Determine risk tier based on:
   - [ ] [Classification criterion]
   - [ ] [Classification criterion]
   - [ ] [Classification criterion]

2. **Verify** — For medium+ risk:
   - [ ] [Verification step]
   - [ ] [Verification step]

3. **Approve** — Obtain required sign-off per tier

4. **Execute** — Proceed only after validation passes

## Escalation Triggers

**STOP and escalate if:**

- [Condition that requires human review]
- [Condition that requires human review]
- [Condition that requires human review]

## Safe Defaults

When uncertain, apply these defaults:

| Uncertainty | Default Behavior |
|-------------|------------------|
| [Ambiguous situation] | [Conservative action] |
| [Ambiguous situation] | [Conservative action] |
| [Ambiguous situation] | [Conservative action] |

## Audit Trail

For operations at Medium tier or above, record:

```
Operation: [what was requested]
Risk Tier: [classification]
Validation: [checks performed]
Approver: [who approved, if required]
Timestamp: [when executed]
```
