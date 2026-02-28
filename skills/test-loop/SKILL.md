---
name: test-loop
description: >-
  Iterative test-fix cycle using subagents to minimize main context impact.
  Use when running tests, fixing failures, debugging flaky tests, or
  iterating on test failures until they pass.
---

# Test Loop

Run tests, diagnose failures, implement fixes, and verify—all via subagents to keep main context clean.

## Core Pattern

```
┌─────────────────────────────────────────────────────────┐
│  MAIN AGENT (orchestrator)                              │
│  - Drives test plan based on current work scope         │
│  - Reads progress log for status                        │
│  - Decides lesson-learned scope                         │
│  - Escalates after max iterations                       │
└─────────────────────────────────────────────────────────┘
         │                              ▲
         ▼                              │
┌─────────────────┐            ┌─────────────────┐
│  RUNNER AGENT   │───────────▶│  FIXER AGENT    │
│  - Runs tests   │  failure   │  - Implements   │
│  - Diagnoses    │  report    │    fix attempt  │
│  - Documents    │            │  - Re-runs test │
└─────────────────┘            └─────────────────┘
         ▲                              │
         │         verify               │
         └──────────────────────────────┘
```

## Workflow

### 1. Initialize progress log

Create or append to `scratchpad.md`:

```markdown
## Test Loop Session - [timestamp]
**Scope:** [what's being tested]
**Framework:** [detected or specified]
**Max iterations:** 5
```

### 2. Spawn Runner subagent

```
Task: Run tests and diagnose failures

CRITICAL: You MUST use the Bash tool to execute commands.
- Include the actual command output in your report (first/last 20 lines minimum)
- Never summarize results without showing raw output
- If a command fails, show the actual error message verbatim
- If you cannot run the command, say so explicitly—do not fabricate results

1. Execute: [test command for current framework]
2. If all pass → report success with raw output proof, exit
3. For each failure:
   - Extract test name, file, line
   - Capture relevant stack trace (truncate to key frames)
   - Identify failure category (assertion, type error, runtime, timeout)
   - Note if failure appears flaky (inconsistent across runs)
4. Write findings to scratchpad.md in this format:

### Iteration [N] - Runner Report
**Command executed:** [exact command]
**Exit code:** [0, 1, etc.]
**Raw output (proof of execution):**
```
[first/last 20 lines of actual command output - REQUIRED]
```
**Status:** [N] failures detected
**Failures:**
- `test_name` in `file:line` - [category]: [one-line summary]
  ```
  [key error snippet, 5-10 lines max]
  ```
**Flakiness noted:** [yes/no, pattern if yes]
```

### 3. Spawn Fixer subagent

Pass the Runner's failure report (from scratchpad.md, not raw output).

```
Task: Fix the identified test failure(s)

Context: [failure report from scratchpad.md]
Prior attempts: [summary of previous fix attempts if any]

1. Read the failing test and relevant source code
2. Identify root cause
3. Implement minimal fix (avoid over-engineering)
4. Run the specific failing test to verify
5. If fixed → report success
6. If still failing → document what was tried and why it didn't work

Write to scratchpad.md:

### Iteration [N] - Fixer Report
**Approach:** [what fix was attempted]
**Files modified:** [list]
**Result:** [pass/fail]
**If failed:** [why the approach didn't work]
```

### 4. Evaluate and iterate

After Fixer completes:

- **Pass:** Proceed to lesson extraction
- **Fail + iterations remaining:** Loop back to step 3 with accumulated context
- **Fail + max iterations reached:** Escalate to user with full progress log

On retry, Fixer gets:
- Original failure report (unchanged)
- Summary of all prior fix attempts and why they failed
- Instruction to try a different approach

### 5. Extract lessons learned

When fixed (or when user resolves manually), main agent determines scope:

| Scope | Where | When |
|-------|-------|------|
| File-local | Inline comment near fix | Edge case specific to this code |
| Project-wide | Project CLAUDE.md | Pattern likely to recur across codebase |
| Cross-project | `~/.claude/skills/test-loop/test-fixes.md` | Framework gotcha or general testing pattern |

## Guardrails

### Context minimization
- Subagents receive only what they need: failure reports, not full test output
- Raw stack traces stay in subagent context; only key snippets reach scratchpad
- Main agent reads scratchpad summaries, not subagent transcripts

### Flaky test handling
- Runner retries suspected flakes 2x before reporting
- Log flakiness pattern in scratchpad
- Treat as real failure for fix attempts (flakes often mask real issues)

### Abort conditions
Keep iterating until max (5) reached. No early abort on failure type—let the fixer try.

### Subagent result verification (CRITICAL)

**Subagents can fabricate results.** Always verify.

After Runner or Fixer reports **success**, main agent MUST run a quick verification:
```bash
[test command] 2>&1 | head -30
```

**Red flags indicating fabricated results:**
- Detailed success reports with no raw command output
- Claims of "all tests pass" without showing test runner output
- Specific version numbers, file sizes, or paths without command evidence
- Report claims environment was set up but no setup commands shown

**If verification fails:** Discard the subagent report entirely and either:
1. Re-run the subagent with stricter instructions, or
2. Run the tests directly from main agent context

**Trust but verify:** Fabricated results waste more time than re-running tests.

### What stays in subagent vs. progress log

| Subagent only | Progress log |
|---------------|--------------|
| Full stack traces | Key error snippets (5-10 lines) |
| All test output | Pass/fail counts |
| File contents read | Files modified list |
| Internal reasoning | Approach summary + result |

## Invocation examples

```
/test-loop                    # Run full suite, iterate on failures
/test-loop tests/auth/        # Scope to specific directory
/test-loop --max-iter 3       # Override iteration limit
```

## Progress log template

```markdown
## Test Loop Session - 2024-01-15 14:32

**Scope:** tests/
**Framework:** pytest
**Max iterations:** 5

---

### Iteration 1 - Runner Report
**Command executed:** `pytest tests/ -v`
**Exit code:** 1
**Raw output (proof of execution):**
```
============================= test session starts ==============================
platform linux -- Python 3.11.0, pytest-7.4.0
collected 47 items
tests/auth/test_login.py::test_login_redirect FAILED
tests/auth/test_tokens.py::test_token_expiry FAILED
...
============================= 2 failed, 45 passed ==============================
```
**Status:** 2 failures detected
**Failures:**
- `test_login_redirect` in `tests/auth/test_login.py:45` - assertion: expected 302, got 200
  ```
  AssertionError: assert 200 == 302
  ```
- `test_token_expiry` in `tests/auth/test_tokens.py:78` - runtime: KeyError
  ```
  KeyError: 'exp'
  ```
**Flakiness noted:** no

### Iteration 1 - Fixer Report
**Approach:** Added missing redirect in login handler
**Files modified:** src/auth/handlers.py
**Result:** test_login_redirect passes; test_token_expiry still fails

### Iteration 2 - Fixer Report
**Approach:** Added 'exp' claim to token generation
**Files modified:** src/auth/tokens.py
**Result:** pass

---

## Lessons Learned
- Token generation must include 'exp' claim for JWT validation (added to project CLAUDE.md)
```
