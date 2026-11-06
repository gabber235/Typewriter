# Interactions, holds, and runtime objects

How Typewriter runs things that take time for a protagonist: interactions and their steps, the holds they place on a protagonist's view, local runtime objects, groups, scenes, NPC scope, and preview. Product intent lives in [../vision/interactions.md](../vision/interactions.md); this file says how it works.

Related files: [overview.md](overview.md) (the primitives), [events-and-handlers.md](events-and-handlers.md) (handlers, verdicts, chains, `Triggered`), [stored-data.md](stored-data.md) (`Stored`, keys, `apply()`), [live-data.md](live-data.md) (mirrors, sessions, routing), [formula-language.md](formula-language.md) (`Var<T, C>`, scopes), [glossary.md](glossary.md).

## Holds

A **Hold** is a live change to how something looks or behaves on an engine: the camera, the chat, the action bar, a title, an NPC shown to one viewer. A Hold is the result of a `@Derive`: while the derive returns a Hold, the system holds it; when it returns `null`, the system removes it. Layer 15 rough design, decided 2026-11-05. Nothing here is built yet; see [Holds: not proven](#holds-not-proven).

### End to end

Scenario: night vision while holding a spyglass. Legacy `PotionEffectAudienceEntry.kt` adds an infinite effect, polls the strength every tick, and removes the effect at the end, which loses a night vision the player already had.

The creator builds an audience with a display under it:

```
FormulaAudienceEntry "holding_spyglass"
  criterion: protagonist.inventory.mainHand.type == minecraft.item.spyglass
  child: PotionEffectEntry
           effect:   minecraft.potionEffect.night_vision
           strength: if (protagonist.vip) 2 else 1
```

The extension declares the Hold, and a derive returns it. The entry's fields arrive as [tracked parameters](#hold-values-are-tracked-parameters).

```kotlin
data class PotionHold(
    @Key val who: Protagonist,
    @Key val effect: PotionEffectType,
    val level: Int,
) : Hold

@Derive
fun PotionEffectEntry.hold(
    who: Protagonist,
    inside: InAudience,        // the receiver fills its node key
    effect: PotionEffectType,
    strength: Int,
) = PotionHold(who, effect, strength)
```

Handlers change the game, and [snapshot handlers](#snapshot-and-restore) put back what was there.

```kotlin
@Handler
fun Added<PotionHold>.apply(effects: HasPotionEffects) = effects.set(value.effect, value.level)

@Handler
fun Changed<PotionHold>.level(effects: HasPotionEffects) = effects.set(new.effect, new.level)

@Handler
fun TakeSnapshot<PotionHold>.existing(effects: HasPotionEffects) =
    PotionSnapshot(effects.effect(value.effect))

@Handler
fun RestoreSnapshot<PotionHold>.back(effects: HasPotionEffects, snapshot: PotionSnapshot) =
    effects.set(value.effect, snapshot.existing)
```

| Moment | What happens |
| --- | --- |
| Enters the audience | `InAudience` exists, so the derive can run and `strength` becomes demanded. Writers for what the formula reads run once. The body waits until formulas settle |
| First value | `TakeSnapshot`, the snapshot is saved, then `Added` |
| `vip` changes | The formula reruns, the derive reruns, and `Changed` updates the game |
| The result stays the same | The graph stops at the formula, and the derive does not run |
| Swaps items and back within the grace | The Hold returns with the same keys, so nothing fires |
| Puts it away | The derive cannot run, so `strength` is no longer demanded. After the grace, `Removed`, then `RestoreSnapshot` |
| Server move | `Removed` on the old connection, `Added` on the new one, and no restore |
| Server crash | On rejoin the snapshot row is still there, so the [same rule](#snapshot-and-restore) applies |

Rules:

- **Same type and keys is the same Hold.** A different value with the same keys is `Changed<H>`, so a handover from the next step undoes nothing.
- **The Hold is never saved; its snapshot is.** After a crash the derive makes the Hold again, and the stored snapshot says what to put back.
- **Engine view only.** Hold derives touch attributes, packets, and the camera; they never write stored data.
- **No owner.** A Hold is not tied to a step or interaction. It exists while some derive returns it.
- **Lane is the Hold type.** There is no separate lane concept. Two things clash only when they need the same Hold type and keys.
- **Known before start.** Publication knows statically which Hold types a step can produce (from the step's stored values, the derives over them, and their Hold types). Clashes are therefore decided before a step starts, and checks can report them.

### The holder is a key

A Hold names its holder with an ordinary `@Key`, the same rule as a `Stored` value. So a parameter finds a Hold the way it finds a stored value: `ActionBarSent(player, ...)` fills the key of `ActionBarHold`, with no second lookup.

| Hold | Holder key | Reaches |
| --- | --- | --- |
| `PotionHold`, `ChatHold` | `Protagonist` | Each of the player's connections |
| `CornerToolHold` | `Session` | One connection |
| `NpcView` | `Protagonist`, plus `NpcEntry` as a second key | That viewer, one Hold per NPC |
| Shared world time | `Engine` | That server |
| `NpcRunning` | `Holder`, picked by content | [Server, group, or protagonist](#npc-scope) |

A Hold has exactly one holder key, of a type above or a `GroupIdentity`. KSP rejects zero or two. In a group step, a derive's `who: Protagonist` iterates the members, so each member gets a Hold with their own formula values.

### Hold values are tracked parameters

The Hold stores its data, and `Changed<H>` syncs it to the game. Everything a derive reads is tracked in the `TrackedGraph` ([live-data.md](live-data.md#formula-changes)), written in one of two forms:

| | Parameter: `strength: Int` | In the body: `spoken.minLines(context)` |
| --- | --- | --- |
| Use | The normal form | Only for nested values |
| What it reads | Known before the body runs, because formula reads are known at publish | Found while the body runs |
| Value not loaded yet | The body does not run, so there is no Hold | The derive gives nothing this run, and reruns when the value arrives |
| Context | Filled in | Passed by hand |
| Follows an `if` | No, it always loads | Yes |

A field is demanded only where the derive could run, so `inside: InAudience` keeps `strength` from loading for players outside the audience ([demand](live-data.md#demand)). Narrowing a watched formula to one field through `Candidate` is not needed here, because the receiver is the entry.

### Applying a Hold: handlers, not methods

A Hold has no `apply()` method. View changes are normal handlers that take the Hold type as a parameter. That parameter stays satisfied through grace and adoption, so a handover never flickers. The Hold carries the data these handlers read, so they need no other value.

```kotlin
@Handler
fun Tick<EverySecond>.resend(bar: ActionBarHold, actionBar: HasActionBar) = ...
```

Initial sending, and sending again after a join or a server move, are handlers on `Added<H>`:

```kotlin
@Handler
fun Added<CameraHold>.spectate(player: PaperPlayer) = ...
```

### Snapshot and restore

A Hold type that changes real game state declares how to put it back, through two handlers. They are handlers and not methods because a handler can ask for several small traits: a camera needs `HasLocation`, `HasFlight`, and `HasVelocity`.

```kotlin
@Handler
fun TakeSnapshot<CameraHold>.save(location: HasLocation, flight: HasFlight, velocity: HasVelocity) =
    CameraSnapshot(location.location, flight.flying, velocity.velocity)

@Handler
fun RestoreSnapshot<CameraHold>.back(location: HasLocation, flight: HasFlight, velocity: HasVelocity,
    snapshot: CameraSnapshot) = ...
```

`TakeSnapshot<H>` allows one handler, because its return value is the snapshot. A `RestoreSnapshot<H>` handler receives that value as a parameter. A Hold with no `TakeSnapshot` handler, such as a sidebar, has no row and nothing to restore.

The stored snapshot row decides everything, so a crash has no path of its own:

| Moment | Rule |
| --- | --- |
| Hold starts | No row: `TakeSnapshot`, save it, then `Added`. A row exists: only `Added` |
| Hold ends and the holder is here | Grace, then `Removed`, then `RestoreSnapshot`, then the row is deleted |
| Rejoin after a crash | The row exists, and a grace starts. A Hold with the same keys returns: keep the row and do not restore. No Hold: `RestoreSnapshot` |
| Hold ended while offline | The same as a rejoin after a crash |
| No connection provides the traits | Nothing runs and the row stays, for example while the player has only a browser tab open. The rule applies when a connection that fits appears |

Everything else goes into `Added<H>` and `Removed<H>` handlers. `Added<H>` handlers, `Removed<H>` handlers, and `RestoreSnapshot<H>` handlers must be safe to repeat.

A `Snapshot<H>` parameter reads and updates a Hold's stored snapshot. Content uses it to change where the protagonist lands after a camera scene, so the protagonist gets one teleport instead of being sent back first.

### Lifecycle

Holds use the same lifecycle events as stored values, including `because` ([live-data.md](live-data.md#added-changed-removed-and-because)): `Added<H>`, `Removed<H>`, `Changed<H>(old, new)`.

| Event | When it fires for a Hold |
| --- | --- |
| `Added<H>` | First start (`Value`), server move or rejoin (`Tracking`) |
| `Removed<H>` | The derive stopped returning it, after grace (`Value`), or the connection closed (`Tracking`) |
| `Changed<H>(old, new)` | The derive returned a different Hold of the same type and keys; when nobody handles it, it acts as remove plus add, with no snapshot handlers |

The usual parameter rule decides how often a handler runs. A handler that asks for a trait runs once per live connection of the holder. A live connection is a session (a Minecraft server connection, a browser tab), not a server; see [live-data.md](live-data.md). A handler that asks for no trait runs once per engine, so a shared NPC starts one activity, not one per player:

```kotlin
fun Added<SidebarHold>.show(view: HasSidebar) = ...   // once per connection
fun Added<NpcRunning>.start(): NpcActivity = ...      // once per engine
```

Adoption within grace fires neither `Added` nor `Removed`.

### Grace and adoption

When a derive stops returning a Hold, its removal (`Removed<H>`, then `RestoreSnapshot<H>`) waits a short grace: about 10 ticks (half a second) by default, set per Hold type and overridable by content. A Hold of the same type and keys within the grace, from any interaction, adopts it together with its snapshot. Two camera scenes back to back, or a choice inside a scene that picks the next scene, are cuts without flicker and without a restore in between. A rejoin gets the same grace before a stored snapshot is restored.

For a Hold from a `Running`, the grace starts only when that interaction's chain has settled: `complete` began and every event it fired is done. Until then the Hold still blocks and counts as protected, so a queued step cannot jump between two steps of one chain.

### Keyed holds

`@Key` fields beyond the holder let one holder hold many Holds of one type:

```kotlin
data class NpcView(@Key val viewer: Protagonist, @Key val npc: NpcEntry) : Hold   // one per NPC
```

### Priority

When several derives produce the same Hold type and keys, the highest priority wins; the priority comes from the derive's entry. A tie is a check warning. Covers legacy priority audiences and tab list priority.

### Input holds

A Hold is for the input a step actually uses, not for input in general: `HotbarScrollHold` for the wheel, while keys are offers that do not clash. See [dialogue.md](dialogue.md).

### Leaving and returning

When a connection closes, `Removed<H>` fires for it. On rejoin, derives rerun and `Added<H>` fires again. A Hold with a snapshot follows [the snapshot rule](#snapshot-and-restore).

### Displays in this layer

Each one proves a different part of the design. Legacy has 16 displays and 17 filters; the filters became formulas ([live-data.md](live-data.md#audiences)).

| Display | Proves | Reaches the game through |
| --- | --- | --- |
| Sidebar, with its lines | A tracked value, then `Changed` | Our wire ([packets.md](packets.md)) |
| Boss bar | Many Holds per player, through `@Key` | Adventure `showBossBar` |
| Tab list header and footer | Priority between entries | Paper `sendPlayerListHeaderAndFooter` |
| Potion effect | Snapshot, restore, and rejoin after a crash | Paper's API |
| Action bar | A verdict that reads a Hold and blocks other plugins | Adventure and our wire |
| Title | A short Hold that ends itself | Adventure |

| Later | Goes to |
| --- | --- |
| Weather, freeze time, experience | Conversion track, small once core exists |
| Particle | Layer 25, with `RegionOutlineHold` |
| Fake block, looping cinematic | Layer 18 |
| Compass, quest item, item slot binder | Layer 23 |
| Timer | No Hold: `Due` from layer 7 |
| Trigger | No Hold: enter and exit entries from layer 8 |

A display is a node in the audience tree, so it has its own `InAudience`, and a display at the root reaches everyone. It has no `criterion` field, which counts as true.

### Holds: not proven

- **Nothing ran.** All Kotlin here is a sketch, and `TrackedGraph` exists only in design records, not in `services/` or `backend/`.
- **Slow loading.** If a formula's values take longer than the grace on rejoin, the restore fires too early and then the Hold returns. The grace may need to start once formulas settle, and a formula that never gets a value then needs a limit.
- **Restore on another server.** A saved location may name a world that server does not have.
- **Restore order.** Two Holds touching the same game state restore in an unknown order.
- **The snapshot row's shape.** Its key holds the Hold's type and keys. A key that is an entry ends with the entry, which would delete the row with no restore.
- **Cost.** Each start of a Hold with a snapshot is one realm write. A value that changes every tick reruns the derive every tick.
- **`NpcRunning` with `Holder` as its key.** The build cannot check which holder content picks. A group held NPC with members on two servers runs once on each. Layer 21 confirms both.
- **A display with no `criterion`.** `AudienceEntry.inside` must treat that as true, which is a small change to the audience design.
- **Many small traits.** The engine object implements them all. How an extension adds its own trait for an identity is not designed.

## Runtime objects

A `Runtime` is a mutable live object on one server: never stored, closed automatically together with what created it (for example a Hold on this server), and created again after a server move through `Added<H>`. A handler creates it by returning it and uses it by asking for it as a parameter.

```kotlin
@Handler
fun Added<NpcRunning>.start(): NpcActivity   // NpcActivity : Runtime

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
- An interaction ends when it has no `Running` or `Queued` row left and its chain has settled. Core then clears `InteractionStart`.
- Newest wins among siblings in one interaction: a forwarded click replaces the current dialogue, as legacy.

### Steps

Entries that take time are **steps**: a dialogue, a scene, a delay, a search followed by a click. Instant entries (actions) run inside the interaction without becoming steps.

Firing into a `StepEntry` starts it. An extension writes no start code, no marker type, and no generation. Each start gets a new unique `Step` id, so a late event finds nothing.

```kotlin
interface StepEntry : Triggerable { val rules: StepRules }

@TypewriterType(id = "...")
data class StepRules(
    val onClash: OnClash = OnClash.Drop,
    val onRejoin: OnRejoin = OnRejoin.Drop,
    val protected: Var<Boolean, StepContext> = Var.Value(false),
    val giveUp: Var<Boolean, QueuedContext> = Var.Value(false),
)

enum class OnClash { Drop, Queue, Replace }
enum class OnRejoin { Drop, RestartStep, RestartInteraction }

interface StepContext : MemberContext { val elapsed: Duration }
interface QueuedContext : MemberContext { val waited: Duration }

// Most creators never open this. giveUp is hidden when the entry can never queue.
object StepRulesInspector : StepRulesPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)
    override val group = FieldGroup("step", "Interruptions", collapsed = true)
    override fun StepRulesPresentationScope.present() {
        onClash.input()
        showIf(onClash.read() eq literal(OnClash.Drop), whenFalse = { giveUp.input() }) {}
        onRejoin.input()
        protected.input()
    }
}

@JvmInline value class Step(val id: UUID) : Identity
@JvmInline value class Interaction(val id: UUID) : Identity

// Protagonist, Session, GroupIdentity, and Engine are holders.
interface Holder : Identity

data class Running<E : StepEntry>(
    @Key val step: Step,
    val interaction: Interaction,
    val entry: E,
    val subject: Holder,
    val context: ChainContext,
    val startedAt: Instant,
) : Stored {
    val elapsed: Duration get() = now - startedAt
}

data class Queued<E : StepEntry>(
    @Key val step: Step,
    val interaction: Interaction,
    val entry: E,
    val subject: Holder,
    val context: ChainContext,
    val queuedAt: Instant,
) : Stored

data class InteractionStart(
    @Key val interaction: Interaction,
    val entry: StepEntry,
    val context: ChainContext,
) : Stored
```

What an extension writes for the smallest step:

```kotlin
class SpokenDialogueEntry(
    /* page, name, placement, triggers, refused, changes */
    override val rules: StepRules = StepRules(),
    val text: Var<RichText, MemberContext>,
) : StepEntry

@Derive fun Running<SpokenDialogueEntry>.chat(who: Protagonist) = ChatHold(who)

@Handler suspend fun Confirm.advance(running: Running<SpokenDialogueEntry>) = running.complete()
```

How a `Running<E>` parameter resolves:

| Handler | Runs for |
| --- | --- |
| Event with a `Step` field | That step, if its entry is an `E` |
| Protagonist subject, no `Step` field | One run per step of type `E` they are in |
| `who: Protagonist` on a `Running` derive | Each member of `subject`, through the group rule |

Other steps use the same row:

| Need | Code |
| --- | --- |
| A scene ends | `Tick<EveryTick>` comparing `running.elapsed` with its length |
| A delay | `Added<Running<DelayEntry>>` writes `DelayDue(step, at) : Due`, and `Elapsed<DelayDue>` completes the step |
| A search and a click | An event handler that takes `Running<E>` and completes it |
| A skip | `Skipped(@Key step, at) : Stored`, removed with the step |
| A preview | `Simulating(@Key step) : Stored` |

Stored values keyed by a step are removed when the step ends, so step data cannot leak after a crash, a server move, or a hot publish. Everything the protagonist sees is a derive over `Running` plus its entry, so a hot publish updates a running step in place ([live-data.md](live-data.md#hot-publish)).

### Ending a step

```kotlin
@Transaction context(tx: GuardedTransaction)
fun completeStep(step: Step) {
    require(running(step).exists(), "Already ended")
    running(step).clear()
}

suspend fun Running<*>.complete(
    links: List<Triggerable> = listOf(entry),
    context: ChainContext = this.context,
) {
    when (CompleteStep(step).ensure()) {
        Committed -> links.forEach { it.complete(context) }
        is Refused -> Unit
    }
}

fun Running<*>.end()   // no links
```

The guard is what makes a double press safe: the second press is refused and fires nothing.

### Variants

Variants (Java chat versus a Bedrock form) are picked by the step when it starts, by adding a different stored value. There is no "most specific handler wins" rule.

### Where step handlers run

Handlers for a step that need only stored data run once, on an engine where the event happened ([events-and-handlers.md](events-and-handlers.md#where-a-handler-runs)); handlers that ask for live traits of a member run on that member's engine. There is no home engine and no single writer (decided 2026-11-03): every stored write is a realm transaction ([stored-data.md](stored-data.md#where-values-live-at-runtime)). When two engines end the same step, the generation check drops the second, and only the engine whose end committed fires the next links.

Interactions stay inside one engine kind. Engines share stored state only through the realm; live effects and events go directly between sessions ([live-data.md](live-data.md#routing)).

## Clashes

The step system does not limit anyone to one at a time. Any number of steps and interactions run together. Two clash only when they need the same Hold type for the same protagonist. Only a `Hold` returned by a derive on `Running<E>` counts; a `Live` value from a step never clashes.

An incoming step counts every Hold type its derives can return. A running step counts what it holds now, so a released Hold can be taken. If a step later wants a Hold that someone took, its own `onClash` applies.

```kotlin
@JvmInline value class HoldType(val id: TypeDefinitionId)

data class HeldBy(val interaction: Interaction, val priority: Int, val protected: Boolean)

// Written by core at tick end.
data class Held(
    @Key val who: Protagonist,
    val holds: Map<HoldType, HeldBy>,
    val settled: Set<Step>,
) : Live

fun holdTypes(entry: StepEntry): Set<HoldType>   // from KSP: Hold return types of derives on Running<E>

fun blockers(
    held: List<Held>,
    mine: List<Running<*>>,
    types: Set<HoldType>,
    self: Interaction,
): List<HeldBy> {
    val now = held.flatMap { h -> types.mapNotNull { h.holds[it] } }
    val starting = mine.filter { row -> held.none { row.step in it.settled } }
        .filter { (holdTypes(it.entry) intersect types).isNotEmpty() }
        .map { HeldBy(it.interaction, it.entry.priority, protected = true) }
    return (now + starting).filter { it.interaction != self }.distinct()
}

sealed interface Decision {
    data object Begin : Decision
    data object Drop : Decision
    data object Queue : Decision
    data class Replace(val ended: List<Interaction>) : Decision
}

fun decideClash(rules: StepRules, priority: Int, others: List<HeldBy>, ahead: Boolean): Decision {
    if (others.isEmpty() && !ahead) return Decision.Begin
    return when (rules.onClash) {
        OnClash.Drop -> Decision.Drop
        OnClash.Queue -> Decision.Queue
        OnClash.Replace -> when {
            others.isEmpty() || others.any { it.protected } -> Decision.Queue
            others.any { it.priority >= priority } -> Decision.Drop
            else -> Decision.Replace(others.map { it.interaction }.distinct())
        }
    }
}

@Handler
fun <E : StepEntry> Triggered<E>.start(
    held: List<Held>,
    mine: List<Running<*>>,
    waiting: List<Queued<*>>,
) {
    val interaction = chain.interaction ?: forwardInto(mine) ?: Interaction(uuid7())
    val step = Step(uuid7())
    val types = holdTypes(entry)
    val others = blockers(held, mine, types, interaction)
    val ahead = waiting.any {
        it.interaction != interaction && (holdTypes(it.entry) intersect types).isNotEmpty()
    }
    val row = Running(step, interaction, entry, subject, context, now)
    val _ = when (val decision = decideClash(entry.rules, entry.priority, others, ahead)) {
        Decision.Begin -> BeginStep(row, siblingsOf(mine, types, interaction))
        Decision.Queue -> QueueStep(Queued(step, interaction, entry, subject, context, now))
        is Decision.Replace -> ReplaceAndBegin(decision.ended, row)
        Decision.Drop -> return
    }.attempt()
}

@Transaction context(tx: Transaction)
fun beginStep(row: Running<*>, siblings: List<Step>) {
    siblings.forEach { running(it).clear() }
    interactionStart(row.interaction).setIfAbsent(InteractionStart(row.interaction, row.entry, row.context))
    running(row.step).set(row)
}

@Transaction context(tx: Transaction)
fun queueStep(row: Queued<*>) {
    interactionStart(row.interaction).setIfAbsent(InteractionStart(row.interaction, row.entry, row.context))
    queued(row.step).set(row)
}

@Transaction context(tx: Transaction)
fun replaceAndBegin(ended: List<Interaction>, row: Running<*>) {
    ended.forEach { interactionStart(it).clear() }   // its steps end with the identity
    interactionStart(row.interaction).setIfAbsent(InteractionStart(row.interaction, row.entry, row.context))
    running(row.step).set(row)
}
```

Rules:

- `Replace` wins only against a lower priority, and ends the whole running interaction, so it can simply be started again later.
- `Replace` against a protected step becomes `Queue`.
- `protected` is a formula on the step, read while it runs (`elapsed` is in its context). It covers only what the step holds now.
- A step's chain stays protected until it settles. See the [grace rule](#grace-and-adoption).
- Server wide events are normal steps; the creator decides per event through the clash field.

### Groups

A group step is all or nothing. It guarantees everyone in the group sees it at the same time, so one person holding out holds it out for everyone.

- **Blockers** are the union over all online members.
- **`Drop`** drops it whole. **`Queue`** waits until all are free. **`Replace`** ends each blocking interaction, unless one is protected or not lower.
- **To decide per person**, trigger for individuals with `ContinueForEachMember`.

### The queue

```kotlin
fun decideQueued(row: Queued<*>, others: List<HeldBy>): Decision = when {
    others.isEmpty() -> Decision.Begin
    row.entry.rules.onClash != OnClash.Replace -> Decision.Queue
    others.any { it.protected } -> Decision.Queue
    others.any { it.priority >= row.entry.priority } -> Decision.Queue
    else -> Decision.Replace(others.map { it.interaction }.distinct())
}

data class Ready(@Key val step: Step, val decision: Decision) : Live

// Reruns on any change of Held, so a queue also moves when a blocker stops being protected.
@Derive
fun Queued<*>.ready(held: List<Held>, mine: List<Running<*>>, waiting: List<Queued<*>>): Ready? {
    val types = holdTypes(entry)
    val older = waiting.any {
        it.queuedAt < queuedAt && (holdTypes(it.entry) intersect types).isNotEmpty()
    }
    if (older) return null
    val decision = decideQueued(this, blockers(held, mine, types, interaction))
    return if (decision == Decision.Queue) null else Ready(step, decision)
}

@Handler
fun Added<Ready>.begin(row: Queued<*>) {
    val _ = when (val decision = value.decision) {
        Decision.Begin -> BeginQueued(row)
        is Decision.Replace -> ReplaceAndBeginQueued(decision.ended, row)
        else -> return
    }.attempt()
}

@Transaction context(tx: Transaction)
fun beginQueued(row: Queued<*>) {
    queued(row.step).clear()
    running(row.step).set(Running(row.step, row.interaction, row.entry, row.subject, row.context, now))
}

@Transaction context(tx: Transaction)
fun replaceAndBeginQueued(ended: List<Interaction>, row: Queued<*>) {
    ended.forEach { interactionStart(it).clear() }
    queued(row.step).clear()
    running(row.step).set(Running(row.step, row.interaction, row.entry, row.subject, row.context, now))
}

// waited reads now, so this rechecks on the timer.
data class GaveUp(@Key val step: Step) : Live
// A step whose book no longer applies leaves too (book-composition.md).
@Derive
fun Queued<*>.gaveUp(context: QueuedContext) =
    if (entry.rules.giveUp(context) || !entry.appliesTo(subject)) GaveUp(step) else null

@Handler
fun Added<GaveUp>.leave(row: Queued<*>) {
    val _ = LeaveQueue(row.step).attempt()
}

@Transaction context(tx: Transaction)
fun leaveQueue(step: Step) {
    queued(step).clear()
}
```

- A queued step never drops: it begins, replaces, or waits. Only `giveUp` removes it, for example `waited > 10s || !protagonist.inRegion(arena)`. It also ends when its book stops applying or its interaction ends.
- The oldest queued step for a Hold type goes first, whatever its priority.

### Clashes: not proven

Nothing compiled or ran.

- **Accessor forms.** `running(step).exists()` and `setIfAbsent` on these rows are assumed.
- **Ending an interaction's rows.** "Its steps end with the identity" needs `interaction` as a key of `Running` and `Queued`, or a listing in the transaction. The plan decides.
- **Settled across engines.** A group chain on one engine, a Hold on another.
- **`Held` for `Session` and `Engine` holders.** An `Engine` subject has no `who` to iterate, so only `server: Engine` derives run. First use is layer 18 or 21.
- **`protected` always watched** while a step runs, and queued priority read at decision time.
- **A generic stored index by `E`**, and an entry deleted while running (core ends the step with no links).
- **Chain settle** needs a counter across guard waits.
- **Static needs are cautious.** A camera used only at minute 5 clashes at the start.
- **Realm latency** on every step start, skip, and end.

## Leaving and rejoining

The step rule `onRejoin` says what happens to running steps when the protagonist leaves and returns:

| Value | Effect |
| --- | --- |
| `Drop` (default) | The step ends on leave, like legacy teardown on quit |
| `RestartStep` | The step starts again with its stored context, a new `Step`, and a new `startedAt` |
| `RestartInteraction` | The interaction starts again from its start |

With several branches running, the strictest wins: `Drop`, then `RestartInteraction`, then `RestartStep`.

One core handler implements return, so extensions write nothing for resume:

```kotlin
@Handler
fun SessionArrived.rejoin(steps: List<Running<*>>, starts: List<InteractionStart>) = ...
```

It takes the strictest `entry.rules.onRejoin`; `RestartStep` fires `Triggered(row.entry, row.subject, row.context)` again, which makes a new `Step` id. While the protagonist is away, live handlers simply do not apply because their parameters cannot be resolved.

A server move is a leave and a rejoin, and the step's `onRejoin` applies. There is no separate "continue" choice and no follow setting.

## Contexts

Interaction fields read `group`, `chain`, and `protagonist` through `InteractionContext` and `MemberContext`; see [formula-language.md](formula-language.md#formula-contexts).

## Groups

### Groupings and Membership

A **grouping** is a way to bucket protagonists by a key: island 42, team red. Decided 2026-11-05 in the layer 11 rough design. There are two kinds of group entry, because there are two ways to land in a group: outside facts decide it, or something assigns you.

The entry's picked type argument `K` decides everything (decided 2026-11-05), chosen with the same editor as `Definition<T>`. `X` means one group per player, and `List<X>` means several. `X` can be a creator type, such as a union.

```kotlin
interface GroupEntry<K> : StaticEntry

// Outside facts decide: the formula is checked against K. With X?, null means in no group.
@TypewriterType(id = FORMULA_GROUP_ENTRY_TYPE_ID)
class FormulaGroupEntry<K>(/* page, name, placement */ val key: Var<K, MemberContext>) : GroupEntry<K>

// Something assigns you, through the JoinGroup and LeaveGroup actions.
@TypewriterType(id = MANUAL_GROUP_ENTRY_TYPE_ID)
class ManualGroupEntry<K>(/* page, name, placement */) : GroupEntry<K>

// X is bound from the group's K.
class JoinGroupEntry<X>(
    /* page, name, placement, triggers */
    val group: Ref<ManualGroupEntry<*>>,
    val key: Var<X, MemberContext>,
) : ActionEntry

class LeaveGroupEntry<X>(
    /* page, name, placement, triggers */
    val group: Ref<ManualGroupEntry<*>>,
    val key: Var<X?, MemberContext>,   // null: every group of this entry
) : ActionEntry
```

A group identity says what members belong to. Our two entries use `EntryGroup`; the entry is part of the identity, so deleting the entry ends all its groups, and the [owner rule](stored-data.md#owners-and-lifetime) removes their memberships and everything keyed by them. Other group identities are not tied to an entry.

```kotlin
interface GroupIdentity : Identity

data class EntryGroup<X>(val entry: GroupEntry<*>, val key: X) : GroupIdentity

// ContinueForEveryone. Ends with the interaction.
data class Snapshot(val interaction: Interaction) : GroupIdentity

// One row per group, so everything that reads a group works the same way.
data class Membership(@Key val who: Protagonist, @Key val group: GroupIdentity) : Stored
```

The rows of one kind are found through the existing per key index: `Membership.all(who)` gives a player's groups, and `Membership.all(group)` gives a group's members.

```kotlin
// ManualGroupEntry: the actions write it. With one, joining moves you.
// The realm reruns a transaction on a conflict, so two joins at once leave one row.
@Transaction
fun join(entry: ManualGroupEntry<*>, who: Protagonist, key: Any) {
    if (!entry.isMany) memberships(who, entry).forEach { it.clear() }
    Membership(who, EntryGroup(entry, key)).set()
}

// FormulaGroupEntry: core compares with what is stored, not with the old formula value,
// because the formula can differ after a rejoin. keys() makes a Set from X? or a List,
// so one and many are the same code.
@Handler
fun Added<Watched<K>>.sync(group: Candidate<FormulaGroupEntry<K>>, who: Protagonist) =
    syncMemberships(group.entry, who, value.keys())

@Handler
fun Changed<Watched<K>>.sync(group: Candidate<FormulaGroupEntry<K>>, who: Protagonist) =
    syncMemberships(group.entry, who, new.keys())

@Transaction
fun syncMemberships(entry: GroupEntry<*>, who: Protagonist, keys: Set<Any>) {
    val stored = memberships(who, entry).map { it.group.key }.toSet()
    (stored - keys).forEach { Membership(who, EntryGroup(entry, it)).clear() }
    (keys - stored).forEach { Membership(who, EntryGroup(entry, it)).set() }
}
```

A formula never looks at the player to learn one or many. `exports` reads `K`, so the reader's type is known while editing, and the writers and migrations keep the rows valid:

```
protagonist.party.bank                       // K = String: a Party, with no value when in no group
protagonist.party.any { it.bank > 5 }        // K = List<String>: a List<Party>
```

Inside a widened chain `group` is always one group, so `bank += 1` works the same for both.

The key must be stable, or stored data leaks. One ordinary realm check walks the type, with no list of allowed classes. A catalog bound cannot express this: bounds read through parents, and a scalar or a creator union has none.

```kotlin
fun TypeUse.isStableKey(seen: Set<TypeUse> = emptySet()): Boolean = when (this) {
    is Scalar -> kind !is FloatScalar
    is Nullable -> value.isStableKey(seen)
    is Named -> when {
        isA(Identity) || isA(DomainValue) -> true
        isCollection || this in seen -> false
        else -> fields.all { it.type.isStableKey(seen + this) }   // records, and every union case
    }
}

each(GroupEntryDraft) { entry ->
    if (!entry.element.isStableKey()) report("A group key must be stable", at = entry.typeArgument)
}
```

So `String`, an enum, `World`, `Protagonist`, and `union { Guild(name: String), Solo }` pass. `Position` fails because it holds a `Double`, and an item fails because it holds lists. The check runs through the query graph, so editing a union later reports it on the group entry and blocks publishing. The panel's type picker offers everything for now and shows this error.

Changing `K` reuses [migrations](migrations.md#group-entries).

- A group has stored data and derived members. `Island` is the type `islands` exports for its `EntryGroup`, so two group entries with the same key type are still different types. It has `.key` and `.members`.
- Membership is stored, so it works offline (last known group), member lookup is an index, and the panel shows it. Going offline is `Removed` with `because = Tracking`, which the sync handler ignores, so a formula group keeps the last groups while offline.
- One for a party where joining another moves you; many for overlapping regions or several guilds. Joining a group you are already in changes nothing.
- `Ref<ManualGroupEntry<*>>` means `JoinGroup` cannot point at a formula group; the panel only offers manual ones.
- Party is not a Typewriter concept; creators build parties with a manual group.
- Each group entry exports its own identity type through `bind` (`islands` gives `Island`). Formulas name the grouping, `protagonist.island`; there is no ambiguous `protagonist.group`.
- Anything else about a group, such as an island's name, is a provider or a variable keyed by the group, unless it belongs in the key type.

Every legacy group is one of these:

| Legacy | Now |
| --- | --- |
| `WorldGroupEntry` | Formula group with `K = World`: `protagonist.world` |
| `PlaceholderGroupEntry` | Formula group: `papi("%team%")` |
| `BalanceGroupEntry` | Formula group: `if (protagonist.balance > 1000) "rich" else "poor"` |
| A plugin's group | Formula group over a mirror the plugin's extension supplies |
| `GlobalGroupEntry` | A variable with no keys, or a formula group with key `"all"` |
| `PlayerGroupEntry` | No group: a variable keyed by protagonist |

An extension only supplies a value, with no group code:

```kotlin
data class TeamId(@Key val protagonist: Protagonist, val value: String) : Live

@Handler
fun Tick<EverySecond>.teamId(player: PaperPlayer, teams: TeamPlugin): TeamId? =
    teams.teamOf(player)?.let { TeamId(player.protagonist, it.id) }
```

A mirror updates at its poll rate. An extension that needs a change at once adds an event writer, as any mirror can.

| Case | What happens |
| --- | --- |
| Formula key becomes null | The player leaves. Their handlers stop, and the data stays with the group. |
| Formula key edited | Online players move at once. Offline ones stay until they return. |
| Everyone in a group offline | Its data stays, because it is keyed by the group. |
| Members on two servers | Per member handlers run on each member's own engine. |
| Reading a group with none | With one, `protagonist.island` has no value; `.orNull` handles it, as with mirrors. With many, the list is empty. |
| `ContinueForGroup` for a player in two groups | It fires once per group, so both groups run it. |
| Panel edit of a group value | With one, it goes to the player's group, or last group when offline. With many, the panel must ask which; not designed. |
| Group entry deleted | All its groups end: memberships and values keyed by them are removed. A variable keyed by its type and a `JoinGroup` pointing at it are errors that block publishing until fixed. |
| Leaving a group you are not in | Nothing happens. |

Not proven: `dynamic()` and `bind` are not built, and `bind` is planned after groups, so the layer order needs checking in the plan; how a key of any allowed type is written as a stable row key; narrowing a watched formula to one entry is already open for the plan; which engine writes when a key reads a mirror and a player is held by two engines; the cost of one watched formula per online player per formula group.

### Widening

Chains start for one protagonist; widening is explicit and makes one shared interaction, not one copy per member.

```kotlin
entry.triggers.fire(context, for = group)   // default: the current subject
```

| Action entry | Effect | `group` in formulas |
| --- | --- | --- |
| `ContinueForGroup(grouping)` | Fires once per distinct group of the members | the grouping's type (`Island`) |
| `ContinueForEachMember(who: Var<List<Protagonist>, InteractionContext>)` | One copy per listed member, like legacy `GroupTriggerActionEntry`, each deciding its own clashes | none, only `protagonist` |
| `ContinueForEveryone(who: Var<List<Protagonist>, InteractionContext>)` | Evaluates the list and creates a snapshot group keyed by the new interaction, ending with it | `Snapshot` |

Book narrowing happens inside `fire`; a group is never rewritten, and a member a book does not apply to only loses their view. A condition turning false mid interaction stops the part from that book at once ([book-composition.md](book-composition.md#7-stopping)). Which `group` type a field sees after widening is in [formula-language.md](formula-language.md#group-fields).

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
- `CameraHold` takes a snapshot of the protagonist's location, flight, and velocity, and restores them at the end. Content can overwrite the snapshot through `Snapshot<CameraHold>` to land the protagonist somewhere else with one teleport.
- While `CameraHold` is held, the formula member `protagonist.position` reads the camera position. Covers legacy `PlayerPositionOverride` in the context: the override disappears with the Hold.
- Back to back scenes adopt the camera Hold within grace, so the cut has no restore in between.
- A cinematic has the normal step rule `onRejoin`, so the creator decides. The default is `Drop`, like legacy; `RestartStep` plays the scene again from its start.

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
fun PlacingCorners.tool(): CornerToolHold = CornerToolHold(session, region, first)

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
