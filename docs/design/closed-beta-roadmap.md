# Closed beta roadmap

Source design: the topic files in docs/design/ (start at overview.md) and docs/vision/.

## Decided

- Shape: a stack of self contained PRs on top of the agent harness and test review stack. Each PR ends in a simple but realistic Paper demo, informed by the legacy BasicExtension (a showcase, not a full port), with tests. Lower PRs get built while higher ones are still being designed and planned.
- Goal of the full stack: a few entries demo every primitive and the core functions (scenes, audiences, commands, dialogue, events, ...).
- 2026-10-30 additions: interaction bounds; debug and inspect (late, before migrations); a conversion track for legacy extensions starting around layer 20 (WorldGuard is not converted; the region extension from #522 replaces it).
- Scope includes items not yet designed: configurations (root resource replacing configs and snippets), artifacts and assets, content capture (the functionality of legacy content mode, not its way of working), panel header actions that trigger engine actions (capture position, teleport), and core needs revealed by develop PRs (#521 visibility, #522 region, road network).

- Layer order v4 adopted 2026-10-30 (see Draft for the list; it moves to Decided as the confirmed order).
- No separate multi server layer (2026-10-31): the primitives are multi server by design, so every layer whose behavior crosses servers proves it with a two engine test in its own PR (two engines in one process, no second Paper server). Server move handoff lands with sessions (3) and holds (15). The harness gets two engine support in layer 3.

## Unreviewed input

- Code state (agent survey 2026-10-30): the engine runs nothing yet (no handlers, players, sessions, stored data; Paper runtime module has build files only); the realm has authoring, publication, checks with input based invalidation (`ReverseDependencyIndex`), catalog, portable expression evaluator; no formula parser, no runtime stored data, no durable timers, no player sessions, no JetStream or KV use from Kotlin; adding a function type template touches about 20 exhaustive `when` sites; `XDraft` already models value, missing, invalid (`Availability`); no Kotlin `PortableKernel` (only panel Dart).
- Draft order of 23 layers (see chat 2026-10-30): base, formula core, Var and editor, Paper runtime and sessions, event core, stored data and variables, commands, mirrors and audiences, time and reactions, holds and interactions and dialogue, scenes, groups, NPCs, books, configurations, content capture and actions, assets, migrations, multi server, regions and visibility and road network, quests, importer, production realm mode.

## Draft

- Order v4, adopted (2026-10-30; primitives early because they inform later layers), each layer with its needs:
  - M1 Core primitives: 0 base; 1 formula core (0); 2 Var editor (1); 3 Paper runtime (0); 4 Minecraft value types (1); 5 event core with cancel (3, 4); 6 commands (5); 7 stored data (5); 8 time and reactions (7); 9 mirrors and audiences (7); 10 groups (7, 9); 11 configurations (2); 12 book variables and instances (1, 7); 13 capture and teleport (2, 3, 4).
  - M2 Show it: 14 packet layer (3); 15 holds (9, 11, 14); 16 interactions and dialogue (7, 10, 15); 17 interaction bounds (14, 16).
  - M3 Film it: 18 scenes (8, 14, 15).
  - M4 Populate it: 20 assets (3); 21 NPCs and entities (9, 14, 20).
  - M5 World it: 22 regions and world rules (5, 9, 13); 23 quests (6, 9, 15); 24 extension platform (5, 9); 25 in game editor tools (13, 14); 26 road network (20, 21, 25); 27 visibility (21).
  - M6 Ship it: 19 debug and inspect (9, 13), moved here 2026-10-31 because it is not strictly needed earlier; 28 migrations (2, 7); 29 importer 0.9; 30 production realm mode (28).
  - Conversion track: Vault and PlaceholderAPI, RPGRegions, SuperiorSkyblock (24); Citizens (16, 24); MythicMobs (18, 24); Entity rest (21, 25); Quest path objective (23, 26). WorldGuard dropped.
- Legacy evidence for packet needs: `ChatHistoryHandler.kt` (12 PacketEvents refs), `SidebarEntry.kt`, `ActionBarBlocker.kt`, `CameraCinematicEntry.kt` (spectates an EntityLib fake entity), `LockInteractionBoundEntry.kt`, `SetFakeBlockCinematicEntry.kt`; `PlayerRadiusInteractionBoundEntry.kt` needs none.
- Gaps found by the extension audit: packet interception, per viewer entity display, entity activities, path finding, skins, external plugin pattern, economy service hooks, in game editors, spatial index and world queries, PlaceholderAPI provider and consumer, item, sound and particle types, cancellable world rules, Bedrock detection, cross extension contracts.

## Open

- Reopen: stdlib reuse target (no Kotlin `PortableKernel`), and query graph versus growing `ReverseDependencyIndex`.
- Out of closed beta candidates: Bedrock (Floodgate) rendering, resource packs, localization.
- Design needed: panel user to Minecraft player link (for capture and teleport), cancellable sync handlers (world rules), packet layer, path finding, extension platform, debug and inspect, commands, NPCs and entities, configurations, content capture and engine actions, assets and artifacts, items, importer.
- Minecraft value types (layer 4): the Position and World proposal (namespaced world key, yaw and pitch in Position, no Coordinate) needs many changes; resume after the roadmap organization work is done.
