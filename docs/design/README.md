# Design records

Living records of design decisions, one file per workstream. The vision (`docs/vision/`) says what Typewriter should be; these records say how it will work and in what order it gets built. Worktrees that implement a part read the matching record first.

Read `overview.md` first; it introduces the seven primitives and links to the rest.

| File | Covers |
| --- | --- |
| [overview.md](overview.md) | The seven primitives on one page and how they fit together |
| [events-and-handlers.md](events-and-handlers.md) | Events, sources, demand, handlers, verdicts, threads, chains, commands |
| [stored-data.md](stored-data.md) | Identities, stored values, changes, transactions, Variables, reactions, Due |
| [live-data.md](live-data.md) | Mirrors, audiences, objectives, sessions, routing, multi server behavior, checks |
| [interactions.md](interactions.md) | Holds, Runtime, interactions and steps, groups, scenes, NPC scope, preview |
| [formula-language.md](formula-language.md) | Formulas, `Var<T, C>`, `dynamic()`, contexts, definitions, books, type checking |
| [migrations.md](migrations.md) | Migration hook, pending migrations, the developer migrator, the 0.9 importer |
| [minecraft-types.md](minecraft-types.md) | Minecraft value types: space (world, vectors, rotation, locations, positions) and items |
| [engines.md](engines.md) | Bridges between Typewriter values and engine types; engine requests |
| [glossary.md](glossary.md) | Every type and term, one line each |
| [closed-beta-roadmap.md](closed-beta-roadmap.md) | The stacked PR order toward the closed beta, with what each layer needs |

The topic files describe the current design only. Each ends with its own Open list. The roadmap keeps the record format below.

The roadmap has four sections:

- **Decided**: agreed with a maintainer; build on it.
- **Unreviewed input**: research and agent output not yet reviewed; never treat it as a decision.
- **Draft**: proposals under discussion.
- **Open**: questions that still need an answer.
