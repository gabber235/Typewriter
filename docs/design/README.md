# Design records

Living records of design decisions, one file per workstream. The vision (`docs/vision/`) says what Typewriter should be; these records say how it will work and in what order it gets built. Worktrees that implement a part read the matching record first.

| Record | Covers |
| --- | --- |
| [event-system.md](event-system.md) | Primitives, formulas, stored data, mirrors, sessions, migrations, and the type glossary |
| [closed-beta-roadmap.md](closed-beta-roadmap.md) | The stacked PR order toward the closed beta, with what each layer needs |

Each record has four sections:

- **Decided**: agreed with a maintainer; build on it.
- **Unreviewed input**: research and agent output not yet reviewed; never treat it as a decision.
- **Draft**: proposals under discussion.
- **Open**: questions that still need an answer.
