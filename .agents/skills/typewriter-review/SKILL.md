---
name: typewriter-review
description: Review a Typewriter change for plan flaws and execution flaws with the xtask review tools. Use in the review phase of planned work, when asked to check a change, or as a fresh independent reviewer.
---

# Typewriter Review

This review does not check compliance with the plan. It asks where the change shows the plan was incomplete or wrong, and where a sound plan was executed poorly. Read code through the tools below and the facts they precompute; never build a second implementation.

## Two uses

- Finishing your own change: investigate with the tools below, compare what you find with what you built and with the plan, and bring every mismatch to Gabber as "we did X, but Y is the case" with a proposed next step. Do not report done while a mismatch is unanswered.
- Independent review: a fresh agent with only the change report (`cargo xtask review report`), the plan and this skill. Never the author's summary, the conversation, or a previous review.

## Questions to investigate

1. Work the plan never described: `review changes`. Usually good; the plan should say why it was needed.
2. Old concept still alive: `review callers <file> <old symbol>`. Callers left at head mean the change stopped half way.
3. New system on an old one: `review forwards`, `review similar`. A new surface that forwards to the old model.
4. Code the change worked around: `review neighbours`, `review history`. Frequent fixes mean the plan should have refactored it.
5. Tests that prove nothing: `review impact`, `review run`. Would the test still pass if the feature missed its goal?

## Independent review budget

Risk low and no findings: no review; say so. Otherwise one pass over flagged hunks and their neighbours, plus one correctness pass over the three riskiest changed entities by the report's ranking, flagged or not. Risk high adds one pass that tries to disprove each item.

## Classify every item

- Plan flaw: the plan's model forced or invited it (kept an old concept, stopped at a symptom, missed a caller, did not refactor a neighbour the change had to work around). Answer with the plan iteration that removes it.
- Execution flaw: the plan was sound and the code does not follow its model, or follows it badly. Answer with the fix.

A patch smell ([patch-smells.md](references/patch-smells.md)) is an item unless the change itself justifies it; no proof of harm needed. Every item cites file:line. "Looks good" without the hunks checked is not a review.

## Typewriter rules

- Apply AGENTS.md. A rule that can be checked mechanically belongs in an ast-grep rule or a lint, not here.
- A new transport subject updates transport-routes.yaml; grants are never written by hand.
- Tests state a requirement and observe its outcome where the user experiences it: the real panel, a real Minecraft client. Packet logs and output layers are not evidence.

## Tools

Every tool compares the working tree with `--base <ref>` (default `origin/HEAD`; pass the pull request's base branch for stacked work) and prints JSON with `--json`.

- `cargo xtask review report`: the change report; `review deep` adds diff coverage and mutation testing.
- `cargo xtask review changes`: entities added, removed and changed, per file.
- `cargo xtask review callers|similar|forwards|neighbours|history|hunk|impact <file> <symbol>`: one entity; `<symbol>` is its name or qualified name.
- `cargo xtask review run <test>`: runs one test by name or qualified name.
- `cargo xtask review verdict <file>`: publishes the verdict in `<file>` for the pushed head commit.

## Changing this skill

Run the calibration set in [calibration.md](references/calibration.md) before accepting any change to this skill or its references.
