---
name: interview
description: >-
  Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree.
  Use when stress-testing a plan, clarifying scope, finding hidden requirements or assumptions, uncovering edge cases, or when the user says "grill me" or "interview me".
---

# Interview

Interview the user about every aspect of their plan or design until reaching shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one by one.

Use `ask_user` for one focused question at a time.

Surface non-obvious concerns: hidden dependencies, edge cases, rollout constraints, ownership gaps, and failure modes.

If the codebase or provided context can answer a question, explore it first instead of asking.

For each question, provide your recommended answer so the user can quickly confirm or correct.

Stop when the significant unknowns are resolved, then summarize decisions, assumptions, and remaining open risks.
