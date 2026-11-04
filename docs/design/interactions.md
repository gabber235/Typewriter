# Interactions, holds, and runtime objects

How Typewriter runs things that take time for a protagonist: interactions and their steps, the holds they place on a protagonist's view, local runtime objects, groups, scenes, NPC scope, and preview. Product intent lives in [../vision/interactions.md](../vision/interactions.md); this file says how it works.

Related files: [overview.md](overview.md) (the primitives), [events-and-handlers.md](events-and-handlers.md) (handlers, verdicts, chains, `Triggered`), [stored-data.md](stored-data.md) (`Stored`, keys, `apply()`), [live-data.md](live-data.md) (mirrors, sessions, routing), [formula-language.md](formula-language.md) (`Var<T, C>`, scopes), [glossary.md](glossary.md).

## Holds

A **Hold** is a live change to how something looks or behaves on an engine: the camera, the chat, the action bar, a title, an NPC shown to one viewer. A Hold is the result of a `@Derive`: while the derive returns a Hold, the system holds it; when it returns `null` or another Hold, the system removes or reconciles it.

```kotlin
data class Speaking(@Key val step: Step, val entry: DialogueEntry, val startedAt: Instant) : Stored

@Derive
fun Speaking.show(/* inputs */): DialogueHold
```

Rules:

- **Compared by value.** An equal Hold from the next step means nothing is undone (handover).
- **Never saved.** A crash leaves nothing to undo.
- **Engine view only.** Hold derives touch attributes, packets, and the camera; they never write stored data.
- **No owner.** A Hold is not tied to a step or interaction. It exists while some derive returns it.
- **Lane is the Hold type.** There is no separate lane concept. Two things clash only when they need the same Hold type for the same holder.
- **Known before start.** Publication knows statically which Hold types a step can produce (from the step's stored values, the derives over them, and their Hold types). Clashes are therefore decided before a step starts, and checks can report them.

### Applying a Hold: handlers, not methods

A Hold has no `apply()` method. View changes are normal handlers that take the Hold type as a parameter. That parameter stays satisfied through grace and adoption, so a handover never flickers.

```kotlin
@Handler
fun Tick<EveryTick>.type(speaking: Speaking, dialogue: DialogueHold, step: Step) = ...
```

Initial sending, and sending again after a join or a server move, are handlers on `Added<H>`:

```kotlin
@Handler
fun Added<CameraHold>.spectate(player: PaperPlayer) = ...
```

### Snapshot and restore

The Hold type keeps only the code that depends on what must be put back:

- `snapshot()` runs once, on first start, and returns a stored snapshot with everything to restore (location, flight, velocity).
- `restore(snapshot)` runs once, at the end.

```kotlin
data class CameraHold(/* path, settings */) : Hold {
    override fun snapshot(): CameraSnapshot      // location, flight, velocity
    override fun restore(snapshot: CameraSnapshot)
}
```

Everything else goes into `Added<H>` and `Removed<H>` handlers. `Added<H>` handlers, `Removed<H>` handlers, and `restore` must be safe to repeat.

A `Snapshot<H>` parameter reads and updates a Hold's stored snapshot. Content uses it to change where the protagonist lands after a camera scene, so the protagonist gets one teleport instead of being sent back first.

### Lifecycle

Holds use the same lifecycle events as stored values, including `because` ([live-data.md](live-data.md#added-changed-removed-and-because)): `Added<H>`, `Removed<H>`, `Changed<H>(old, new)`.

| Event | When it fires for a Hold |
| --- | --- |
| `Added<H>` | Per live connection of the holder: first start (`Value`), server move or rejoin (`Tracking`) |
| `Removed<H>` | Per live connection: the derive stopped returning it, after grace (`Value`), or the connection closed (`Tracking`) |
| `Changed<H>(old, new)` | The derive returned a different Hold of the same type and key; when nobody handles it, it acts as remove plus add |

A live connection is a session (a Minecraft server connection, a browser tab), not a server; see [live-data.md](live-data.md). Adoption within grace fires neither `Added` nor `Removed`.

### Grace and adoption

When a derive stops returning a Hold, its removal (`Removed<H>`, then `restore`) waits a short grace: about 10 ticks (half a second) by default, set per Hold type and overridable by content. An equal Hold for the same protagonist within the grace, from any interaction, adopts it together with its snapshot. Two camera scenes back to back, or a choice inside a scene that picks the next scene, are cuts without flicker and without a restore in between.

### Keyed holds

`@Key` on a Hold field lets one holder hold many Holds of one type:

```kotlin
data class NpcView(@Key val npc: NpcEntry) : Hold   // one per NPC
```

### Priority

When several derives produce the same Hold type for the same holder and key, the highest priority wins; the priority comes from the derive's entry. A tie is a check warning. Covers legacy priority audiences and tab list priority.

### Input holds

Raw input becomes intent events such as `Confirm` only for the key the current input holder offers ([events-and-handlers.md](events-and-handlers.md#event)). The offered key shown in a hint is a `Var` field read as a plain parameter of the render handler.

### Leaving and returning

Holds need nothing special. When a connection closes, `Removed<H>` fires for it. On rejoin, derives rerun and `Added<H>` fires again.

## Runtime objects

A `Runtime` is a mutable live object on one server: never stored, closed automatically together with what created it (for example a Hold on this server), and created again after a server move through `Added<H>`. A handler creates it by returning it and uses it by asking for it as a parameter.

```kotlin
@Handler
fun Added<NpcRunning>.start(/* traits */): NpcActivity   // NpcActivity : Runtime

@Handler
fun Tick<EveryTick>.act(activity: NpcActivity) = ...
```

- Returning a `Runtime` replaces the previous one of that type for the same subject.
- A different returned value counts as a change, so everything downstream recomputes.
- A `Runtime` has a creator lifetime. Immutable live values with a demand lifetime are `Live` mirrors instead; see [live-data.md](live-data.md).

## Interactions

An **Interaction** is the running group of steps that one start produced.

### Creation and membership

- An interaction is created when a start fires into an entry that is not a member of a running interaction.
- Membership is computed at publication: every entry reachable from the start through trigger links, crossing book edges.
- When a start fires into an entry that is already a member of a running interaction, the trigger type decides whether it forwards into that interaction. Forwarding is declared by the trigger type (the extension marks it forwardable). Clicking NPC B while talking to NPC A forwards when both are in the same interaction and clashes otherwise.
- An interaction ends when no step runs and nothing is pending in any branch.

### Steps

Entries that take time are **steps**: a dialogue, a scene, a delay, a search followed by a click. Instant entries (actions) run inside the interaction without becoming steps.

Steps and interactions are identities, with a generation, so an event for a finished step is dropped. A step belongs to a group (`step.group`). Stored values keyed by a step are removed when the step ends, so step data cannot leak after a crash, a server move, or a hot publish.

A step entry's handler starts the step; whoever ends the step fires the next links:

```kotlin
@Handler
fun Triggered<DialogueEntry>.start(...) {
    startStep(context, Speaking(step, entry, startedAt = now))
}

@Handler
fun Confirm.advance(talk: Talking) {
    step.end()
    // the ender fires the next links, e.g. entry.complete(context)
}
```

The event addresses the step directly: it is the event's only `Step` field. Chains, `Triggered`, `fire`, and `complete` are explained in [events-and-handlers.md](events-and-handlers.md).

### StepState

The step rules are explicit `startStep` arguments:

```kotlin
startStep(context, marker, onClash = entry.onClash, onRejoin = entry.onRejoin)
```

A handler may hardcode them when a rule is not a creator choice; an omitted argument means the default. `startStep` stores a core `StepState(entry, context, onClash, onRejoin)` keyed by the step, because the rules must survive the protagonist being gone. The interaction has a matching `InteractionState`.

### Step markers store moments

The step marker stores only moments (`startedAt`, `skippedAt`), not counters or progress. Everything the protagonist sees is a derive over the marker plus the entry, so steps rarely write and a restart from the stored marker is a real resume. How a hot publish updates a running step (the `Speaking` derive) is in [live-data.md](live-data.md#hot-publish).

### Variants

Variants (Java chat versus a Bedrock form) are picked by the step when it starts, by adding a different stored value. There is no "most specific handler wins" rule.

### Where step handlers run

Handlers for a step that need only stored data run once, on an engine where the event happened ([events-and-handlers.md](events-and-handlers.md#where-a-handler-runs)); handlers that ask for live traits of a member run on that member's engine. There is no home engine and no single writer (decided 2026-11-03): every stored write is a realm transaction ([stored-data.md](stored-data.md#where-values-live-at-runtime)). When two engines end the same step, the generation check drops the second, and only the engine whose end committed fires the next links.

Interactions stay inside one engine kind. Engines share stored state only through the realm; live effects and events go directly between sessions ([live-data.md](live-data.md#routing)).

## Clashes

Clash rules apply at every step start, and only when the incoming step needs a Hold type that another interaction holds for the same protagonist.

| Who | Declares | Values |
| --- | --- | --- |
| Incoming step | `onClash` (a normal entry field, the default of the `startStep` argument) | `Drop` (default), `Queue`, `Replace` |
| Running step | `Protected` stored value | whole step, or a period of it |

Rules:

- `Replace` wins only against a lower inherited priority.
- `Replace` against `Protected` becomes `Queue`.
- `Replace` ends the whole running interaction, so it can simply be started again later.
- A queued step gives up through a formula, for example `waited > 10s || !protagonist.inRegion(arena)`. It also gives up when its book stops applying or its interaction ends.
- Server wide events are normal steps; the creator decides per event through the clash field.

## Leaving and rejoining

A step entry field `onRejoin` says what happens to running steps when the protagonist leaves and returns:

| Value | Effect |
| --- | --- |
| `Drop` (default) | The step ends on leave, like legacy teardown on quit |
| `RestartStep` | The stored step starts again with its stored context and a new `startedAt` |
| `RestartInteraction` | The interaction starts again from its start |

With several branches running, the strictest wins: `Drop`, then `RestartInteraction`, then `RestartStep`.

One core handler implements return, so extensions write nothing for resume:

```kotlin
@Handler
fun SessionArrived.rejoin(interaction: InteractionState, steps: All<StepState>) = ...
```

It takes the strictest `onRejoin`; `RestartStep` emits `Triggered(state.entry, state.context)` again. While the protagonist is away, live handlers simply do not apply because their parameters cannot be resolved.

A server move is a leave and a rejoin, and the step entry's `onRejoin` applies. There is no separate "continue" choice and no follow setting.

## Contexts

Interaction fields read `group`, `chain`, and `protagonist` through `InteractionContext` and `MemberContext`; see [formula-language.md](formula-language.md#formula-contexts).

## Groups

### Groupings and Membership

A **grouping** is a way to bucket protagonists, declared by a static group entry (like legacy `GroupEntry`). Core stores one value:

```kotlin
data class Membership(
    @Key val grouping: GroupEntry,
    @Key val who: Protagonist,
    val key: String,
) : Stored
```

- A group identity is (group entry, key), for example `Group(islands, "42")`. A group has stored data and derived members.
- Membership is stored, so it works offline (last known group), member lookup is an index, and the panel shows it.
- Each group entry kind keeps membership in sync with normal tools: a Skyblock plugin uses a handler on the plugin event; placeholder and world groupings use a derive. A stored derive over mirrors keeps its last result when an input vanishes by tracking, so group sync keeps the last group while offline.
- `ManualGroupEntry` changes only through the `JoinGroup` and `LeaveGroup` actions, so creators build parties with data. Party is not a Typewriter concept.
- Each group entry exports its own identity type through `bind` (`islands` gives `Island`). Formulas name the grouping, `protagonist.island`; there is no ambiguous `protagonist.group`.

### Widening

Chains start for one protagonist; widening is explicit and makes one shared interaction, not one copy per member.

```kotlin
entry.triggers.fire(context, for = group)   // default: the current subject
```

| Action entry | Effect | `group` in formulas |
| --- | --- | --- |
| `ContinueForGroup(grouping)` | Fires once per distinct group of the members | the grouping's type (`Island`) |
| `ContinueForEachMember` | One copy per member, like legacy `GroupTriggerActionEntry` | none, only `protagonist` |
| `ContinueForEveryone(who: Var<List<Protagonist>, InteractionContext>)` | Evaluates the list and creates a snapshot group keyed by the new interaction, ending with it | `Snapshot` |

Book narrowing happens inside `fire`. Which `group` type a field sees after widening is in [formula-language.md](formula-language.md#group-fields).

### Live members

Members of a group interaction are live: derived from `Membership`, which is a tracked input. A member who leaves the group drops out (their Holds are removed, per member handlers stop for them); a member who joins sees the current step because derives rerun. Snapshot groups stay fixed by design.

### Handlers with a group subject

A widened chain's events have a group subject; how handlers then iterate members is in [events-and-handlers.md](events-and-handlers.md#resolution).

### Party dialogues and leaving

- A dialogue entry has a creator field `advance: Anyone (default) | Everyone | Leader`. `Everyone` counts online members only.
- A group interaction pauses only when every member is gone. While one member stays, it keeps running; a leaving member's Holds are removed and per member handlers skip them; on rejoin their derives rerun and they see the current step.
- `onRejoin` applies only after all members left.

## Scenes

Scenes are steps whose Holds take the camera and hide the protagonist. Their feature details are decided when scenes are built (roadmap layer 18); the primitive level rules are:

- The filming protagonist is hidden by packets, not by an invisibility potion, so nothing is persisted and nothing needs restoring.
- `CameraHold` snapshots the protagonist's location, flight, and velocity, and restores them at the end. Content can overwrite the snapshot through `Snapshot<CameraHold>` to land the protagonist somewhere else with one teleport.
- While `CameraHold` is held, the formula member `protagonist.position` reads the camera position. Covers legacy `PlayerPositionOverride` in the context: the override disappears with the Hold.
- Back to back scenes adopt the camera Hold within grace, so the cut has no restore in between.
- A cinematic has the normal step entry field `onRejoin`, so the creator decides. The default is `Drop`, like legacy; `RestartStep` plays the scene again from its start.

## NPC scope

NPC scope is who holds the `NpcRunning` Hold:

| Holder | Scope |
| --- | --- |
| server | shared NPC, the same for everyone |
| group | one NPC per group |
| protagonist | one NPC per protagonist |

The running activity is a `Runtime` created on `Added<NpcRunning>` and never saved, so a restart or server move starts a fresh activity, like legacy. Per viewer display uses keyed Holds (one `NpcView` per NPC). NPC feature details are decided when NPCs are built.

## Preview and recording

Preview adds a `Simulating(mode)` stored value to the previewed step. Preview is opt out, like legacy: handlers run for real unless they check for `Simulating`.

```kotlin
@Handler
fun Added<CameraHold>.spectate(player: PaperPlayer, preview: Simulating?) = ...
```

A camera shows a preview display; a blinding effect shows nothing.

There is no content mode concept and no generic content framework. A feature that needs a running mode (capture, pick, an in game editor, recording) builds it from the primitives:

- a stored value keyed by the session is the mode; removing it ends the mode and undoes its holds;
- holds draw the mode and offer its input (input holds);
- a `Runtime` holds in progress buffers such as a recording, so a server move drops only the recording in progress;
- an authoring `edit` saves ([authoring-writes.md](authoring-writes.md));
- an event from the panel or the game ends or changes it, and its result returns to the session it came from.

Example: the region feature's own corner placing mode (nothing in it is shared with other features).

```kotlin
data class PlacingCorners(@Key val session: Session, val region: RegionEntry, val first: BlockLocation?) : Stored

@Derive
fun PlacingCorners.tool(): CornerToolHold = CornerToolHold(region, first)

@Handler
fun Confirm.place(mode: PlacingCorners, player: PaperPlayer, origin: Origin) {
    val corner = player.targetBlock().fromPlatform()
    if (mode.first == null) {
        val _ = SetFirstCorner(mode.session, corner).attempt()
        return
    }
    realm.edit(scope = AuthoringScope.resources(listOf(mode.region.target)), initiatedBy = origin.principal) {
        mode.region.draft().setShape(Cuboid(mode.first, corner))
    }
    val _ = EndPlacingCorners(mode.session).attempt()
}

@Transaction
context(tx: Transaction)
fun setFirstCorner(session: Session, corner: BlockLocation) {
    placingCorners(session).first = corner
}

@Transaction
context(tx: Transaction)
fun endPlacingCorners(session: Session) {
    placingCorners(session).clear()
}
```

Writes go through [transaction functions](stored-data.md#transaction-functions).

## Open

- Interaction bounds (blocking versus interrupting, changing over time; roadmap layer 17) are not designed yet.
- How a Hold names its holder (server, group, protagonist) in code.
- How content marks a `Protected` period inside a step.
