# Calibration

Keep 10 real Typewriter diffs with seeded or known problems, each labelled by the maintainer with the expected items and whether each is a plan flaw or an execution flaw. A skill change is accepted only if, over the set, it finds at least as many expected findings and raises no more false ones than before. Results live in the project at `xtask/src/review/calibration/results.md`.

Run the set only when this skill or its references change, so it costs nothing per pull request. Each case is an independent review: a fresh agent with the change report, the plan and this skill.

## Acceptance

A skill change must catch every expected item of cases A and B and raise no bug level item on case C. Any correctness item (a bug report that names no plan or model flaw) counts as a false item in every case.

## Case A: PR #542, the agent harness

Review commit `9dd2175bd` against base `bb0f0204a`. Expected plan flaws:

- Legacy workflows still live next to `ci.yml` and `full.yml`: `build-engine`, `build-extension`, `ci-alpha`, `publish-release`, `manual-build-all`, `build-development-jars-and-publish`. One item each, or one item naming all of them. Found through `review siblings .github/workflows/<deleted workflow>.yml` and `review leftovers`.
- `documentation/` and its CI workflows left outside xtask: the new system does not cover the documentation area and the plan names no non-goal. Found through the umbrella question.

## Case B: seeded leftover

Replace one tool with another (for example commitlint with an xtask check), deleting its configuration and package entries, but leave a reference in one workflow YAML and one in AGENTS.md. Expected: one plan flaw per leftover, each citing file:line, found through `review leftovers commitlint`.

## Case C: negative control

A clean replacement: the old tool, its configuration and every reference are gone, and the new one covers the same areas. Expected: zero items. A review that reports correctness findings here fails, since those count as false items.
