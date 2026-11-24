# Collaboration

> **Status: decided** (2026-11-24). Every name marked *(proposed)* does not exist yet; every other name refers to existing code. Later direction (stored push alignment, presence, backend projections, catalog as a table) is adopted as direction only; each gets a short design check before it is built.

How many authors, tools and engines work on one realm at the same time: what each of them saw, how the realm decides whether a write, an operation or a publish still holds, and how every reader stays current. Related: [authoring-writes.md](authoring-writes.md) (the edit contract and the SDK), [panel-engine-communication.md](panel-engine-communication.md) (engine actions, the tab watch), [formula-language.md](formula-language.md#query-graph) (the realm graph), [live-data.md](live-data.md#lost-pushes) (lost pushes), [stored-data.md](stored-data.md#transactions).

## Problem

"Is what this reader saw still there" was answered by five separate mechanisms, each with its own identity and wire shape:

| Question | Mechanism today |
| --- | --- |
| Does an edit still apply? | `EditExpectation` guards carrying full expected values |
| Are these findings still true? | `CheckEvidence` judged per reply (`FindingFreshness.kt`) |
| Is this publish still what was reviewed? | random candidate ids, whole realm current clause |
| Does this operation still describe the saved state? | random `AuthoringObservationId`, `stale_observation_error` |
| Is the panel's copy current? | full `QueryAuthoringState` after every `AuthoringChanged` |

Measured costs: about 50 full reads per commit and per finding change (5 MB at 1000 names); a lost last hint leaves a panel stale with no heartbeat to notice; submission dedupe keeps 1024 keys realm wide; every operation call goes stale on any commit; a publish can starve under steady edits; repairs can conflict with others' pending edits.

The realm graph already answers the same question inside the realm: an edge remembers the revision at which the part it read last changed ([formula-language.md](formula-language.md#query-graph)). This record makes that the one answer, seen from outside the realm too.

## The four primitives

### 1. Clock and log

- **When** the realm graph advances (a commit, a catalog activation, a stored input change), **then** the realm clock moves by one. That count is the **revision**.
- The clock is **in memory**. **When** the realm restarts, **then** it starts a new **epoch** for every table and counts from zero again.
- The **commit history** (`AuthoringCommit`) is the one durable record of authored change. Its order is the order admission admitted the commits.
- **When** a client submits an edit, **then** its submission key is a field of the commit. Deduplication reads the history; the separate dedupe table (`commit_submission`) goes.

### 2. Table

A table is rows addressed by a key with a prefix order (`ValueLocation` with `ItemId` paths for authored values).

- Each row keeps `changedAt`, the revision at which its value last became different. Writing an equal value keeps `changedAt`.
- A removed row leaves a **tombstone** for a bounded window, with a floor below which the table answers with a full read.
- Each table keeps a **change log**: the keys changed after a revision.
- A table's **watermark** is `{table, epoch, revision}` *(proposed)*.
- A table is either **durable** (rebuilt from the durable record after a restart) or **leased** (rows live while their writer renews them).
- A read looks at one **part**:

| Part | What it covers | Its change revision |
| --- | --- | --- |
| `Cell` | one value | the cell's `changedAt` |
| `Row(key)` | one row | the row's `changedAt` |
| `Rows(prefix)` | every row value under a prefix | the largest `changedAt` under the prefix |
| `Keys(prefix)` | which rows exist under a prefix, values ignored | the revision of the last insert or removal under the prefix |

Resources, links, findings and publication rows are tables. Derived tables (findings, publication rows) are computed by the realm graph; input tables (authored values) are set by commits.

### 3. Remembered read

```
RememberedRead { table, part, seen }        // seen: the revision the part last changed when it was read
```

- **When** anything decides based on what it read (an edit guard, finding evidence, a publication candidate, an operation on unsaved work, a graph edge), **then** it keeps a remembered read per part it read.
- **When** the realm checks a remembered read, **then** it holds while the part's change revision still equals `seen`. Nothing else is compared: no values, no hashes.
- **When** a part changes and changes back, **then** its change revision has moved, so the remembered read fails. This is deliberate (see Same value).

### 4. Watch

One protocol for every remote reader of a table.

- **Pull by watermark.** The reader sends the watermark it has; the realm answers the rows changed after it (rows with `changedAt` past it, plus tombstones) and the new watermark. A watermark below the tombstone floor, or from another epoch, answers a full read, paged.
- **Digest.** Each answer carries a digest of the table (XOR of `hash(key, changedAt)`); a mismatch with the reader's own digest makes it pull a full read.
- **Hint.** **When** a table advances, **then** the realm sends a hint carrying the new revision. The hint carries no rows.
- **Heartbeat.** **When** no hint went out for a heartbeat period, **then** the realm sends the hint again with the current revision, so a lost last hint is noticed.
- **Leased demand.** **When** a reader watches a computed table, **then** it writes a leased demand row (`{reader, table, scope}` *(proposed)*) and renews it; the realm computes the table only while some demand row lives. No acknowledgements and no other per client state on the realm.
- **Scope.** A watch names a scope (all, some resources, some types), so a reader pulls only the part it shows.

## Decisions

Each decision below is the rule it sets. Numbers follow the maintainer's answers.

### 1. Seen is the change revision

**When** an edge or remembered read records what it saw, **then** it keeps the revision at which the part last changed, never a value hash. This is exact (no collisions), costs one number per row and trie node, and gives `each` and `fold` their delta from the change log.

### 2. One realm clock, in memory

- **When** the graph advances, **then** the one realm clock counts it; every table's watermark uses that clock.
- **When** the realm restarts, **then** every table gets a new epoch; every panel and engine does a full read of what it watches.

### 3. Commit history is the log

- **When** a commit is admitted, **then** it is appended to the commit history with its submission key.
- **When** a submission key repeats, **then** admission answers the earlier commit's outcome from the history.
- **When** a tool undoes commit N, **then** the undo commit guards "unchanged since commit N" on each part commit N changed, as remembered reads, not as full expected values.

### 4. An edit is intents plus a base watermark

- **When** a client sends an edit, **then** it sends its intents and the watermark it based them on. It sends no expected values.
- **When** admission receives it, **then** the realm derives the parts the intents read and refuses the edit when any of those parts changed after the base (a part changed and changed back refuses too).
- **When** the base is from an older epoch (the realm restarted), **then** the panel does a full read and, for each part its pending edits read, compares its old baseline value with the new read: unchanged parts rebase onto the new watermark; changed parts go to conflict review.

### 5. Narrow guards

- **When** an edit touches a list, **then** it guards the items it names plus the neighbours that fix its order (an insert's anchor, a move's item and anchor), not the whole list.
- **When** an edit touches a relation, **then** it guards that one relation's links, not every relation of the resource.

### 6. Same value keeps the guard

**When** two authors set the same part to the same value, **then** the second edit still conflicts and goes to conflict review. There is no last writer wins.

### 7. Operations on unsaved work

- **When** a client runs an operation (a formula watch, a preview, a computation) on work it has not saved, **then** it sends its pending intents plus their base watermark; the realm applies them to the **current** revision and answers with `at` (the revision it answered at).
- **When** a pending intent no longer applies at the current revision, **then** that is the same conflict an edit would get, shown the same way.
- Observation ids and `stale_observation_error` go. Whole record overlays become intents.

### 8. Findings are a derived, watched table

- **When** a check runs, **then** its findings become rows of the derived `Findings` table, keyed by the check instance.
- **When** anything a check read changes, **then** its row's edge is dirty and the row is **outdated** until the graph cleans it. Outdated means a dirty edge; nothing is judged per reply.
- **When** findings travel on the wire, **then** their evidence is the parts they read (remembered reads), not `CheckEvidence` facts the client must judge.
- `AuthoringState.findings` goes; clients watch `Findings`.
- Publication refers to finding rows; it does not copy findings.

### 9. Publication rows and candidates

- **When** the realm reports publication state, **then** it is derived rows per root (one book, one realm section) in a publication table, not one realm wide `PublicationStatus` with findings inside.
- **When** the realm issues a candidate, **then** the candidate is a remembered read of the root rows it showed, including every part their checks read. It has no random id.
- **When** a publish arrives, **then** admission checks the candidate's remembered reads inside the admission queue and releases exactly what was reviewed.

### 10. Release rule

**When** a publish arrives, **then** it is blocked only by a change to something the candidate read. A commit elsewhere in the realm does not block it. This replaces the clause that the whole realm must still be current, and ends publish starvation under steady edits.

### 11. Engine action gate per root

**When** an engine action (capture, teleport, run an entry) checks whether content is ready, **then** it looks only at the roots the action needs, not at the whole realm's publication state.

### 12. One remote watch protocol

**When** a remote reader follows a table (panel tabs, engines, services), **then** it uses the watch: pull by watermark, digest, heartbeat hint carrying the revision, and leased demand rows for computed tables. It replaces the separate protocols, among them full state reads after `AuthoringChanged`, findings inside state, the publication watch, and the tab's `WatchValues`; the sync pull request names the full list of six.

### 13. Engines watch publication rows

- **When** an engine needs content, **then** it watches the publication rows of the roots it runs through the one watch.
- **When** an engine applies a publication, **then** it writes an applied mirror row; the view shows "applied on N of M" from those rows. This replaces the holding PR's temporary publication applied push.

### 14 to 17. Later direction

Adopted as direction, built in this order, each after a short design check:

| Order | Decision | Direction |
| --- | --- | --- |
| 1 | 15 | the stored `Changed<T>` push aligns its form with the watch |
| 2 | 16 | presence and sessions as leased rows |
| 3 | 17 | backend organization projections as watched tables |
| 4 | 14 | the catalog as an input table (highest risk, last) |

## Scenarios

| Scenario | What happens |
| --- | --- |
| Two authors set the same value | Both base on revision r. The first commits; the part's change revision moves. The second is refused with a conflict and goes to conflict review, even though the value matches (decision 6). |
| Two authors edit the same list | Each guards only its named items and their order neighbours. Inserts after different anchors, or after the same anchor, both commit (same anchor lands in commit order). Only removing or moving a guarded item conflicts. |
| Shared hub resource (a page every element links to) | Each edit guards one relation's links or one list item, never the hub's whole record, so 50 authors adding elements to one page do not conflict. |
| Different resources | Disjoint parts: no conflicts, and each watcher pulls only the changed rows. |
| Rename | A rename changes one name row and dirties the edges of readers of that name (through the name index). Findings that read the old name become outdated and recheck; edits whose derived parts include that name conflict; others commit. |
| Edits during checks | A commit advances the clock and dirties only the findings rows whose edges it touched. Clean rows stay clean; outdated rows show as outdated until their recheck. A check never runs against an old revision. |
| Publish during edits | The candidate remembers what its roots and their checks read. An edit outside those parts does not block release (decision 10). An edit inside them answers `candidate_changed_error`; the panel takes the new candidate once its checks are clean. |
| Realm restart | New epoch for every table. Watchers see the epoch change on the next hint or heartbeat and do a full read. Panels rebase pending edits whose read parts are unchanged and send the rest to conflict review (decision 4). The commit history is the durable record of authored change; derived tables are recomputed, and the realm keeps no watcher state to recover. |
| Lost messages | A lost hint is noticed at the next heartbeat (it carries the revision). A lost or reordered answer is caught by the digest. Either way the reader pulls from its watermark again, or a full read below the floor. |
| 50 authors on 10k elements | A value edit costs work proportional to what it touched: graph marking and cleaning of that row's readers, one changed row in each watcher's pull, one hint per watcher. No full state reads; no reply time judging. |

## What it replaces

| Today | Replaced by |
| --- | --- |
| `EditExpectation` with full expected values | intents plus base watermark; parts derived by admission |
| `AuthoringObservationId`, `confirmed_observation`, `stale_observation_error` | operations answered at current with `at` |
| `commit_submission` dedupe table (1024 keys realm wide) | submission key on the commit, read from the history |
| `CheckEvidence` facts judged by clients, `FindingFreshness` per reply | remembered reads; outdated means a dirty edge |
| `AuthoringState.findings`, findings in `PublicationStatus` | the watched `Findings` table; publication refers to rows |
| random candidate ids, whole realm current clause | candidate as a remembered read; release blocked only by what it read |
| realm wide engine action gate | gate per root the action needs |
| full `QueryAuthoringState` after each `AuthoringChanged` | the watch: pull by watermark, digest, heartbeat hint |
| separate watch protocols (publication watch, tab value watch, and the rest of the six) | the one watch with leased demand |
| holding PR's temporary publication applied push | applied mirror rows read through the watch |

## Delivery plan

Each step is one pull request. Requirement tests are written first and fail before the code. Event core (#580) needs only #583.

| Step | Pull request | Covers |
| --- | --- | --- |
| 0 | design record | this file; authoring-writes.md and panel-engine-communication.md updated |
| 1 | check pass | graph core with seen as revision; findings derived internally; no wire change |
| 2 | sync | the watch for resources, links and findings; replaces full reads and `AuthoringChanged` |
| 3 | edits | decisions 3, 4, 5, 6, 7 and restart recovery |
| 4 | publication | decisions 9, 10, 11 |
| 5 | engine delivery | decision 13 |
| 6 | later | 15, 16, 17, then 14 |

### What each pull request must prove

**1. Check pass**

- A value edit of one row marks, cleans and recomputes only that row's readers: equal counts at 10 and at 10,000 rows.
- A part changed and changed back fails a remembered read; a part left alone holds it.
- A findings row is outdated exactly while one of its edges is dirty, and clean again after its recheck.
- A commit outside a check's reads leaves its findings row clean and not recomputed.

**2. Sync**

- A watcher at revision r pulls exactly the rows changed after r, plus tombstones; a value edit sends one row, not the realm.
- A lost last hint is noticed within one heartbeat and the watcher catches up.
- A digest mismatch makes the watcher pull a full read and end with the realm's rows.
- A watermark below the tombstone floor, or from another epoch, answers a full read.
- A computed table is computed only while a leased demand row lives, and stops after the lease ends.

**3. Edits**

- Two edits on disjoint parts both commit; an edit whose derived parts changed after its base is refused.
- Setting a part to the value another author just set is refused (same value keeps the guard).
- Two inserts after different anchors in one list both commit; removing a guarded anchor refuses the insert.
- An edit on one relation of a resource does not conflict with an edit on another relation.
- A repeated submission key answers the first outcome and commits nothing.
- Undo of commit N is refused when a later commit changed a part N changed, and applies otherwise.
- An operation on pending intents answers at the current revision with `at`; a pending intent whose parts changed gets the edit's conflict.
- After a restart, pending edits whose read parts are unchanged rebase and commit; the others reach conflict review.

**4. Publication**

- A candidate issued for clean roots is released exactly as reviewed.
- A commit outside what the candidate read does not block its release.
- A commit inside what the candidate read answers `candidate_changed_error` and changes nothing.
- Under a steady stream of unrelated edits, a publish still releases (no starvation).
- An engine action checks only the roots it needs: a blocked unrelated root does not disable it.

**5. Engine delivery**

- An engine receives a new publication of its roots through the watch, and catches up after a lost hint or a realm restart.
- An engine's applied row appears after it applies, and the view counts "applied on N of M" from those rows.

## Open

- The exact list of protocols the one watch replaces is named by the sync pull request (decision 12 counts six).
- Scope of a watch for findings and publication rows (per root, per resource) is set by the sync and publication pull requests.
