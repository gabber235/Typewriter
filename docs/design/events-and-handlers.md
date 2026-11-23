# Events and handlers

How something that happens (a click, a chat message, a tick, a fired link) reaches code, how that code decides or reacts, and how chains of entries follow from it.

The seven primitives are summarized in [overview.md](overview.md). Stored values, keys, and transactions are in [stored-data.md](stored-data.md); mirrors, demand for mirrors, sessions, and routing between engines are in [live-data.md](live-data.md); holds, steps, interactions, and groups are in [interactions.md](interactions.md); formulas and `Var<T, C>` are in [formula-language.md](formula-language.md). Every term is listed in [glossary.md](glossary.md).

## Event

An event is a plain Kotlin type that says one thing happened. Extensions declare their own events next to the types they use (common code, or the capability that owns those types). Every event is a Typewriter type, `@TypewriterType(id = ...)` like any value type, so it crosses engines as its catalog value and an engine with the class decodes it through its binding; every field must therefore be a Typewriter type, which KSP enforces.

- **One event type per meaning.** What a particular delivery may do (decide, change, which thread it is on) is typed on the source, not on the event.
- **Meaning decides how many events exist.** A change with a different effect at the packet than at the Paper event is two events: `ClientPosition` is a fake view on the wire, `PlayerMove` really moves the player. The same effect (`ArmSwing`) is one event: the first source starts the occurrence, the others join it. Nothing may rely on the packet arriving before the Paper event.
- **Raw input becomes intent events.** A raw key press becomes `Confirm` only when it is the key currently offered ([dialogue.md](dialogue.md#6-the-key)), so a raw key is only taken when it is the offered key. Input with one holder, like the hotbar wheel, needs no intent event: its handlers take the raw event.
- **Subject.** Most events have a subject (usually a protagonist; a widened chain has a group). Events without a subject (`Tick`, world events) turn handler parameters into a query, see [Events without a subject](#events-without-a-subject).
- **Engine neutral core.** `Tick` is a capability, not core. Core events say protagonist, never player (`ProtagonistJoined`). `Player` is only a Minecraft capability trait or part of a Minecraft event name (`PlayerMove`).

Lifecycle events are ordinary events with the same handler rules: `Added<T>`, `Removed<T>`, `Changed<T>(old, new)` fire for every stored value ([stored-data.md](stored-data.md)), hold ([interactions.md](interactions.md)), mirror, and watched formula ([live-data.md](live-data.md)). `Due` is in [stored-data.md](stored-data.md).

### Emitting

Events without a source are emitted by handlers. `emit()` queues: the emitted event is decided after the current event finishes. There is no nesting.

An emitted event runs locally when this engine holds a session of the subject, and is published to the protagonist subject only when another engine holds one too (decided 2026-11-03). Whether this engine holds a session is its own session keeper's knowledge (sessions it reported and still has), so it works while NATS is down; events the keeper fires itself skip the check (decided 2026-11-22). Each engine keeps a local copy of the `sessions` bucket through a KV watch to know whether another engine holds one too (node 9). A normal chain therefore never touches NATS and keeps working while NATS is down. An engine that holds no session of the subject only publishes, and runs none of its own handlers for it. An offline subject drops the event. An engine skips its own published events. Source events follow the same rule: a source event decides inline, and when another engine also holds the subject it is forwarded as an ordinary delivery, which that engine decides for itself. Events without a subject are always local.

```kotlin
@Handler
fun PlayerChat.detectGreeting() {
    if (message.startsWith("hello")) emit(Greeted(protagonist))
}
```

A handler that emits a narrower event is a filter. Together with subscribed events this covers filtering without a separate filter concept.

### Order

There is no order among handlers reacting to the same event (stable in practice, not promised). Order between events comes from the queue. Across engines, order is per identity in commit order ([live-data.md](live-data.md)).

## Source

A source turns something outside Typewriter (a Paper event, a packet, a timer) into events. Sources are lazy: a source only produces what some handler could actually run for. That is the same notion of demand used for mirrors ([live-data.md](live-data.md)).

### Writing a source

A source is a class implementing an engine neutral interface; the engine it runs on supplies a helper for its own event system (decided 2026-11-03). No generator knows Paper.

```kotlin
fun interface Source<E : Event> : EnginePart {
    fun open(sink: Sink<E>): AutoCloseable
}

interface Sink<E : Event> {
    fun decide(event: E, origin: Origin?, apply: (Outcome<E>) -> Unit = {})
}
```

The Paper engine's `PaperEvents` turns most Paper events into a source with only the conversion left to write:

```kotlin
class BlockBreakSource(paper: PaperEvents) : Source<BlockBreak> by
    paper.source<BlockBreakEvent, BlockBreak> { BlockBreak(player.protagonist) }
```

- `source` listens, decides, and cancels the Paper event on deny. It defaults to `ignoreCancelled = true`. The conversion returns `null` when the event does not apply. A deny on an event Paper cannot cancel logs a warning once.
- `origin` comes from the event's subject: a Minecraft session id is the UUID, so the protagonist gives the session.
- A `change` verdict is applied with `apply = { damage = it.event.damage }`, read from `outcome.event`.
- `PaperEvents.listen` is the fallback for unusual cases, such as a cause that is not the subject.
- `PaperEvents.own(player) { ... }` marks a game change as Typewriter's own: a Paper event raised inside the block, for that player, reaches the conversion with `own` true, and a source returns `null` for it. Other plugins still see the Paper event. The block is not suspending, so the mark covers exactly the call that raises the event. The same rule as `wire.send` for packets ([packets.md](packets.md#5-typewriters-own-packets-get-through)); first use is the camera's body follow ([scenes.md](scenes.md#5-typewriters-own-moves)).

| Detail | Who does it |
| --- | --- |
| Opening on the first runnable handler, closing after the last, recomputed on publish | event runtime |
| Occurrence id, running verdicts inline, merging the outcome | `Sink` |
| Applying the outcome | the `apply` block; follow ups and after handlers run once it ends |
| Forwarding to other holders, dropping when the subject has no session | `Sink` |

A verdict handler that throws counts as `pass` and is logged. Packet sources and their dedupe arrive with the [packet layer](packets.md) (14). A test can use a small test source with a real `Sink`, without Paper.

### Engine parts

`EnginePart` is a marker for a class an engine builds and runs (decided 2026-11-03). Implementing it is the registration: there is no list to write and no annotation to forget.

1. KSP finds every concrete class implementing `EnginePart`, generates a provider, and adds a row to the provider index. This is the first processor searching by supertype instead of annotation.
2. On start, the engine reads the index for the source parts it loaded, so a Paper part only reaches Paper, and adds each class to its deployment Koin ([engines.md](engines.md#wiring-inside-an-engine)).
3. The deployment turns each provider row into a Koin single (decided 2026-11-22). The generated provider calls the constructor and asks for each parameter by type, so an extension reaches `PaperEvents` by asking for it and never depends on Koin. A part is offered to others by its supertypes, not by its own class.
4. The event runtime asks for every `Source` and opens them by demand. The Koin closes with the deployment.

A missing constructor dependency fails at engine start, naming the class and the type, because KSP cannot see what Koin provides. `SubscribedSource` extends `EnginePart` and others may follow. `RuntimeRegistrar` stays for imperative setup.

### Occurrences and dedupe

One occurrence can reach several sources (packet and Paper event can both decide and change). Sources may overlap; the meaning rule above says whether the second one joins the occurrence or is a separate event.

The occurrence dedupe key is (connection, kind, client sequence number) when the packet has one, otherwise per connection order. Never timing or same tick guesses.

### Subscribed events

An event type may take a subscription type parameter: `Tick<S : TickSubscription>`. The source only emits for matching subscriptions and passes the subscription to the handler as `subscription`.

```kotlin
object EveryTick : TickSubscription

@Handler
fun Tick<EveryTick>.animate(animating: Animating, chat: HasChat, history: ChatHistory) = ...
```

A subscription is either a Kotlin object (code), an entry type (content: one subscription per published entry), or a list item type inside an entry (content: one subscription per published item, such as `Every`).

How it works:

1. KSP indexes every (event, subscription type) pair used by a handler: the plan's `subscription` is `HandlerSubscription.Object(EveryTick)` or `HandlerSubscription.Entries(IntervalEventEntry::class)`. Any other subscription type (a plain class, a type parameter) is rejected at build time. Item types inside an entry are not built yet.
2. Publication turns each pair into subscription instances: one for an object, one per published entry or item for a content type. These stay live across hot publish.
3. The source receives only the subscriptions that currently have a runnable handler, through `SubscribedSource<E, S>.open(demand: Demand<S>, sink: Sink<E>)`, and indexes them its own way (a timing wheel, a map by region). `Demand.watch` hands the current set at once and every changed set after it; the source closes once the demand is empty.
4. An occurrence reaches only the handlers of its subscription. A `Candidate<C>` of the subscription's own entry type is that entry only (`Param.Candidate.ofSubscription`), with its book condition.

`Tick<S : TickSubscription>` is the first subscribed event (basic extension, node 4). Its Paper source fires at the start of every server tick whose number is a multiple of a subscription's interval, indexed by interval, so the chains it starts run at the end of the same tick. `IntervalEventEntry` (content, `interval` in ticks) starts its links for every online player its book applies to.

Subscriptions a source cannot index are not subscribed events. Use `Candidate<E>` plus an `if` in the handler instead; entries stay pure data.

Appearing and disappearing state (being in a region, being near an NPC) is not an event. It is `Added` and `Removed` of a `Live` value; see [live-data.md](live-data.md).

## Demand

`Demand<S>` is the source input for subscribed events: the subscriptions that currently have a handler whose other parameters are satisfiable. Demand is computed from handler parameters, so a source never runs work no handler could use. Demand for mirrors (`Demanded<T>`) follows the same rule and is described in [live-data.md](live-data.md).

## Handler

A handler is a Kotlin function with the event as receiver and typed parameters. Its parameter types decide when and where it runs; its return type decides its phase and what it produces.

```kotlin
@Handler
fun NpcClicked.talk(running: Running<SpokenDialogueEntry>, mood: Mood) = ...
```

This runs when an NPC is clicked, only if the clicking protagonist is in a spoken dialogue step and a `Mood` exists for the clicked NPC.

### Parameters

Parameters take plain types. A type as a parameter is the requirement; nullable means optional. There are no wrapper types such as `Present<P>` or `Held<H>`. An entry value is never a parameter: it is read in the body through an accessor ([Reading entry values](#reading-entry-values), decided 2026-11-23).

```kotlin
fun Tick<EveryTick>.animate(
    animating: Animating,
    chat: HasChat,
    preview: Simulating?,
)
```

Core resolution is a small fixed set. Extensions add value types, not resolution logic.

| Parameter | Resolves to |
| --- | --- |
| A `Stored`, `Hold`, `Live`, or `Runtime` type | The value at keys filled from the subject or event fields; free keys iterate (one run per value). |
| An identity (`Protagonist`, `Step`, `Npc`, ...) | The subject, or the event's only field of that kind. |
| A live capability trait (`HasChat`, `HasInventory`, `HasHealth`) | The engine object for that identity; for a group subject, one per member. |
| `List<T>` | One run with the values that exist at these keys, filled like `T` from a list field or by `@From`; missing keys drop out. |
| `All<T>` | Every value of type `T`; for a mirror, on every engine ([live-data.md](live-data.md#demand-across-engines)). |
| `Candidate<E>` | One run per published entry of type `E` whose book applies to the subject ([book-composition.md](book-composition.md#6-conditions)). |
| `Outcome` | The final outcome; lets an after handler also see denied events. |
| `Origin` | Who caused this occurrence: the session and its `PrincipalId`. Absent for events without a cause (`Tick`), which skips the handler; `Origin?` makes it optional. |
| A hold's snapshot type (`LeashCenter`) | That hold's stored snapshot at the hold's keys ([interactions.md](interactions.md#snapshot-and-restore)). |
| `Snapshot<H>` | A hold's stored snapshot, readable and writable ([interactions.md](interactions.md)). |

Live capability traits are provided by the engine (`PaperProtagonist : Player, HasChat, ...`). Optional capabilities are plain Kotlin type checks.

### What KSP generates

KSP generates a thin `EnginePart` per handler whose parameters are described as data; resolution is ordinary code in the runtime (decided 2026-11-03). The example is an extension's own entry with a `locked` field: `fun BlockBreak.vault(entry: Candidate<VaultEntry>): Verdict`.

```kotlin
// generated
class BlockBreak_vault : VerdictHandler<BlockBreak>, EnginePart {
    override val event = BlockBreak::class
    override val params = listOf(Param.Candidate(VaultEntry::class))

    override fun run(event: BlockBreak, values: List<Any?>) =
        event.vault(values[0] as Candidate<VaultEntry>)
}
```

The plan is the one source for resolution, demand, and placement, and later for debug output. Later layers add a `Param` kind and its resolver. Layer 4 has `Identity`, `Trait`, `Candidate`, `Origin`, and `Outcome`.

Live objects come from the engine, which is what keeps handlers engine neutral:

```kotlin
interface LiveResolver<I : Identity> : EnginePart {
    fun live(identity: I): Any?
}
```

The runtime checks the result against the requested trait; `null` or the wrong type means the handler does not apply.

### Reading entry values

One way to read entry values (decided 2026-11-23): handlers and derives read them in the body, by name, at any depth. `EntryScope<E : Entry>` is what a body reads through. It carries `entry`, `subject`, and `context`; `Candidate<E>`, `Triggered<E>`, and `Running<E>` all implement it. `RecordScope<T>` is a scope positioned at a record value inside an entry; an entry is itself a record, so `EntryScope<E>` is a `RecordScope<E>` at the root.

KSP generates one typed accessor per field of every record type, on `RecordScope<ThatRecord>`. A `Var<T, C>` field reads as a plain `T`, and context is filled from the scope (subject and chain context), so nobody passes it by hand:

```kotlin
// generated
val RecordScope<VaultEntry>.locked: Boolean get() = readField(VaultEntryFields.locked)
val RecordScope<WeightedRandomTriggerGateEntry>.links: List<RecordScope<WeightedLink>>
    get() = recordList(WeightedRandomTriggerGateEntryFields.links)
```

```kotlin
@Handler suspend fun Triggered<SimpleMessageActionEntry>.send(chat: HasChat) {
    chat.send(message)
    complete()
}

@Derive fun Running<SpokenDialogueEntry>.view() =
    SpokenView(step, text.wrap(spoken.maxLineLength, spoken.minLines))
```

On `Triggered<E>` and `Running<E>` the receiver is the scope, so accessors read bare (`message`, `spoken.minLines`). On a `Candidate<E>` parameter they are reached on the candidate (`entry.condition`). Nested records read the same way at any depth, with no segment limit. A record field gives the record's own scope one level deeper (an optional record gives `RecordScope<R>?`, and whether one is stored is its own read). Lists, sets and maps of records give `List<RecordScope<R>>`, `Set<RecordScope<R>>` and `Map<K, RecordScope<V>>` in stored order, so `options[i].text` reads the `text` field of the i-th option record; inside the engine a path addresses an item by its stable item id, not its index. There is no whole value read: a helper that needs a record is written on its scope (`fun RecordScope<Spoken>.wrapLines(text: RichText)`). A derive on an entry that is not a running step takes `EntryScope<ThatEntry>` as its receiver. A record field named like a scope member (`entry`, `subject`, `context`, `reader`, `entryScope`, `recordPath`) is a build error, since the member would hide its accessor.

- **The entry reader.** Every accessor resolves through one reader (`EntryReader`: `read`, `has` and `items` at a path from the entry's root). A stored value, a `Var` (value or formula) and a nested record field all resolve through it; the engine reader asks `StoredValues.at(location)` for a loaded value or not loaded. A configured value needs nothing extra: a configuration record's `Var` field reads the inherited value through the ordinary scope name `inherited` in its formula ([configurations.md](configurations.md)). Check in the plan that KSP can generate accessors for entries from another extension.
- **Tracked reads.** Inside a derive, every accessor read is a read of the tracked graph: each run records its own reads and verifies them in read order. A branch is correct because the condition's value is itself a read: a change on the branch not taken does not rerun the derive, a change to the condition does. A change at a location also covers the reads below it, and the graph compares values, so a derive reruns only when a value it read actually differs. Handlers (verdict and after) evaluate inline and never rerun. A formula's own references to other resources are not graph reads yet (`TODO(node 6)`). KSP does not list reads: declared reads would load both sides of every branch and rerun on changes that cannot matter.
- **Not loaded.** A read whose value is not loaded yet fails as a recorded read, and the graph reruns the derive once that failure clears. On a rerun the engine first loads everything the previous run read, so a steady state needs one load round, not a chain of loads. A derive may therefore run once before its values are loaded. A handler that reads a value not loaded yet fails like any failing handler.
- **Accessors only.** The accessors are the only path to entry values, and derives stay pure. A lambda that runs later (a callback) runs as a handler with its own scope.

A formula that fails counts as a failed handler and is logged; for a verdict that means `pass`.

### Resolution

- **From the subject, else from the only field of that kind.** A value whose key is a `Step` resolves from the event's only `Step` field, so events can address a step:

  ```kotlin
  fun Confirm.advance(running: Running<SpokenDialogueEntry>)
  ```

- **Every key must resolve.** A stored value is keyed by `@Key` fields ([stored-data.md](stored-data.md)); each key fills from the subject or event fields. Set keys (`Friendship(@Key pair: Set<Protagonist>, level)`) fill from all event fields of that kind.
- **Typed roles.** When an event has two fields of one kind, the event marks them with `@As(Killer::class)` and handlers pick one with `@From(Killer::class)`. A derive's receiver entry marks its fields the same way (`@As(Parent::class) val parents`).
- **Same kind means same identity.** Parameters of the same identity kind refer to the same identity, one parameter per trait, ECS style:

  ```kotlin
  fun SwapHands.heal(health: HasHealth, inventory: HasInventory)
  ```

- **Group subjects iterate members.** When the subject is a group, protagonist kind parameters iterate its members, joined per member. A group parameter plus traits gives the group once plus each member:

  ```kotlin
  fun Triggered<GiveReward>.give(inventory: HasInventory, chat: HasChat)
  ```

  A member who leaves stops being iterated; `Removed` cancels a suspended run for that member.
- **Unresolved means not applicable.** If any parameter cannot be resolved, the handler does not run. Zero values skip it; many values run it once per value. While a protagonist is away, its live handlers simply do not apply.
- **Unresolvable at build time is an error.** KSP rejects a handler whose parameters can never resolve (for example a protagonist trait on an event with neither a protagonist nor a group subject).

Variants (Java chat versus a Bedrock form) are chosen by the step when it starts, by adding a different stored value. There is no "most specific handler wins" rule.

### Events without a subject

For `Tick` and world events, parameters become a query and the handler runs once per match. `fun Tick<EveryTick>.animate(animating: Animating)` runs once per `Animating` value. Stored types are indexed per type, so a query costs about the values it finds.

Node 4 builds the identity query: a required identity parameter that no event field fills runs the handler once per identity its `LiveResolver.present()` names (each online player on Paper), with that identity as the run's subject for traits, candidates, and book conditions.

The event runtime measures every handler run per event class (`HandlerCosts`, an engine-core Koin single) as the `typewriter.event.handler.duration` histogram, in seconds, with the attribute `typewriter.event` naming the event class. The game run report prints the average handler time per event, so the average tick handler time can be read on real Paper.

### Where a handler runs

Parameter types decide placement. The realm sees this statically, and the panel catalog can filter on required capabilities.

| Handler asks for | Runs |
| --- | --- |
| Only stored data | Once, on an engine where the event happened; for realm delivered events (`Changed<T>`, `Due`), on the realm ([stored-data.md](stored-data.md#offline-changes)). |
| Mirrors, no live trait | On the engine that owns the mirror, without live object access. |
| A live trait | On the engine where its subject is live. The handler runs on a worker; the engine's trait implementation places each read and effect ([tick pipeline](#tick-pipeline)). |
| A live trait on a group subject | On each member's engine. |

A handler needs exactly one live anchor. When it would need two, it reads the second through its mirror:

```kotlin
fun Trade.check(seller: PaperPlayer, buyerHealth: Health)
```

Routing an event to that engine is described in [live-data.md](live-data.md); offline behavior in [stored-data.md](stored-data.md).

### Return value decides the phase

| Return type | Phase | Notes |
| --- | --- | --- |
| `Verdict` | Decision | Pure; takes part in allow, deny, change, pass. Never suspends. |
| `Unit` | After | Runs after the outcome was applied (the source decides when). May suspend. |
| `Live` type | After | Writes a mirror on the owner thread at tick end ([live-data.md](live-data.md#writers)). Never suspends. |
| `Runtime` type | After | Creates the runtime object; returning another replaces the previous one of that type, and a different value counts as a change. |

Non cancellable events (`Tick`) accept only after handlers.

```kotlin
@Handler
fun EntityDamage.health(player: PaperPlayer): Health = ...
```

After phase writers see the post event value; verdict handlers reading the same mirror see the pre event value.

### Verdicts

A verdict is `allow`, `deny`, `change`, or `pass`. Pass means "not my business" and never overrides a lower priority decision.

Resolution:

1. Pass verdicts drop out.
2. Changes apply from low to high priority. Each change is a pure function; a higher one sees the lower one's result.
3. Allow versus deny is won by the highest priority. A tie means deny wins at runtime, and the realm reports the tie as a check warning (`RealmCheckProvider`).
4. A foreign deny is never undone.

Priority: a `Candidate<E>` verdict carries that entry's inherited priority. A handler with a stored value from a step uses the step entry's priority. Pure extension handlers get a low default.

### Follow ups and cancel

Every verdict may carry a follow up: `allow { }`, `deny { }`, `pass { }`. A follow up runs when the final outcome matches its verdict: a deny follow up on denied, allow and pass follow ups on allowed. `pass(on = Allowed | Denied | Any) { }` chooses when a pass follow up runs (default `Allowed`; `Any` receives the `Outcome`). One handler can thus hold the decision and every reaction.

The outcome is Typewriter's own, from its verdicts. Another plugin cancelling the Paper event after that does not change it (decided 2026-11-04): this is often what a server wants, such as a fake mine where another plugin cancels the break and resets the block while Typewriter still rewards it. An event already cancelled before Typewriter's listener is skipped through `ignoreCancelled`, like legacy.

Rule control (cancelling world behavior) is a cancelable event entry, like legacy. There is no separate rule entry concept. The shared entry does this for every cancelable event ([Event entries](#event-entries)):

```kotlin
@Handler
fun <E : CancelableEvent> E.rule(
    entry: Candidate<CancelableEventEntry<E>>,
): Verdict = when {
    !entry.condition -> pass()
    entry.cancel -> deny { entry.complete() }
    else -> pass { entry.complete() }
}
```

The triggers fire exactly once either way. Deny and start goes through a deny follow up, so it only starts if that deny wins. When two cancelling entries both deny, both fire their triggers, like legacy; clash rules settle competing starts ([interactions.md](interactions.md)).

By default an after handler only sees allowed events. A handler that asks for an `Outcome` parameter also sees denied ones.

An event emitted from a session reports its result back to that session once its after handlers finish: `Done`, `Denied(reason)`, `Failed(reason)` (an after handler ended with a typed failure, such as an edit that could not commit), or `NotHandled`. A deny verdict carries the typed reason, so permission checks and unavailability are deny handlers ([panel-engine-communication.md](panel-engine-communication.md)). An engine that lacks the event's exact `TypeDefinitionId` (type and revision) or cannot decode it answers `Failed(reason)`, never stays silent. `NotHandled` means no engine holding the subject's sessions has a handler for the event; every holder answers, also without a handler.

Each engine decides for itself (decided 2026-11-03): no engine waits on another for a verdict. A source event decides inline on its source's engine; an emitted event is decided by each holder with its own handlers, and each holder sends one result. The sender reads the holders from the `sessions` KV and merges their results, the strongest winning: `Denied`, then `Failed`, then `Done`, then `NotHandled`. No holders gives `NotHandled` right away, because the protagonist is offline. With several holders, one engine's after handlers can run while another denied; in alpha a protagonist's sessions sit on one engine, so this first becomes possible with account linking.

Events have no sender field. Who caused an occurrence travels beside the event as its origin, filled by the source and never by the event: the panel engine fills it from the tab's session, Paper from its player. A client cannot fake it, because only engines publish to protagonist subjects. A handler that needs it asks for `Origin` and passes it on explicitly; nothing reads it implicitly.

```kotlin
@TypewriterType(id = CAPTURE_LOCATION_TYPE_ID)
data class CaptureLocation(val player: Protagonist, val into: BoundPath<Location>) : Event

@Handler
fun CaptureLocation.capture(player: PaperPlayer, origin: Origin) {
    realm.edit(scope = AuthoringScope.resources(listOf(into.location.resource)), initiatedBy = origin.principal) { into.set(player.location.fromPlatform()) }
}
```

`player` is the event's only `Protagonist` field, so it is the subject and no roles are needed. Common captures use the core `Capture` event instead ([capture.md](capture.md)); an event of your own, like this one, is for what a formula cannot do. On the wire (layer 4):

```skir
struct EventOrigin { session: SessionId = 0; principal: PrincipalId = 1; }
struct EventDelivery { occurrence: OccurrenceId = 0; event: DataValue = 1; origin: EventOrigin? = 2; }
struct EventResult {
  occurrence: OccurrenceId = 0;
  engine: EngineId = 1;
  outcome: enum { received; done; denied: EventReason; failed: EventReason; not_handled; } = 2;
}
struct EventReason { code: string = 0; message: string = 1; detail: DataValue? = 2; }
```

`OccurrenceId` is a UUIDv7 set by the source. Only events with an origin get results, through `session.emit(event): EventResult`; a handler's `emit` queues and returns nothing. A holder sends `received` as soon as it gets the event, and its final result when its after handlers finish. With no `received` within 5 seconds the sender records `Failed("no_response")`; with no final result within 60 seconds, the session key's TTL, it records `Failed("timeout")`, while the handler keeps running. A long job finishes its handler quickly and reports through stored data. The engine holding the origin session merges the results. `EventReason` matches `code` and `message` on `Diagnostic`, so a panel can show any reason without knowing its type; `detail` is typed, and an editor shows the details it knows.

A panel user is `PrincipalId("user", <user id>)`; a player is `PrincipalId("minecraft", <uuid>)`. Both are also the principal inside their `Protagonist`. The result goes to the origin session's subject.

### Threads

There is no "main thread". Live access runs on the thread that owns the identity (protagonist, entity, region), so Folia style region threads work.

- **Packets are never held.** Verdicts on wire events read only network safe data: stored values, holds, formulas, and `Live` mirrors (last committed value; at most one tick old for a writer, and a derived value can be older while a recheck runs). Live traits are forbidden there.
- **Live access on world events only**, on the owning thread.
- **Other threads** read the last committed mirror value without a hop.
- **Codegen rejects violations** at build time.

Verdict handlers never suspend: they run inline (for example inside a Paper event) and read cached stored data. A value keyed by a field other than the subject can miss, so such a parameter must be nullable; KSP rejects it otherwise ([live-data.md](live-data.md#demand-across-engines)).

### Tick pipeline

Chosen 2026-11-03, after a prototype compared it with waiting per write, chain transactions, and starting each chain at once. Priorities: few context switches, little work on owner threads, and Typewriter out of the way. The prototype simulated the game thread and the realm distance, so the plan checks these numbers on real Paper.

1. **In the event, on the owner thread.** The verdict decides at once. Each chain start joins a queue, without waking a thread. Starts with the same subject, entry, and context in one tick merge into one, so an autoclick does not run a chain three times. Repeats of a link within one `fire` call are not merged: a gate that draws the same link three times starts it three times.
2. **At tick end, on the owner thread.** Mirror writers run for demanded keys (decided 2026-11-04). This is the live copy, so it includes the event's own result, and it is the only handler code on an owner thread. One worker wakes for the whole engine.
3. **On the worker.** The worker first rechecks the formula graph once for everything that changed (decided 2026-11-04, [live-data.md](live-data.md#formula-changes)), then takes chains until the queue is empty and runs each chain's handlers in one go. A worker stuck in a slow handler holds up only that chain: the next tick's worker takes the rest.
4. **Effects.** Apart from writers in step 2, handlers never run on an owner thread. An engine's trait implementation chooses where each effect runs, not the shared trait, because this differs between engines. Paper sends chat from the worker and queues a world change for the owner thread; all queued changes of a tick share one visit. An effect sent after a queued change joins that queue, so effects keep their order.

Every chain gets the same limit: at most one owner visit to read live values, one owner visit per tick for world changes, a realm wait only for a `require` guard ([stored-data.md](stored-data.md#transactions)), and a wait only for a mirror read that misses on another engine ([live-data.md](live-data.md#demand-across-engines)).

Accepted costs: a chain starts up to one tick after its event, while the verdict stays instant. A player who leaves right after paying can lose the item, as in every option tested; what must arrive is stored as owed.

Named in node 4 (decided 2026-11-22): `ChainQueue` takes chain starts, `ChainPickup` is the one engine piece that drains it (Paper on `ServerTickEndEvent`, the panel engine at once), and `ChainWorker` is the coroutine per drain on a bounded dispatcher. There is no owner thread effect queue yet: node 4's only effect is chat, sent from the worker, and the first world change action adds the queue. Open: how a handler's live reads reach step 2: KSP knows its parameters but no longer lists body reads (decided 2026-11-23), and `FormulaReads` knows a formula's reads at publish, so writers can run before the chain ([formula-language.md](formula-language.md#what-a-formula-reads)).

Folia (decided 2026-11-03): the first version targets Paper's server wide tick end. Picking up queued chain starts stays one small piece of the Paper engine, so the design does not block Folia. Folia later replaces only that piece, with a next tick task per active player, because no per region tick end hook was found. Expected cost there, not measured: one post per active player per tick, and chains start up to one tick later.

### Busy per subject

The game verification framework steps Paper's ticks itself and judges a requirement only once its player's work is quiet ([game-verification/README.md](game-verification/README.md#obligations-on-typewriter)). Typewriter owes it a per subject view of its own work (decided 2026-11-07):

- The engine counts, per protagonist, the chains queued and running for it. A chain with a group subject counts for every member.
- The realm side counts pending transactions the same way ([stored-data.md](stored-data.md#who-waits-for-a-commit)). A future `Due` is not busy; a requirement waiting on one advances the realm clock ([stored-data.md](stored-data.md#due)).
- Typewriter never cancels a chain for the test. A chain that does not finish is reported by the framework's wall clock limit (1 s), and its player sits out until it ends.
- The engine counts from the moment a chain start is queued until the chain ends (decided 2026-11-22), through the engine-core port `SubjectWork`, which does nothing by default. A chain for an event without a subject counts for every protagonist present on the engine, since its handlers query them.
- On the test Paper the playtest bridge, an Imprint extension, implements `SubjectWork` with the framework's `PlayerWork` API ([plugin-integrations.md](plugin-integrations.md#first-user)). The test side needs no hook of its own.

Spikes I and D showed that work a server wide quiet check cannot see (a raw thread pool) gives wrong verdicts and wrong coverage, and that a per player count fixes both ([d-clients.md](game-verification/spikes/d-clients.md), [i-coverage.md](game-verification/spikes/i-coverage.md)).

**Effects through the owner thread.** Spike N found that an effect sent from the owner thread lands on the same stepped tick every time, while one a worker thread sends races the tick boundary and lands one or two steps later ([n-stepped-ticks.md](game-verification/spikes/n-stepped-ticks.md)), so a requirement's tick counts would vary between runs. The search therefore asks that the Paper engine's effects reach the player through the owner thread, in the tick's effect queue. The framework later made Paper's own async chat steady another way: the work counts as the player's from the moment Paper reads the line, so the next tick waits for the send. Step 4 above still sends chat from the worker, which is steady because the chain counts from the moment it is queued (decided 2026-11-22).

### Suspending handlers

After handlers may suspend. A suspended handler is cancelled when any value it resolved through a parameter is removed (step ended, stored value removed, member gone, a mirror `Removed` including `because = Tracking`). `Changed` never cancels it. Stale writes are also dropped by the owner generation check: an event for a finished step is dropped ([interactions.md](interactions.md)).

## Chain

A chain is how entries lead to entries. Links fire, entries do not: nothing follows links automatically.

### Firing and `Triggered`

Firing a link emits an ordinary `TriggeredEvent<E>(entry, subject, context)` event per linked entry, queued like `emit`; chains merge on it. A handler's receiver is `Triggered<E>`, the scope the engine builds from that event and its own entry reader when it runs the handler, so a `Triggered<E>` can always read its entry and an engine that receives the event binds its own reader. An `outcome` parameter on such a handler is `Outcome<TriggeredEvent<E>>`. `Triggered<E>` is the scope its handler reads through ([Reading entry values](#reading-entry-values)), so `complete()` and `fire()` take the context from it. The subject is the identity the chain is for: a protagonist, or a group after widening ([interactions.md](interactions.md#widening)).

```kotlin
entry.triggers.fire()
entry.triggers.random(seed).fire()
chosen.link.fire()
```

Actions, steps, and triggers share this one flow:

- An **action** entry's handler on `Triggered<E>` does its work and fires its links.
- Firing into a **step** entry starts it; whoever ends the step (`running.complete()`) fires the next links. Steps, interactions, clashes, and rejoin are in [interactions.md](interactions.md).
- A **trigger** is an ordinary handler on a world event that fires an entry's links:

```kotlin
@Handler
fun <E : Event> E.fire(entry: Candidate<EventEntry<E>>) {
    if (entry.condition) entry.complete()
}
```

That shared handler serves most events ([Event entries](#event-entries)); `event.message.contains("hello")` in the condition replaces the legacy chat entry. An extension can write its own trigger the same way. Extra needs are extra parameters (traits, stored values, mirrors). Entries stay plain data; trigger code only says it fired, the core follows the links. Book narrowing happens inside `fire`: a link into an entry whose book does not apply to the subject is skipped ([book-composition.md](book-composition.md#6-conditions)). Firing for a group instead of the current subject (`fire(for = group)`) is described in [interactions.md](interactions.md).

Forwarding is declared by the trigger type: the extension marks it forwardable.

`Candidate<E>` scans the published entries of type `E`, like legacy `Query<Entry>`.

### Context

Context is a typed bag of produced records that always passes along the chain. It only grows.

- **Entry records** are keyed by producing entry plus type (`smith_question.chosen.index`, short form `chosen.index` when only one is reachable). They are add only.
- **Global records** are keyed by type only and describe the chain as a whole (random seed, interacting entity instance). They may be replaced (newest wins), never removed.

An entry declares what it produces through `produces { }` in its `dynamic()` ([formula-language.md](formula-language.md)); a Kotlin entry gets that call generated from its declaration. `fire` only accepts the declared record types and adds them to the context, and later formulas in the chain read them with checking and autocomplete (`chat.message`). When several paths reach an entry, a record is non null if every path provides it, otherwise nullable (`chat?.message`).

Steps keep their context on the step (stored, so it survives server moves) and can add to it while running.

### `Triggerable` and `complete`

Entries that apply changes and fire links implement the core trait:

```kotlin
interface Triggerable {
    val triggers: ...
    val refused: ...
    val changes: Var<Changes, InteractionContext>
}
```

`changes` replaces legacy modifiers. `refused` links fire when the changes are refused; the triggers do not fire then, and the event result is `Failed(reason)` ([stored-data.md](stored-data.md#which-fields-are-guarded)). Two styles:

```kotlin
// Shortcut: apply changes, then fire triggers (legacy order; the next entry sees the changes).
entry.complete()

// Manual, when an entry needs another order or timing.
entry.changes.attempt()
entry.triggers.fire()
```

Extra update fields (dialogue options) are applied the same way: `option.changes.attempt()`, then `option.triggers.fire()` unless refused. What `attempt()` commits and how the realm handles conflicts is in [stored-data.md](stored-data.md).

## Event entries

One shared entry serves almost every event (decided 2026-11-04 in the layer 10 rough design). An extension writes the event and its source; the entry, its editor, the filter, cancel, and the chain record come along. The filter is one boolean formula over the event, which is what the vision asks in place of criteria and how [items are already recognized](minecraft-types.md#recognizing-items). Filter fields generated from an event's fields do not work: only 13 of the 30 legacy events have no filter or a plain equal.

Nothing here is built yet. See [Event entries not proven](#event-entries-not-proven).

### End to end

A player breaks diamond ore with an iron pickaxe. The break is cancelled, and a message names the location.

**The event and source.** The facts a filter needs sit on the event, because a verdict cannot wait for a mirror. `@TypewriterDisplay` on the event gives the name, icon, and color the entry shows.

```kotlin
@TypewriterType(id = BLOCK_BREAK_TYPE_ID)
@TypewriterDisplay(name = "On block break", icon = "mingcute:pickax-fill", color = Color.Hex.YELLOW)
data class BlockBreak(
    val player: Protagonist,
    val blockType: BlockType,
    val location: BlockLocation,
    val mainHand: Item,
    val offHand: Item,
) : CancelableEvent

class BlockBreakSource(paper: PaperEvents) : Source<BlockBreak> by
    paper.source<BlockBreakEvent, BlockBreak> {
        BlockBreak(
            player.protagonist,
            block.type.fromPlatform(),
            block.location.fromPlatform(),
            player.inventory.itemInMainHand.fromPlatform(),
            player.inventory.itemInOffHand.fromPlatform(),
        )
    }
```

**The entries, in core.** `E` is the resource's type argument, the same way a `Definition<T>` holds its `T`.

```kotlin
interface CancelableEvent : Event

interface EventContext<E : Event> : InteractionContext { val event: E }

@TypewriterType(id = EVENT_ENTRY_TYPE_ID)
class EventEntry<E : Event>(
    // page, name, placement, triggers, refused, changes
    val condition: Var<Boolean, EventContext<E>>,
) : SequenceEntry, Triggerable

@TypewriterType(id = CANCELABLE_EVENT_ENTRY_TYPE_ID)
class CancelableEventEntry<E : CancelableEvent>(
    // page, name, placement, triggers, refused, changes
    val condition: Var<Boolean, EventContext<E>>,
    val cancel: Var<Boolean, EventContext<E>>,
) : SequenceEntry, Triggerable
```

**The handlers, in core.**

```kotlin
@Handler
fun <E : CancelableEvent> E.rule(
    entry: Candidate<CancelableEventEntry<E>>,
): Verdict = when {
    !entry.condition -> pass()
    entry.cancel -> deny { entry.complete() }
    else -> pass { entry.complete() }
}

@Handler
fun <E : Event> E.fire(entry: Candidate<EventEntry<E>>) {
    if (entry.condition) entry.complete()
}
```

**What the creator writes.** Completion after `event.` lists the event's fields; after `minecraft.block.` it uses the [picker's search](domains.md).

```
event.blockType == minecraft.block.diamond_ore and event.mainHand.is_like(iron_pickaxe)
```

**The next entry reads the event.** The event itself is the chain record, which replaces the 14 legacy `ContextKeys` enums.

```kotlin
// Generated default on the entry, once, from E.
produces { use(E) }
```

```
"You cannot break this at ${on_block_break.location}"
```

**The action runs on the player.** Actions stay hand written: the handler reads their fields in its body through accessors, so nothing can be derived.

```kotlin
@Handler
fun Triggered<SimpleMessageActionEntry>.send(chat: HasChat) {
    chat.send(message)
    complete()
}
```

### Own entries stay

Any extension can write its own entry and handler on any event, next to the shared one; both run. Write one when the shared entry's shape is not enough, such as a second link set:

```kotlin
class PlayerKillPlayerEventEntry(
    // page, name, placement, triggers, refused, changes
    val condition: Var<Boolean, EventContext<PlayerKillPlayer>>,
    val killedTriggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>>,
) : SequenceEntry, Triggerable

@Handler
fun PlayerKillPlayer.fire(entry: Candidate<PlayerKillPlayerEventEntry>) {
    if (!entry.condition) return
    entry.complete()
    entry.killedTriggers.fire(for = killed)
}
```

### When things go differently

| Case | What happens |
| --- | --- |
| Condition reads a mirror | `protagonist.heldItem` misses on the first read, so it counts as not met and posts a demand. This is why filter facts sit on the event. |
| Condition fails at run time | Counts as not met: `pass`, no links fire, logged. |
| Entry value not loaded yet | The handler fails like any failing handler; for a verdict that means `pass` (decided 2026-11-23). In a derive the read is recorded and the derive reruns once it loads. |
| Event field renamed in code | The formula gets a check error at publish. |
| Cancel on a non cancelable event | Refused by the bound on the type argument. |
| One exact block | Capture into a `Definition`, then name it in the formula. |

### Legacy events and actions by layer

Of the 30 legacy events, 24 use the shared entry. `PlayerDamaged`, `PlayerKillPlayer`, and `PlayerProjectileHitEntity` have a second link set for the other player, so they get their own entry. `StandOnBlock` and `PlayerNearLocation` are one `PlayerMove` event with a condition, so they need no fields of their own and can still cancel (decided 2026-11-05). `FactChange` becomes a `FormulaEventEntry` on `Changed<Watched<Boolean>>` ([live-data.md](live-data.md)). `RunCommand` and `FireTrigger` are commands.

| Layer | Events | Actions |
| --- | --- | --- |
| 4 Events | `PlayerJoin`, `PlayerQuit`, `ChatContainsText`, `BlockBreak` | `Simple`, `SimpleMessage`, `GroupTrigger`, `RandomTriggerGate`, `WeightedRandomTriggerGate` |
| 5 Commands | `RunCommand`, `FireTrigger`, `DetectCommandRan` | `ConsoleCommand`, `PlayerCommand` |
| 6 Stored data | | `BulkFactsReset`, `FactsPreset` |
| 7 Time | | `Delayed`, `Repeat` |
| 8 Mirrors | `FactChange` | |
| 10 Minecraft types | `BlockPlace`, `ConsumeItem`, `CraftItem`, `DropItem`, `PickupItem`, `Fish`, `Interact`, `InteractBlock`, `ChangeWorld`, `Teleport`, `PlayerRespawn`, `PlayerMove`; `BlockBreak` gains its fields | `GiveItem`, `RemoveItem`, `RemoveItemFromSlot`, `SetItem`, `DropItem`, `Teleport`, `ApplyVelocity`, `BurnPlayer`, `AddPotionEffect`, `RemovePotionEffect`, `SwitchServer` |
| 16 Dialogue | | `Message`, `ActionBarSimpleMessage`, `ShowTitle`, `SendToast` |
| 18 Scenes | `PlayerDamaged`, `ClientLoaded` | `PlaySound`, `StopSound`, `SpawnParticle`, `Firework`, `SetBlock`; legacy `Cinematic` becomes the `PlaySceneEntry` step |
| 20 Assets | `ResourcePack` | |
| 21 Entities | `LeashEntity`, `PlayerHitEntity`, `PlayerKillEntity`, `PlayerKillPlayer`, `PlayerProjectileHitBlock`, `PlayerProjectileHitEntity` | |
| 22 Regions, rules | `PlayerDeath` | |

`PlayerMove` holds the player, `from`, and `to`. A condition covers what legacy needed fields for:

```
event.to.block.below.type == minecraft.block.gold_block          // stand on a block
event.to.distance(spot) < 5 and event.from.distance(spot) >= 5   // walked near a place
```

`SwitchServer` takes a `ServerName`, an open id, so an unknown name is a warning. Nothing reports server names until assets, so until then it warns that there are no reports yet.

### Event entries not proven

- **Palette.** "On block break" must appear as its own choice when creating an entry. `resource_creation.dart` does not mention type arguments.
- **Cost.** Both hand items convert on every event while the source is open. Not measured; `Interact` is the frequent one.
- **Proven in node 4 (change set 1).** Generic handlers (`fun <E : CancelableEvent> E.rule`, instantiated per published event class within the bound) and `EventContext<E>` inside a `Var` work end to end.
- **Not run yet.** Anything resting on layers 6 and 8.

### Open

- A form on top of the condition, likely a presentation with rows for `event.x == value`, gives creators pickers and writes the same formula, so the data does not change. It is wanted during the beta and not for alpha (decided 2026-11-05). Not designed. Until then, 0.9 creators write a formula for what was a form.
- `PlayerMove` runs its condition on every move while an entry uses it. That cost is not measured.

## Commands

A command is a hold, an event, and data at once; see [commands.md](commands.md).

## Build time checks

KSP rejects, for handlers: `suspend`, stored writes, and effects in a mirror writer; unresolvable parameters, live access in wire verdicts, non nullable verdict parameters keyed by a field other than the subject, handlers needing two live anchors, and command nodes whose event fields do not match the path arguments. The full check list is in [live-data.md](live-data.md).

## Open

- The same occurrence reaching a handler twice through forwarding.
- What `force` does for `/tw fire`.
- Chat from the worker (tick pipeline step 4) against game verification's ask that effects go through the owner thread ([Busy per subject](#busy-per-subject)). Counting the chain as the player's work from the moment it is queued would also keep tick counts steady.
- Event declaration details (how an event names its subject and typed roles in code) are settled when the event core is built.
