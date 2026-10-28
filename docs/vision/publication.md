# Publication

## What it is

The step that turns authored content into what engines run. It is also where compile time work happens, such as duplicating book instances and wiring edges between books (see [content-model.md](content-model.md)).

### Roughly live

On a development realm, edits publish **automatically after a short debounce** (about 5 seconds). A **publish now** action skips the wait. Publishing may take a moment. This differs from today's behaviour, which must change.

**Incremental compilation** is needed: only what changed since the last publication is rebuilt. This also matters later for resource packs, which should only regenerate the parts that changed.

### Hot reload of running interactions

| Kind of update | What running interactions do |
| --- | --- |
| **Pure content update** (no extension or engine code changed) | Switch to the new version **immediately**, if their entry still exists. If the entry was removed, the interaction **stops immediately** |
| **Extensions or engines changed** (new code deployed) | Full reload. Nothing resumes; protagonists start again |

Example: a creator standing in a dialogue edits a line, publishes, and sees the new text right away.

### Errors block publication

If any content has errors (a formula type error, a validator finding such as a missing reference), **nothing is published** until they are fixed.

### Content per engine

Each engine receives only the content its capabilities support, decided **per book**. A book cannot mix engines: a book of Minecraft entries goes to the Paper engine, not to the panel engine. A book that several engines support runs on all of them (see [engines.md](engines.md)).

### Current state

Parts exist and are probably fine. The stored form is not finalized: it is not well typed (strings joined together) and has not been tried in practice.

## Who it serves

Content creators (their edits reach engines), engines (receive ready configuration).

## Why

Engines should run resolved, validated configuration, not interpret authoring structure.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Content to engine configuration | closed beta | shaped (partly built) |
| Typed stored form | closed beta? | open |
| Book instance expansion and edge wiring | closed beta | shaped |
| References stay correct across duplicated entry identities | closed beta | shaped |
| Roughly live publishing with debounce and publish now | closed beta | shaped |
| Incremental compilation | closed beta | shaped |
| Hot swap of running interactions on pure content updates | closed beta | shaped |
| Errors block publication | closed beta | settled |
| Content routed to engines per book by capability | closed beta | shaped |

## Open questions

- None for development realms. Revisions and rollback for live servers are covered by [realm modes](realm-modes.md).
