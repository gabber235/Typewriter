# Events and handlers

How something that happens (a click, a chat message, a tick, a fired link) reaches code, how that code decides or reacts, and how chains of entries follow from it.

The seven primitives are summarized in [overview.md](overview.md). Stored values, keys, and transactions are in [stored-data.md](stored-data.md); mirrors, demand for mirrors, sessions, and routing between engines are in [live-data.md](live-data.md); holds, steps, interactions, and groups are in [interactions.md](interactions.md); formulas and `Var<T, C>` are in [formula-language.md](formula-language.md). Every term is listed in [glossary.md](glossary.md).

## Event

An event is a plain Kotlin type that says one thing happened. Extensions declare their own events in common code, next to their entries.

- **One event type per meaning.** What a particular delivery may do (decide, change, which thread it is on) is typed on the source, not on the event.
- **Meaning decides how many events exist.** A change with a different effect at the packet than at the Paper event is two events: `ClientPosition` is a fake view on the wire, `PlayerMove` really moves the player. The same effect (`ArmSwing`) is one event: the first source starts the occurrence, the others join it. Nothing may rely on the packet arriving before the Paper event.
- **Raw input becomes intent events.** A raw key press becomes `Confirm` only when it is the key currently offered by whatever holds the protagonist's input, so a raw key is only taken when it is the offered key.
- **Subject.** Most events have a subject (usually a protagonist; chain events have a group). Events without a subject (`Tick`, world events) turn handler parameters into a query, see [Events without a subject](#events-without-a-subject).
- **Engine neutral core.** `Tick` is a capability, not core. Core events say protagonist, never player (`ProtagonistJoined`). `Player` is only a Minecraft capability trait or part of a Minecraft event name (`PlayerMove`).

Lifecycle events are ordinary events with the same handler rules: `Added<T>`, `Removed<T>`, `Changed<T>(old, new)` fire for every stored value ([stored-data.md](stored-data.md)), hold ([interactions.md](interactions.md)), and mirror ([live-data.md](live-data.md)). `Seed<X>` and `FormulaChanged<T>` are core events described in [live-data.md](live-data.md); `Due` delivery is in [stored-data.md](stored-data.md). `Demanded<X>` is a core parameter, not an event ([live-data.md](live-data.md#demanded)).

### Emitting

Events without a source are emitted by handlers. `emit()` queues: the emitted event is decided after the current event finishes. There is no nesting.

```kotlin
@Handler
fun PlayerChat.detectGreeting() {
    if (message.startsWith("hello")) emit(Greeted(protagonist))
}
```

A handler that emits a narrower event is a filter. Together with configured events this covers filtering without a separate filter concept.

### Order

There is no order among handlers reacting to the same event (stable in practice, not promised). Order between events comes from the queue. Across engines, order is per identity in commit order ([live-data.md](live-data.md)).

## Source

A source turns something outside Typewriter (a Paper event, a packet, a timer) into events. Sources are lazy: a source only produces what some handler could actually run for. That is the same notion of demand used for mirrors ([live-data.md](live-data.md)).

### Occurrences and dedupe

One occurrence can reach several sources (packet and Paper event can both decide and change). Sources may overlap; the meaning rule above says whether the second one joins the occurrence or is a separate event.

The occurrence dedupe key is (connection, kind, client sequence number) when the packet has one, otherwise per connection order. Never timing or same tick guesses.

### Configured events

An event type may take a configuration type parameter: `Tick<C : TickConfig>`. The source only emits for matching configurations and passes the configuration to the handler as `config`.

```kotlin
object EveryTick : TickConfig

@Handler
fun Tick<EveryTick>.type(speaking: Speaking, dialogue: DialogueHold, step: Step) = ...
```

A configuration is either a Kotlin object (code) or an entry type (content: one configuration per published entry).

How it works:

1. KSP indexes every (event, configuration type) pair used by a handler.
2. Publication turns each pair into configuration instances: one for an object, one per published entry for an entry type. These stay live across hot publish.
3. The source receives only the configurations that currently have a runnable handler, through `ConfiguredSource<E, C>.open(demand: Demand<C>)`, and indexes them its own way (a timing wheel, a map by region).

Configurations a source cannot index are not configured events. Use `Candidate<E>` plus an `if` in the handler instead; entries stay pure data.

Appearing and disappearing state (being in a region, being near an NPC) is not an event. It is `Added` and `Removed` of a `Live` value; see [live-data.md](live-data.md).

## Demand

`Demand<C>` is the source input for configured events: the configurations that currently have a handler whose other parameters are satisfiable. Demand is computed from handler parameters, so a source never runs work no handler could use. Demand for mirrors (`Demanded<X>`) follows the same rule and is described in [live-data.md](live-data.md).

## Handler

A handler is a Kotlin function with the event as receiver and typed parameters. Its parameter types decide when and where it runs; its return type decides its phase and what it produces.

```kotlin
@Handler
fun NpcClicked.talk(talk: Talking, mood: Mood) = ...
```

This runs when an NPC is clicked, only if a `Talking` value exists for the clicking protagonist and a `Mood` exists for the clicked NPC.

### Parameters

Parameters take plain types. A type as a parameter is the requirement; nullable means optional. There are no wrapper types such as `Present<P>` or `Held<H>`.

```kotlin
fun Tick<EveryTick>.type(
    speaking: Speaking,
    dialogue: DialogueHold,
    step: Step,
    preview: Simulating?,
)
```

Core resolution is a small fixed set. Extensions add value types, not resolution logic.

| Parameter | Resolves to |
| --- | --- |
| A `Stored`, `Hold`, `Live`, or `Runtime` type | The value at keys filled from the subject or event fields; free keys iterate (one run per value). |
| An identity (`Protagonist`, `Step`, `Npc`, ...) | The subject, or the event's only field of that kind. |
| A live capability trait (`HasChat`, `HasInventory`, `Living`) | The engine object for that identity; for a group subject, one per member. |
| `All<T>` | Every value of type `T`. |
| `Candidate<E>` | One run per published entry of type `E` whose book applies to the subject. |
| `Formula<T>` | A formula declared in Kotlin, always current ([formula-language.md](formula-language.md)). |
| `Outcome` | The final outcome; lets an after handler also see denied events. |
| `Snapshot<H>` | A hold's stored snapshot, readable and writable ([interactions.md](interactions.md)). |
| `Demanded<X>` | The keys of mirror `X` demanded for this subject now ([live-data.md](live-data.md)). |

Live capability traits are provided by the engine (`PaperProtagonist : Player, HasChat, ...`). Optional capabilities are plain Kotlin type checks.

### Resolution

- **From the subject, else from the only field of that kind.** A value whose key is a `Step` resolves from the event's only `Step` field, so events can address a step:

  ```kotlin
  fun Confirm.advance(talk: Talking)
  ```

- **Every key must resolve.** A stored value is keyed by `@Key` fields ([stored-data.md](stored-data.md)); each key fills from the subject or event fields. Set keys (`Friendship(@Key pair: Set<Protagonist>, level)`) fill from all event fields of that kind.
- **Typed roles.** When an event has two fields of one kind, the event marks them with `@As(Killer::class)` and handlers pick one with `@From(Killer::class)`.
- **Same kind means same identity.** Parameters of the same identity kind refer to the same identity, one parameter per trait, ECS style:

  ```kotlin
  fun SwapHands.heal(living: Living, inventory: HasInventory)
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

For `Tick` and world events, parameters become a query and the handler runs once per match. `fun Tick<EveryTick>.type(speaking: Speaking)` runs once per step that has a `Speaking` value. Stored types are indexed per type, so a query costs about the values it finds.

### Where a handler runs

Parameter types decide placement. The realm sees this statically, and the panel catalog can filter on required capabilities.

| Handler asks for | Runs |
| --- | --- |
| Only stored data | Once, on an engine where the event happened; for realm delivered events (`Changed<X>` while offline, `Due`), on any engine that runs the book. |
| Mirrors, no live trait | On the engine that owns the mirror, without live object access. |
| A live trait | On the engine where its subject is live, on the thread that owns that identity. |
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
| `Live` type | After | Writes a mirror ([live-data.md](live-data.md)). |
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

Rule control (cancelling world behavior) is a cancelable event entry, like legacy. There is no separate rule entry concept.

```kotlin
data class BlockBreakEventEntry(..., val cancel: Var<Boolean>) : ...

@Handler
fun BlockBreak.rule(entry: Candidate<BlockBreakEventEntry>): Verdict =
    if (entry.cancel) deny { entry.complete(context) }
    else pass { entry.complete(context) }
```

The triggers fire exactly once either way. Deny and start goes through a deny follow up, so it only starts if that deny wins. When two cancelling entries both deny, both fire their triggers, like legacy; clash rules settle competing starts ([interactions.md](interactions.md)).

By default an after handler only sees allowed events. A handler that asks for an `Outcome` parameter also sees denied ones.

### Threads

There is no "main thread". Live access runs on the thread that owns the identity (protagonist, entity, region), so Folia style region threads work.

- **Packets are never held.** Verdicts on wire events read only network safe data: stored values, holds, formulas, and `Live` mirrors (last committed value, at most one tick old). Live traits are forbidden there.
- **Live access on world events only**, on the owning thread.
- **Other threads** read the last committed mirror value without a hop.
- **Codegen rejects violations** at build time.

Verdict handlers never suspend: they run inline (for example inside a Paper event) and read cached stored data.

### Suspending handlers

After handlers may suspend. A suspended handler is cancelled when any value it resolved through a parameter is removed (step ended, stored value removed, member gone, a mirror `Removed` including `because = Tracking`). `Changed` never cancels it. Stale writes are also dropped by the owner generation check: an event for a finished step is dropped ([interactions.md](interactions.md)).

## Chain

A chain is how entries lead to entries. Links fire, entries do not: nothing follows links automatically.

### Firing and `Triggered`

Firing a link emits an ordinary `Triggered<E>(entry, group, context)` event per linked entry, queued like `emit`. The entry is a field of the event, and the subject is the group.

```kotlin
entry.triggers.fire(context)
entry.triggers.random(seed).fire(context)
chosen.link.fire(context)
```

Actions, steps, and triggers share this one flow:

- An **action** entry's handler on `Triggered<E>` does its work and fires its links.
- A **step** entry's handler calls `startStep(...)`; whoever ends the step (`step.end()`) fires the next links. Steps, interactions, clashes, and rejoin are in [interactions.md](interactions.md).
- A **trigger** is an ordinary handler on a world event that fires an entry's links:

```kotlin
@Handler
fun PlayerChat.containsText(trigger: Candidate<PlayerMessageContainsTextEventEntry>) {
    if (trigger.matches(this)) trigger.triggers.fire(context)
}
```

Extra needs are extra parameters (traits, stored values, formulas). Entries stay plain data; trigger code only says it fired, the core follows the links. Book narrowing happens inside `fire`. Firing for a group instead of the current subject (`fire(context, for = group)`) is described in [interactions.md](interactions.md).

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
    val changes: Var<Changes, InteractionContext>
}
```

`changes` replaces legacy modifiers. Two styles:

```kotlin
// Shortcut: apply changes, then fire triggers (legacy order; the next entry sees the changes).
entry.complete(context)

// Manual, when an entry needs another order or timing.
entry.changes(context).apply()
entry.triggers.fire(context)
```

Extra update fields (dialogue options) are applied the same way: `option.changes(context).apply(); option.triggers.fire(context)`. What `apply()` commits and how it handles conflicts is in [stored-data.md](stored-data.md).

## Commands

A command is three things at once: a hold (it exists for a player now, contributed by a derive), an event (it ran, and can be denied), and data (the tree).

### Shape

A contribution is a data class whose `nodes` are built with a small data DSL: `literal`, `argument`, `runs<Event>()`. A node that can run names a typed event whose fields are filled from the path arguments by name; KSP checks this on every path.

```kotlin
data class ClaimReward(val amount: Int) : Event

// inside a contribution
val nodes = literal("claim") {
    argument("amount", Int) { runs<ClaimReward>() }
}
```

- **One tree per player.** Contributions merge; there is no path or branch concept. A root command is just a literal node. Each contribution inserts its nodes where they match existing ones; removing it prunes nodes left with no executable and no children.
- **Merging.** The same literal, or the same argument name and type, merges. Two runs at one node are settled by hold priority, which also resolves the same name from two books.
- **Where contributions come from.** Derives: state dependent commands (`/claim` while a reward waits), commands available only during an interaction (`/accept` during an offer), and content commands through `Candidate<CustomCommandEntry>`.
- **Applicability.** Commands from a book that does not apply to a player are hidden for that player (Brigadier `requires`); the tree is resent when applicability changes.
- **Running.** Running a node emits its event, so ordinary handlers decide (deny blocks it) and react.
- **Who it runs for** is separate from player arguments: a command can run for another player, or for the caller while a player argument stays usable in formulas and context.

### Content commands

`CustomCommandEntry` and its argument entries build the nodes. They are manifest (audience) entries, not sequence triggers. A node with triggers runs `ContentCommandRan(node, args)`, whose handler fires the node's triggers with the arguments as context.

`/tw fire` takes the target first (`/tw fire <player> <entry>`), so suggestions follow the target.

### Must also cover

The shape must express the legacy command features: any tree shape in code and content, self or others, suggestions from state, console sender, detecting and cancelling other plugins' commands, blocking during interactions and re-running, running commands, and hot publish. Commands run from outside the game world are not needed. Prefer structured data over lambdas, with codegen doing the checking.

## Build time checks

KSP rejects, for handlers: unresolvable parameters, live access in wire verdicts, handlers needing two live anchors, and command nodes whose event fields do not match the path arguments. The full check list is in [live-data.md](live-data.md).

## Open

- The same occurrence reaching a handler twice through forwarding.
- What `force` does for `/tw fire`.
- Event declaration details (how an event names its subject and typed roles in code) are settled when the event core is built.
