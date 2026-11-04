# Panel and engine communication

> **Status: phase 2, developer experience.** Planned with the planning flow: requirements, then developer experience, then the plan. Questions 1 to 13 are settled except the reason set of question 4; what remains is listed under Open. Sections: Decided, Unreviewed input, Draft, Open.

Everything where a panel client (browser tab, desktop app, mobile app) and engines talk to each other, in either direction, and how a presentation declares such an action. Related: [engines.md](engines.md), [authoring-writes.md](authoring-writes.md), [live-data.md](live-data.md#session).

## Decided

- Requirements come before design: no mechanism (request events, acknowledgements, target choice) is decided until the scenarios are confirmed.
- The record lives in `docs/design/` (project rule) and is committed when the topic is finished.

### Scenarios (confirmed 2026-10-31, phase 1 gate)

Tags are the milestones defined in [closed-beta-roadmap.md](closed-beta-roadmap.md): alpha, beta, after, someday. Hard cases first in each group.

Scope rule: a scenario belongs here only when the panel and an engine talk to each other (directly or through the realm on an engine's behalf). Panel to realm only flows (publishing, hot reload, others' edits, general product facts) are out of scope.

**A. Scenes, preview, record**

- A1 (beta; alpha edits scenes from the panel with simple recording through the same realm transactions) In game scene editor. The whole scene (camera, NPCs, every track) is edited live in game in one editor, not in separate content modes per track; it records and writes over existing frames, and writes to the realm directly. Several creators record on the same scene at the same time, synchronized, like a group dialogue. A server move cancels the transaction in progress; finished recordings are kept. Its own design topic (scenes layer); this topic carries what it needs from engine and panel communication.
- A3 (after) Preview a step, dialogue, or scene for a chosen player without changing their real progress, and stop it from the panel or in game.

**B. Inspect and debug**

- B1 (beta) Watch one player live: their running interactions, steps, holds, and stored values, updating as they play. Hard: the player switches servers; the player is offline (last known state).
- B2 (beta) Live formula values: a formula field shows its value for a chosen player right now.
- B4 (beta) Online players and "who is in spawn" (audiences, regions) live in the panel.
- B7 (beta) Live inspect an NPC and edit a field in place.

**C. Capture and in game tools**

- C1 (alpha) Capture a field from the game: position, held item, looked at block, a region corner. Works from the panel button and from in game, with no panel open; uses the newest content.
- C2 (alpha) Pick in the world: select an NPC, a block, a region by looking at it or with a held tool.
- C3 (alpha) In game editors with handles drawn by the server (no client mod): road network, region shapes, with undo and redo and many writes.
- C4 (beta) Other creators in game see edit previews with name tags.
- C5 (open: no clear use case yet; tag it when one appears) Capture a list of things at once, for example every block in a selection.
- C6 (alpha) Go to a captured value: teleport the player there, or highlight the block or region in game.

**D. Act on players and choose the target**

- D1 (alpha) Choose the target player: any online player; the choice is remembered in the user's settings, so web, desktop and mobile share it. No account link needed.
- D2 (alpha) Teleport, give an item, run an entry or a single step on the target, with feedback in the panel and in game.
- D3 (alpha) Explain why an action is unavailable (target offline, no engine can do it, no permission, production realm, content blocked, checking, publishing, applying): the button is disabled with the reason as a tooltip.
- D4 (beta) Link Minecraft accounts to a Typewriter user, started from the panel or from in game. An extra that joins the two identities for presence (B4, C4 name tags) and per user team permissions in game; nothing in alpha depends on it.
- D5 (alpha) In game tools without a link: a server permission (for example `typewriter.edit`) gates them; the engine writes as its service principal with `initiated_by` naming the Minecraft player, so history shows the player. A creator's panel and in game edits show as two authors until D4.

**F. Engine knowledge**

- F1 (alpha) Editors know the server: materials, sounds, particles, worlds, plugin ids from the engines that run the book; version aware; work from the last report when no engine is online.
- F2 (after) Sound preview played in the panel itself (needs vanilla and resource pack sound files). Playing a sound to the target player in game is a D2 action.

**G. Failure and topology**

- G1 (alpha) An engine is offline, restarts, or the player moves between servers during a long action: the action in progress is cancelled with a clear reason; finished work is kept.
- G2 (alpha) The realm is offline or the cloud is offline: actions fail with a clear reason (D3) and the game keeps running its content. Editing during a cloud outage is after.
- G3 (alpha) Several engines and engine kinds run one realm; the panel engine runs next to the realm.
- G4 (alpha or beta, to confirm) Same host shortcut: when engines, or engines and the realm, run on the same host, the host carries their traffic locally instead of over NATS. Engines and the realm do not notice. It covers most traffic, not only panel and engine communication: stored data sync saves the most. Alpha requirement either way: no contract or API assumes NATS, so the shortcut needs no engine or realm change.

**H. After the closed beta, and team permissions**

- H1 (after) Panel engine tutorials that react to what the user configured, installable from the docs.
- H2 (after) An MCP or AI assistant that triggers actions; its reads and writes are covered by authoring writes.
- H3 (beta) Team permissions decide who may act on which player; comes with paid team management and D4.

## Unreviewed input

### Vision requirements (agent research)

The vision covers little of this topic directly. Requirements it does state:

- Visual configuration, not scripting; every panel action works on mobile and by keyboard alone (README.md:9; panel.md:10-11,36-37).
- Edits feel roughly live: publish after about five seconds, "publish now" skips the wait, running interactions swap to new content immediately (publication.md:9,17,20,50,52).
- Content and player data live only on the realm (topology.md:36-44). The realm is not a gateway: live traffic goes directly between engines through session subjects (live-data.md, Routing); only what the realm owns goes through the realm.
- Web clients now, desktop later, mobile apps long term (panel.md:33-35).
- One realm drives many engines; each engine gets only the content its capabilities support; the catalog is filtered by every engine running a book (topology.md:56,63; publication.md:28; engines.md:14).
- The panel engine runs next to the realm with the panel user as its player; tutorials react to what the user configured (engines.md:39-43).
- Panel accounts link to game accounts; capture from a default protagonist or one picked from the online list (panel.md:18; formulas.md:310).
- View and edit a protagonist's stored data, also offline, as if the protagonist wrote it, through the realm's transactional checks (data-storage.md:7-16,62,104-108,138).
- The panel can start interactions as an outside world start (interactions.md:27,164).
- Development realms play content; production realms have no visible or editable entries (realm-modes.md:10-11).
- Live formula values for a specific protagonist; where a stored value came from; live updates on group changes (panel.md:16,38; formulas.md:310,337; data-storage.md:33,106).
- Diagnostics before a step starts (hold clashes) and publication blocked on errors (interactions.md:110; publication.md:24).
- Protagonists keep playing during a cloud outage (topology.md:46). Slightly stale reads across engines are acceptable (data-storage.md:112).
- An AI assistant and MCP access later (ai.md:12-13,30-31).

Vision ambiguities for this topic: where the panel engine runs (engines.md:31 versus :41); several engine kinds per book (publication.md:28 versus engines.md:60); stored data edits in production; whether the panel engine counts toward the multi server add on; "Minecraft account" linking versus engine neutral naming; the catalog when no engine is online; whether creators can edit during a cloud outage.

Not covered by the vision: recording, in game tools, preview of a chosen entry for a chosen protagonist, step debugging and tracing, testing without real players, concurrent editing, permissions for acting on players, the linking flow, acting on the world beyond data edits, addressing a specific engine.

### Precedent (agent research, partly unverified)

Use cases from other tools that the inventory lacks:

- Select a region with a visual handle in the world (WorldEdit CUI), drawn by the server when no client mod exists (WorldEditSUI, WorldEditDisplay).
- Preview a step or scene on a chosen player without changing live state.
- Live inspect an entity or NPC and edit a field in place (Godot remote scene tree).
- Follow another author's view (Figma follow mode).
- Live player positions on a panel map with hiding rules (BlueMap).
- Run one command or step on a chosen player from the panel (Denizen `/ex`).
- Simulate several players in a test (Roblox Server and Clients).
- Show which engine is down before an action is sent (Pterodactyl handshake errors).
- Explain why an action is not allowed (Axiom `/whynoaxiom`).

Lessons: selection by looking or a held tool works; explicit instance pickers work; drafts private until committed work. Direct browser to game server sockets break behind TLS and firewalls (Pterodactyl); mode switches that silently change what runs confuse (Roblox drafts versus Team Test, Bedrock Editor); recording that disturbs other clients hurts (Unreal Take Recorder with Multi User); slow play mode entry hurts (Unity); large payloads hit transport limits (Axiom, 32 KB custom payloads).

### What users see today (agent research)

Current panel: the connection shows only as status. Realm online dots and a realm offline veil (`features/realms/presentation/realm_suspension.dart:121-225`), the realm inbox with publish state (`realm_inbox.dart:65-122`), conflict review against saved realm values (`authoring_conflict_notice.dart:18-45`), realm backed search, the services topology graph (hosts, realms, engines, connected or offline: `services_graph.dart:33,157-234`), server registration by token, and realm commands from authored presentations. Presence heartbeats are sent but never displayed (`organization_presence.dart:42-80`). No capture, no live game data, no online players, no version aware editors.

Legacy panel behavior users rely on that the current panel lacks:

1. In game capture into a field (position, item, cinematic recording over the selected segment's frames), publishing first so the server captures the latest content (`app/lib/widgets/inspector/headers/content_mode_action.dart:56-119`).
2. Writer presence: who is online, and avatars on the page, entry, field, and segment someone edits (`app/lib/widgets/components/app/writers.dart:25-173`).
3. Live sync of other users' edits as they happen (`app/lib/models/communicator.dart:176-235`).
4. Version aware editors: materials flagged unavailable on the connected server's version (`app/lib/widgets/inspector/editors/material.dart:41,327`).
5. Joining from in game with `/typewriter connect` (`app/lib/pages/home_page.dart:32-47`).
6. Sound preview in the panel (from mcmeta, not the server) and a manual Reload Data button.

### Use case inventory (agent research)

Direction: panel to engine (P to E), engine to panel (E to P), engine writes the realm while the panel watches (E to R). Milestones live on the scenarios below; the Scenario column names the scenario that covers each row (out: outside this topic's scope; dropped: removed in review).

| Group | Use case | Direction | Timing | Scenario |
| --- | --- | --- | --- | --- |
| Capture and pick | Capture a field (position, held item) from a player | P to E to R | one shot, or a short mode | C1 |
| Capture and pick | Capture started in game, no panel | E to R | one shot | C1 |
| Capture and pick | Pick a block by looking at it; pick road nodes | P to E to R | long running | C2 |
| Capture and pick | Pick the target player | P | query | D1 |
| Capture and pick | Registry search and existence checks | E reports, P reads | cached report | F1 |
| Act | Teleport to a value | P to E | one shot | C6 |
| Act | Fire an entry or trigger for a player | P to E | one shot | D2 |
| Act | Give an item from a field | P to E | one shot | D2 |
| Act | Edit a protagonist's stored data | P to R, E sees it | one shot | out (panel to realm) |
| Preview and play | Preview a step or scene (`Simulating`) | P to E | long running | A3 |
| Preview and play | Scrub a scene: cursor, play, pause, speed | both | long running | A1 |
| Preview and play | Timeline playhead follows playback in game | E to P | stream | A1 |
| Preview and play | Hot reload while standing in content | P to R to E | continuous | out (panel to realm) |
| Record | Record movement into a segment, record over frames | P to E to R | long running, one batched commit | A1 |
| In game tools | Road network editor, region shape editors with undo and redo, region workspace | in game, E to R | long running, many commits | C3 |
| Inspect | Live formula values per protagonist | E to P | stream | B2 |
| Inspect | Stored data view with live changes | E and R to P | stream | B1 |
| Inspect | Online index and online players list | E to R to P | stream | B4 |
| Inspect | Running interactions, holds, chains for a player | E to P | stream | B1 |
| Inspect | Region and pathfinding debuggers | in game | long running | dropped |
| Inspect | Engine reports: registries, worlds, plugin ids, versions | E to R | on connect and change | F1 |
| Testing | Play content on a development realm | P to E | long running | dropped |
| Testing | Presets for test state | P to E | one shot | dropped |
| Testing | Simulate other players or groups | P to E | long running | dropped |
| Panel engine | Tutorials that react to what the user configured | panel engine | long running | H1 |
| Presence | Who edits which page and field; cursors | P to P | stream | out (panel to panel) |
| Presence | In game spectators see others' edit previews | E to players | stream | C4 |
| Other | Account linking, several accounts, fast switching | P and E | setup | D4 |
| Other | Publication status and errors pushed to the panel | R to P | stream | out (panel to realm) |
| Other | MCP or AI assistant writes content | service to R | one shot | H2 |

### Fit map (agent research 2026-10-31, against the decided design first, then code)

No event core, sessions, principals, or bridges are built yet; `runtimes/paper` and `runtimes/panel` hold only build files. So "code" is "not built" unless noted.

| Need | Design | Code |
| --- | --- | --- |
| Routing to where the subject is live | decided: protagonist subjects, plus session subjects for one connection (live-data.md Routing) | not built |
| C1 capture | partly: in game write path decided (engines.md; authoring-writes.md example 2); value via `fromPlatform` | commit route admits members only |
| C2 pick in the world | settled: questions 5, 6 (waiting modes in layer 25) | not built |
| C3 in game editors | partly: batching and reruns (authoring-writes.md tier A); undo and drawn handles settled: questions 12, 13 | `XDraft.setX` exists |
| C6 go to a value | partly: routing and handler placement decided; highlight settled: question 13 | not built |
| D1 target player | decided (engines.md); settings storage and online list settled: question 9 | panel prefs local only |
| D2 act on the target | partly: routing, bridges, `Triggered<E>`; feedback missing | panel dispatch only |
| D3 explain unavailable | partly: offline and capability filtering defined; no typed reason set | untyped reason slots |
| D5 in game tools | decided (engines.md; authoring-writes.md Principles); authoring policy settled: question 11 | not built |
| F1 engine reports | concept accepted; shape, merge, storage settled: question 10 | `ProbeRealmHosts` roles and versions only |
| G1 engine gone, server move | partly: leave and rejoin, cancellation of suspended handlers, atomic edits | not built |
| G2 realm or cloud offline | partly: live effects survive realm outage; NATS or cloud outage silent | engines keep last publication |
| G3 several engines, panel engine | partly: panel sessions per tab, presence heartbeat reuse; client link and grace missing | `PANEL_ENGINE` placement, `PanelPresence` |
| Action declaration, context | settled: question 8 (`EditorAction.emit`) | `EditorAction` without engine target |
| Fresh content | partly: panel engine tracks drafts; silent for Paper | not built |
| Long running work | building blocks only (session keyed values, cancellation, `Runtime`, `Simulating`) | search watch only |
| Feedback | partly: engines emit back to panel sessions (draft); no reply concept | `PanelInstruction.notify` for realm commands |
| Streams on demand | settled: demand crosses engines (question 14) | realm served `watch` only |

### Open questions from the fit map (ordered; earlier answers inform later ones)

1. Settled 2026-10-31: the panel engine holds each tab's session (`typewriter.session.<tab>`) and runs its handlers and derives; the tab is a thin client that talks directly to the panel engine over per tab subjects, like a Minecraft client to Paper. The browser has grants only to its own user's subjects (per user, decided 2026-11-04; a connection is bound to its user, not to a tab). Panel session grace: 45 s, the current presence expiry. (G3, C1, C6, D1, D2)
2. Settled 2026-10-31: events about a protagonist go to `typewriter.protagonist.<id>`; every engine holding a session of it subscribes and runs the handlers it can. Session subjects stay for one connection targets. (C6, D2, D3, G1)
3. Settled 2026-11-03: there is no single writer; every stored write is a realm transaction (stored-data.md). (G1, D2, C3)
4. Settled 2026-10-31: the result of an event emitted from a session goes back to that session's subject once its after handlers finish: `Done`, `Denied(reason)`, `Failed(reason)`, or `NotHandled`. Deny verdicts carry the typed reason (D3); permission checks are deny handlers. `NotHandled` means no engine holding the subject's sessions has a handler; every holder answers; a holder that stays silent gives `Failed` after a timeout (events-and-handlers.md). Settled 2026-11-03: the reason is `EventReason { code, message, detail? }` (events-and-handlers.md). (D2, D3, G1, G2)
5. Settled 2026-10-31: there is no mode concept and no generic content framework or helper. Each feature that needs a running mode (capture, pick, an editor, recording) builds it from the primitives: a stored value keyed by the session is the mode, holds draw it and offer its input, a `Runtime` holds in progress buffers, an authoring `edit` saves, an event ends it (its result reaches the panel). Server moves, cancel, clashes, and session loss follow the existing rules. (C1, C2, C3, G1)
6. Settled 2026-10-31: there is no capture concept; each type owner defines its own event and handler (Location: the Minecraft capability). The engine saves; the value never returns to the panel to be saved. `initiated_by` comes from the occurrence's `Origin` (replaced the `@As(Requester)` role on 2026-11-01, see Draft below). The field to write is a `BoundPath<T>` (exists: `TypedPath.kt:99`). (C1, C2)
7. Settled 2026-10-31: publish first, then send; an engine never waits for content.
   - Buttons that act on engines are disabled, with the reason as a tooltip, while the publication view (`authoring_publication_watch`) is `blocked`, `unavailable`, `checking`, `publishing`, or applying, and while their own click is in progress (no double click).
   - On click: read the view (`QueryPublicationView`). `current{selected: P}` goes straight to the wait; `ready{candidate}` calls `PublishAuthoring(candidate)`. `blocked_error` stops and shows the blockers; `candidate_changed_error`, `publishing`, and `interrupted_error` read the view again; `activated{P}` continues.
   - Wait until every connected engine that runs this content has applied P ("fully published"). An engine that fails to apply P stops the action with its message ("paper-2 couldn't load your change: ..."). Then the event is sent.
   - New piece: engines report the publication they applied, or their delivery failure (today `EngineContentDeliveryHealth` in `CompiledContentDelivery.kt` stays local). Part of engine reports (F1); the publication view shows "applied on N of M engines".
   (C1, D2, D3)
8. Settled 2026-10-31: a presentation declares an engine action with a new `EditorAction.emit`, built in the scope block style of the DSL.
   - Wire: `EmitEventAction { event: TypeDefinitionId; fields: [EventFieldValue] }`, `EventFieldValue { path; value: EventFieldSource }`, `EventFieldSource { expression: ExpressionNode; location: BindingRef }`.
   - Kotlin: KSP generates an emit scope per event with one function per field; the origin is never a field (the panel engine attaches it). `valueLocation` and `locations.<field>` lower to a `BindingRef` the way `createResource` lowers `owner` (`PresentationActions.kt:244`); the panel resolves it with `context.location(...)` (`resource_action_dispatcher.dart:108-112`).
   - Target: new host context input `target_protagonist` (`HostContextInput`, `EditorContext.targetProtagonist`), filled from user settings; needs the portable form of `Protagonist` (layer 3).
   - Panel: `canExecuteActionFor` disables `emit` actions while `engineActions.blockedReason` is set (publication blocked, unavailable, checking, publishing, applying; shown as the tooltip) or while the action is pending (`operation_results.dart` `pending`, today tracked but not drawn).
   ```kotlin
   section(header = {
       button(HeaderItemId("capture")) {
           icon(literal("crosshair"))
           label(literal("Capture from target"))
           action(emit(CaptureLocation) {
               into(valueLocation)
               player(context.read(EditorContext.targetProtagonist))
           })
       }
   }) { ... }
   ```
   (C1, C6, D2, D3)
   - Settled 2026-11-01: events come from extensions, so the panel and the panel engine never need an event's class. Every event is a Typewriter type with an explicit `@TypewriterType(id = ...)`, like `Location` (`TypewriterTypeProcessorProvider.kt:190`). It travels as its `DataValue`; Paper decodes it through `NativeBindingRegistry.bind` (needs the type in its checked catalog); the tab checks field values against the event's `PublishedType`. KSP rejects fields that are not Typewriter types (`KspTypeGraphConverter.kt:175`).
9. Settled 2026-11-01: the chosen target is a stored value, `ChosenTarget(@Key val user: Protagonist, val target: Protagonist) : Stored` (the panel user is a protagonist), so it follows the user across devices; the tab reads it through its panel engine session and fills `EditorContext.targetProtagonist`. The online list is a mirror in the Minecraft capability, `OnlinePlayer(@Key val protagonist: Protagonist, val name: String, val server: Engine) : Live`, which the panel's target list demands across engines (question 14). Rejected: browser local storage (per device), reading the `sessions` KV (no name, includes panel sessions). (D1)
10. Engine reports (F1, D3), split in three:
   - 10a settled 2026-11-01: there is no engine report concept. The engine is an identity, `Engine(id: EngineId) : Identity` (core, like `Session`). The engine kind is not a field and not a closed enum: it is the engine artifact id, `EngineKind(value: String)` = topology `EngineTarget.engine_id` (`topology.skir`), stored once in the topology and open to third party engines. Bridges register per artifact at build time, each engine's `SessionReporter` supplies its grace, and the realm reads `EngineInstance.target.engine_id` when it keeps an interaction inside one kind, and reports are ordinary typed values keyed by it. What an engine is doing now is `Live`: `ContentDelivery(@Key engine: Engine, health: EngineContentDeliveryHealth) : Live` (today's local type in `CompiledContentDelivery.kt`, made a Typewriter type); its keys are the connected engines of question 7 and `Active(P)` counts "applied on N of M". What an engine knows is `Stored`, written when the engine starts and when the fact changes, so it survives the engine being offline (F1); see 10b for its shape. Extensions report their own facts the same way. `EngineId` is the stable topology `engine_id` (`topology.skir` `EngineInstance`), so an engine identity survives restarts and ends only when the engine leaves the topology. The panel engine is an `Engine` too. `OnlinePlayer.server` (question 9) is an `Engine`. Rejected: a report route plus an `engines` KV (two paths for facts about one engine), and a live mirror copied into a stored value (one fact stored twice).
   - 10b settled 2026-11-01: worlds, the registry ids marked (R) in minecraft-types.md, and external plugin ids are one abstraction, a reported id: an id type whose valid values only engines know. `interface ReportedId { val key: String }`; `World`, `BlockType`, `NexoItemId`, ... implement it. One stored type serves them all: `KnownIds(@Key engine: Engine, @Key type: TypeDefinitionId, ids: Set<String>) : Stored`, written by the engine for each `ReportedId` type it supports when it starts and when the set changes. The panel has one picker for every `ReportedId` field and the realm one check ("no engine reports this id"); extensions add their own types with no core change, and each engine's own version decides its set (version aware). Replaces `KnownWorlds`, per type stored types, pickers, and checks, and the registry search and existence check request events (engines.md). Engines report through ordinary handlers, no separate reporting path: the Minecraft source turns Bukkit world events into `WorldLoaded(engine, world)` and `WorldUnloaded(engine, world)`; their handlers `append` and `remove` the key on the generated `knownIds(engine, type)` reader (native set operations, so concurrent updates are not lost), and `Added<ContentDelivery>.recordWorlds(server: PaperServer)` `set`s the full set when the engine connects, which also drops worlds deleted while it was offline. `PaperServer` is the live trait of the `Engine` identity on Paper, as `PaperPlayer` is for a protagonist. Not covered yet: tag contents (`#logs` members, with `ItemTag`) and per id extra data (`GameRule` value types, `Statistic` targets), designed with those types.
   - 10c settled 2026-11-01: reported ids combine as a union over the engines that run the book (content goes per book to engines whose capabilities support it, vision/publication.md; the same set question 7 waits for), read from `KnownIds`; no merge code. The picker is a realm search capability (`SearchCapabilityDefinition`, capability.skir) listing each id with the engines that report it ("only paper-1"). The realm check is a query: no diagnostic when some engine reports the id, a warning while no engine has reported the type yet (fresh install), an error once one has. A removed engine's `KnownIds` end with its identity; an offline engine's stay. Rejected: a warning when only some engines have the id (normal in a network). Checks and searches read stored data through the query graph (closed-beta-roadmap.md, Decided), as migration dry runs already do (migrations.md).
11. Settled 2026-11-01: authoring policy for alpha is the existing route roles, no new policy concept: `authoring_edit_commit` (and the scoped read `realm.edit` needs) accept `organization_member` and `realm_participant`, which every service attached to the realm already gets (`services.rs`), so engines can commit. Per player rights in game are deny handlers on the engine (question 4); who acted is `initiated_by` from `Origin`, accepted only from service principals; per user permissions are team management (beta). Rejected: a per realm authoring role (a second permission system that team management replaces). (D5, C1, C3)
12. Undo and list guards (authoring-writes.md Open 3 and 8). (C3)
   - Undo settled 2026-11-01, alpha: the realm keeps a commit history, `AuthoringCommit { id: CommitId; actor: Actor; session: SessionId?; changes: [ValueChange { at: ValueLocation; before: DataValue?; after: DataValue? }] }`. Undo is a new commit with the inverse changes, each guarded by `EditExpectation.value(at, expected = after)` (authoring_facts.skir); a newer commit on the same value gives `conflict_error`, shown as entangled, the rule the region extension's `EditHistory` (PR #522) implements privately. `session` (from `Origin`) lets a tool undo only its own session's commits. One history serves the panel, in game editors, and every tool, replacing per tool histories. Built with engine authoring writes in layer 9; the history UI stays beta. Rejected: moving C3's undo to beta (a regression from the region extension).
   - List guards settled 2026-11-01: list operations guard only the items they name, not the whole list. `EditExpectation.exists { at: ValueLocation; expected: bool }` replaces `resource_exists` (a resource is its root location); insert guards its `after` anchor, remove its item, move its item and anchor, each at the list path plus `ItemPathSegment(id)`. Two tools adding nodes to one road network no longer conflict, and a removed anchor reruns on a fresh read instead of failing at apply (`AuthoringRecordValues.kt` `insertionIndex`). Inserts after the same anchor land in commit order; rules over a whole list stay with realm admission.
   - Naming settled 2026-11-01 (questions 8 and 9): the host context input is `target_protagonist` (`EditorContext.targetProtagonist`), because core says protagonist, never player (events-and-handlers.md); a Minecraft server is the `Engine` identity, so minecraft-types.md has no separate `Server` type.
13. Settled 2026-11-01: server drawn visuals need no new concept. Handles and highlights are holds: a mode or a stored value derives a hold (`RegionOutlineHold`), and a handler draws it per viewer (particles through `Player.spawnParticle`, entities shown to one viewer through the packet layer). The C6 highlight is an event (`HighlightRegion`) whose handler stores `Highlighting(@Key viewer, region, at) : Due`, which ends itself at `at`; its outline derive is the same hold the editor uses. All of C6 (teleport and highlight) lands in layer 25 with the editor handles, so C6 is not split inside alpha. Precedent: the region extension draws with per viewer particle packets and a `TextDisplay` (PR #522, `BoundaryPreview.kt`, `EditorHologram.kt`). (C3, C6)
14. Settled 2026-11-04, alpha (layer 8): `Indexed` is dropped; demand crosses engines through the `demand` and `mirrors` KV buckets, with the TTL pattern of the `sessions` KV ([live-data.md](live-data.md#demand-across-engines)). A reader creates demand wherever it runs (a formula in published content, the panel's target list, question 7 gating, a tab watching one player), for one key or every key of a mirror type, and authors read through `All<X>` unchanged. One mechanism covers what `Indexed` did (`OnlinePlayer`, `ContentDelivery`, audience counts) and B1/B2. A server move rewrites the same key, so a watching tab sees no gap. An offline player has no mirrors, so last known state means stored values. (B1, B2)

### Cross cutting needs

1. Target choice: any online player, remembered in the user's settings; account linking is a beta extra (D4).
2. Routing to where the subject is live, including server moves during long modes.
3. Action declaration: a type, field, entry, or page declares its actions so a presentation renders the button; engine neutral and filtered by capability.
4. Context passed with an action: entry, page, field path, current value, range (for example a segment's frames).
5. Fresh content: the engine acts on the current draft, not on content up to five seconds stale.
6. Long running work: start, progress, confirm, cancel from either side, nested or swapped modes, undo and redo.
7. Feedback: success or a typed error to the panel and to the player.
8. Streams on demand: subscribe and unsubscribe to live values.
9. Permissions: who may act on which player; attribution through the commit actor.
10. Offline cases: player offline, engine offline, cloud outage.
11. Several engines and engine kinds; the co-hosted panel engine.
12. Works without the panel open; the panel reflects in game writes live.
13. Large payloads (recordings).
14. Realm mode: content actions only on development realms; inspection on both.

### What exists for declaring actions

- `EditorAction` (`skir-src/editor/v1/action.skir:118`) on header items, buttons, icon buttons, and menu items (`presentation.skir:78-114, 995-1023`): `local` binding edits, `realm` (reload or a command), `navigate`, `authoring`, `create`.
- Realm capabilities (`capability.skir`, `@RealmCapability.Search/Computation/Command`): run in the realm process only; commands and computations are unary; search is the only stream (watch plus cancel).
- `PanelInstruction` (`capability.skir:76`): `invalidate_resource` (a full reload), `open_resource`, `notify`.

Gaps: no engine or player target, no caller in capability contexts, no progress or long running work, no value streams besides search, no action that writes a computed value into a field, thin feedback, and no Kotlin builder that attaches a command to a presentation (`PresentationActions.kt:92-231`).

### Precedent

- Unity, Unreal, Roblox: separate edit and play worlds with live inspection; Roblox distinguishes playing drafts (Play Solo) from committed content (Team Test) and can simulate several clients.
- Figma: cursor and selection presence.
- LuckPerms web editor: sessions start in game, edits come back as a diff after the session is trusted.

## Draft

### Conflicts to settle before layer 3 (from earlier decisions)

1. Settled 2026-11-03: no single writer; every stored write is a realm transaction.
2. Settled 2026-10-31: engines share stored state only through the realm; live effects and events go directly between sessions. The realm is not a gateway (vision updated).
3. Settled with 2.
4. "The realm is treated as untrusted" has no source in any design or vision doc; authoring-writes.md says `initiated_by` comes from a trusted service. Drop unless a source turns up.
5. Settled 2026-10-31: the panel session grace is 45 s, the current presence expiry.
6. Settled 2026-11-01 by questions 10a and 14: engine reports are mirrors (published through cross engine demand) and stored values keyed by `Engine`; neither needs a report path.
7. Where the decision runs when one event reaches several engines (verdicts from Paper and from the emitting engine must meet). An event core gap, not only a panel one: settle with layer 4 (event core).

### Emit without extension code in the panel engine (2026-11-01)

- Settled 2026-11-01, explicit form: `Origin(session, principal)` replaces the `Requester` role: the source fills it (the panel engine from the tab session, Paper from the player), never the event. It serves the result back (question 4), deny handlers, and `initiated_by`. A handler asks for `Origin` and passes `initiatedBy = origin.principal` itself; no implicit default (a coroutine context default was rejected as hidden state). With it, `CaptureLocation(player, into)` needs no roles: `player` is the subject as the only `Protagonist` field.
- The capture button belongs to the `Location` presentation in the Minecraft capability, next to the type and its event, so every `Location` field gets it (legacy precedent: `PositionContentMode` registered per type).
- The panel engine attaches the origin and publishes to the subject's protagonist subject; KSP writes the subject field's path into the emit action.
- Settled 2026-11-01: `BoundPath<T>` gets a portable form, because a place in authored content must outlive the panel's view: a mode that waits for the player (pick a block) keeps it in its stored value, so selecting something else, closing the tab, or a second tab cannot redirect the write (legacy: `ContentModeRequest` carried entry id and field path). Returning the value for the panel to write was rejected for that reason. Contract: a `value_location` representation next to `link` (`RepresentationTemplate.value_location: { target: TypeTemplate }`, `DataValue.value_location: ValueLocation`), and `BoundPath<T>` becomes a standard generic type like `List<T>` (`StandardTypes.kt`). Named `value_location`, not `location`, so it never reads as the Minecraft `Location`. Cost: every exhaustive match over these enums (about 31 Kotlin, 13 Dart, 3 Rust files, measured on `link`).
- Settled 2026-11-01: engines on another extension version need no new piece. An event names its exact `TypeDefinitionId` (type and revision); a primary engine only applies a publication whose `implementation_token` matches its own (`ReloadableEngineRuntime.kt:56-58`), and question 7 waits for that apply. An engine that lacks the exact type or cannot decode the value answers `Failed(reason)` ("paper-2 runs another version of CaptureLocation"); roadmap todo for layer 4.
- Moved to the roadmap as todos: portable `Protagonist` and the `sessions` KV value (layer 3); merging results across engines and every holder answering (layer 4).

## Open

- Question 4: the reason type set (D3).
- Conflicts 4 (the untrusted realm statement) and 7 (where the decision runs, layer 4).
- G4: whether the same host shortcut is alpha or beta.
- Phase 2: fit map of every alpha scenario onto the existing system, then directions in real code.
