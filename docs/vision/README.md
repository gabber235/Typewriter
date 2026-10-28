# Typewriter product vision

A living map of what Typewriter is, who it serves, why it exists, and where it is going, from the first milestone to things we want someday. It records product intent, not designs or implementation. Design documents (for example `docs/event-system/`) should check their assumptions against this map.

## What Typewriter is

Typewriter lets people build **personalized, flexible, composable interactions** inside a Minecraft server. Quests are one kind of interaction; Typewriter is not limited to them.

Historically it was described as a "player interaction plugin". The scope may grow beyond that. Content is made through **visual configuration**: not visual scripting, but configuring entries, pages, and books in a visual editor (the panel).

## Who it is for

| Audience | Role |
| --- | --- |
| Server owner | Runs Typewriter on their own hardware |
| Extension developer | Adds new functionality through extensions |
| Content creator (admins, helpers) | Builds interactions in the panel |
| Protagonist | A player who plays the content (Typewriter's name for players) |

See [audiences.md](audiences.md).

## Why it exists

The core problem it solves: interactions that are **highly personalized, super flexible, and composable**.

## Milestones

A milestone is a bundle of features.

| Milestone | Meaning |
| --- | --- |
| Closed beta | First milestone. The bare minimum that lets people start using Typewriter |
| Later milestones | Further bundles of features, not yet ordered |
| Someday | Wanted, with no milestone yet |

## Legends

**Horizon** (when it is wanted):

| Mark | Meaning |
| --- | --- |
| closed beta | Part of the first milestone |
| closed beta (not at the start) | During the closed beta, after its start |
| later | A later milestone |
| someday | Wanted, with no milestone yet |

A trailing `?` on a horizon means it is not confirmed yet.

**Maturity** (how settled the intent is, not how far implementation is):

| Mark | Meaning |
| --- | --- |
| settled | We know exactly how it should work |
| shaped | The main idea and key behaviour are clear; details open |
| sketch | A rough direction |
| wish | We want it; no shape yet |
| open | Not decided yet |

## Glossary

| Term | Meaning |
| --- | --- |
| Typewriter Cloud | What the Typewriter team hosts: backend, web panel |
| Realm | Runs on the server owner's hardware; owns content, state, and the gateway to engines |
| Engine | Executes published content in a concrete runtime (Paper, the panel) |
| Host | A process that runs a realm, engines, or both |
| Capability | A complete set of behaviour an engine implements and extensions target. Only core defines capabilities |
| Extension | Code that extends Typewriter, running on the realm, the engine, or both. Its source parts target common code, capabilities, or a specific engine |
| Imprint | The build tooling that packages extensions |
| Entry | The basic unit of content |
| Page, chapter, book, tag | Organizational units of content |
| Publication | Turning authored content into what engines run |
| Stored value | Data the realm stores for one or more identities. Its **blueprint** comes only from an extension; **instances** come from creators or extension code. Read as `entry.value(identity)`, for example `dragon_quest.stage(group)` |
| Entry variable | A stored value tied to an entry. Stored data can also be global or on other identities, through extension code |
| Context | Everything a formula can use: the player, the book, `minecraft`, and more. Not one single type |
| Field types | `Var<T, CONTEXT>` (a value or a formula) and `Formula` (always a formula, with a declared signature) |
| Identity | Anything clearly identifiable that data can belong to (protagonist, group, NPC, book instance) |
| Protagonist | A player |
| Development realm | A realm for building and trying content; full editing and history |
| Production realm | A realm that runs compiled revisions of content; no editing, easy rollback |
| Configuration | A typed, overridable set of settings that replaces legacy snippets |
| Perk | Something published on the marketplace (an extension or a book) |

## Areas

Horizon and maturity list every mark used in the area file, earliest and most settled first. A horizon with `?` counts under its base horizon; `?` alone means not placed yet.

| Area | Summary | Horizon | Maturity |
| --- | --- | --- | --- |
| [Audiences](audiences.md) | Who uses Typewriter and how | closed beta, later | shaped, sketch |
| [Topology](topology.md) | Cloud, realm, engine, host | closed beta, later, someday | settled, shaped, sketch, wish |
| [Realm modes](realm-modes.md) | Development and production realms, revisions, rollback | closed beta | settled, shaped |
| [Engines](engines.md) | Capabilities, Paper engine, panel engine | closed beta, later, someday | shaped, sketch, wish |
| [Extensions](extensions.md) | Source parts, realm and engine code, validators, assets | closed beta, later | shaped, sketch |
| [Content model](content-model.md) | Entries, pages, books, instances, edges | closed beta, later | settled, shaped, sketch |
| [Interactions](interactions.md) | Scope, starts, Minecraft rules, priority, clashes | closed beta, later | shaped, sketch |
| [Configurations](configurations.md) | Typed, overridable settings that replace snippets | closed beta | shaped |
| [Data storage](data-storage.md) | Transactional state that replaces facts; identities | closed beta | settled, shaped |
| [Expressions](expressions.md) | Formula language that replaces variables and criteria | closed beta, someday, ? | settled, shaped, sketch, wish, open |
| [Publication](publication.md) | Live publishing, incremental compilation, hot reload | closed beta | settled, shaped, open |
| [Panel](panel.md) | Web, desktop, and mobile editor | closed beta, later, someday | shaped, sketch, wish |
| [Marketplace](marketplace.md) | Perks, sealed books, review, signing | later | shaped, sketch |
| [Resource packs](resource-packs.md) | Assets in books, stacked packs, serving, GUIs | later | shaped, sketch, open, wish |
| [AI](ai.md) | Voice, generation, assistants | later | wish |
| [Pricing](pricing.md) | Free core, one time add ons, credits | closed beta, later, someday, ? | settled, shaped, sketch, wish, open |
| [Distribution](distribution.md) | Automatic updates, publisher rollouts, feature flags | later | shaped, sketch, wish |

## How to update this map

- Each area file uses the same sections: what it is, who it serves, why, horizon and maturity, open questions.
- Record intent as stated by the product owner. Mark guesses as open questions instead of writing them as vision.
- When an area matures, update its maturity marks here and in the area file.
- **What belongs in the closed beta:** fundamental pieces that would be painful to add later, or trivially easy to include in the initial design. Everything else can wait.
- Detail follows the horizon. Anything in or during the closed beta should be described in high detail. Later and someday items only need enough to show direction.
