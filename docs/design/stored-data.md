# Stored data

Stored data is everything Typewriter saves about the world of a realm: quest stages, coins, reputation, a running step, owed rewards, durable timers. There is one storage concept, `Stored`. It is the stored value from [the data storage vision](../vision/data-storage.md) with keys that decide what it is about and how long it lives.

This file covers identities, stored values and their keys, change operations, transactions, creator variables and their reactions, `Due`, offline changes, and derives with a `Stored` result. For how handlers receive stored values as parameters, see [events-and-handlers.md](events-and-handlers.md). For live values that are never saved, see [live-data.md](live-data.md). For the formula language that reads and changes stored data, see [formula-language.md](formula-language.md). For type changes of stored data, see [migrations.md](migrations.md).

## Identity

An identity is something stored data can be about. Identities are the only types allowed as keys.

| Identity | What it is |
| --- | --- |
| `Protagonist` | The engine neutral person: a Minecraft player, also the panel user. Owns stored data. Its id is the account it comes from, `Protagonist(PrincipalId("minecraft", <uuid>))` or `Protagonist(PrincipalId("user", <user id>))`, so an engine knows it at join without asking the realm. |
| `Step` | One running step of an interaction. |
| `Interaction` | The running group of steps (see [interactions.md](interactions.md)). |
| `Holder` | An identity that can run a step or hold a Hold: `Protagonist`, `Session`, `GroupIdentity`, or `Engine`. |
| `Session` | One connection of a protagonist (see [live-data.md](live-data.md)). |
| `Engine` | One engine, by its stable topology engine id; survives restarts and ends when the engine leaves the topology (see [live-data.md](live-data.md#session)). |
| An entry type (`NpcEntry`) | A published entry: a `Resource` typed field in a runtime value (stored data, holds, live values, events) is that entry's identity, stored as its `ResourceId` plus its instance path, read as the current published version, and ended when the entry is unpublished. Authored fields keep `Ref<Contract.Side, T>`; KSP rejects a `Resource` typed field in an authored type. |
| `BoundPath<X>` | A place in authored content: an entry plus a path through fields, list items, and map rows, in its portable `value_location` form. Reads the current published value. Only the location is its identity. |
| `GroupIdentity` | What members belong to. Our group entries use `EntryGroup(entry, key)`, such as `EntryGroup(islands, "42")`, so it ends with the entry. Each group entry exports its own type through `bind` (`islands` gives `Island`). `Snapshot(interaction)` ends with the interaction. |
| Book instance | One instance of a book, a path on the identity of each [copy](formula-language.md#copies-at-publish). |

`Identity` is a catalog parent type. Every type above has it as a parent, so the catalog, KSP, and realm admission can all ask "is this an identity?" the same way.

### Identities end

Every identity has a lifetime:

- A step or interaction ends when it finishes.
- A session ends when no engine reports it for longer than the grace of its engine kind.
- An identity defined by an entry ends when that entry is removed by a publication.
- An identity ends when an identity inside it ends (decided 2026-11-05), so `EntryGroup(islands, "42")` ends with `islands`.
- A `BoundPath` ends when its place is gone, for example when its list item is removed.

Owners such as steps and interactions carry a generation. An event addressed to a step whose generation has finished is dropped, and a stale write from a finished step is dropped by the same check.

## Stored values

A stored value is declared with `stored(name, keys, value, default)`:

- `name`: the storage name.
- `keys`: a record whose fields are the identities the value is about.
- `value`: the record or type of the data itself.
- `default`: the value a reader sees when nothing is stored.

Being a key is a property of the storage declaration, not of a type. The same type can be a key in one declaration and plain data in another, so the type catalog needs no key marker.

### Kotlin form

In extension code a stored value is a Kotlin type with `@Key` fields. KSP splits it into the same `stored(...)` call a creator variable makes, so the realm sees one form.

```kotlin
// About one protagonist and one NPC entry.
data class Reputation(
    @Key val protagonist: Protagonist,
    @Key val npc: NpcEntry,
    val value: Int,
) : Stored

// Symmetric: order free, any size.
data class Friendship(@Key val pair: Set<Protagonist>, val level: Int) : Stored

// Ordered: two keys of one kind, each with its own meaning.
data class Debt(@Key val from: Protagonist, @Key val to: Protagonist, val amount: Int) : Stored

// One moment about a running step, removed with the step.
data class Skipped(@Key val step: Step, val at: Instant) : Stored
```

Developer defined stored types are Typewriter types (`@TypewriterType` with an id and a revision), because they are persisted. The migrator converts their data between revisions (see [migrations.md](migrations.md)).

### Keys

| Keys | Meaning |
| --- | --- |
| No key | Global: one value for the whole realm. |
| One key | About one identity (`Skipped` on a `Step`). |
| Several keys | About several identities, ordered (`Debt(from, to)`). |
| `Set<I>` key | Symmetric (`Friendship(pair)`): order free, any size, filled from all event fields of that kind, stored sorted. |

One validation rule runs both in KSP and in realm admission: every field of the keys record is an `Identity` type, or a `Set` of one. A key field of any other type is a build error (KSP) or a realm error (creator variables).

### Owners and lifetime

The keys are the owners. A stored value is removed automatically when any of its key identities ends. A step's marker disappears with the step; a value keyed by a session disappears when the session ends; a value keyed by an entry disappears when that entry is unpublished. Nothing can leak after a crash, a server move, or a hot publish.

A stored value without keys is global and has no owner. That is the escape hatch for extension code that needs data with no natural lifetime.

Stored values carry no time limit of their own. Time based behaviour is built from [reactions](#reactions) and [`Due`](#due).

### Lifecycle events

Every stored value, whether written by a derive, by a step, or by code, emits:

| Event | When |
| --- | --- |
| `Added<T>` | A value appears for a set of keys, or a live handler starts tracking one (`because`). |
| `Changed<T>(old, new)` | The value at those keys changes. |
| `Removed<T>` | The value is removed (cleared, or a key identity ended), or a live handler stops tracking it (`because`). |

`Changed<D>` also works on a storage declaration: `Changed<Reputation>`, or `Changed<Variable<K, T>>` for a creator variable. `Changed` handlers run after the commit of the transaction that caused the change. `because` is defined in [live-data.md](live-data.md#added-changed-removed-and-because).

### Reading

Handlers take a stored type as a parameter; the keys are filled from the event (see [events-and-handlers.md](events-and-handlers.md)). A nullable parameter is optional.

```kotlin
@Handler
fun Confirm.advance(running: Running<SpokenDialogueEntry>) = ...
```

Kotlin reads a `Settable` only inside a [transaction function](#transaction-functions) (decided 2026-11-04). A `get()` anywhere else does not compile, so a handler cannot read a value and write it back by accident. Kotlin cannot see where a plain value came from, so `Set(event.new + 1).attempt()` with a value from an event or parameter still compiles.

Formulas read stored values through generated readers. Each `stored()` declaration generates a `Settable<T>` reader that takes the keys as parameters filled from scope, and `.all` reads every key:

```kotlin
reputation(protagonist, npc): Settable<Int>
```

In formula text the keys are implicit, so a dialogue line reads `reputation` and a changes field writes `reputation += 5`. When a key cannot be filled from scope, the realm reports it on the field.

Stored values are indexed per type, so finding every value of a type, or every value for one key, costs about the number of values found.

### Where values live at runtime

The guideline is **store moments, not counters**: `startedAt`, `skippedAt`. Steps then rarely write, and a restarted step is a real resume.

All stored data is owned by the realm, also the values of a running step, and every write is a transaction (decided 2026-11-03). There is no single writer: the realm serializes writes, and a generation check drops a stale write. Fast changing state that needs no saving lives in a `Runtime`. Engines tell the realm which stored keys they currently demand and receive `Changed<X>` pushes in commit order on their own subject (see [live-data.md](live-data.md#lost-pushes)).

Stored data and `Due` are never put on NATS streams: they need transactions and exactly once delivery, which the realm owns.

## Change operations

Stored data changes only through a small native set of operations. The realm's storage applies them itself, also when no engine is running.

| Operation | Applies to | Effect |
| --- | --- | --- |
| `set` | any | Replace; the last write wins. |
| `add` | numbers | Add an amount; concurrent adds both count. |
| `multiply` | numbers | Multiply by a factor. |
| `max`, `min` | comparable | Keep the larger or smaller (`best_time.lowerTo(t)`). |
| `setIfAbsent` | any | Set only when nothing is stored (`first_met ?= now`). |
| `append`, `remove` | lists, sets | Add or remove one element. |
| `addAll`, `removeAll` | lists, sets | Bulk variants. |
| `put`, `remove(key)` | maps | Set or remove one key of a map. |
| `clear` | any | Remove the value. |
| `require(condition, message)` | guard | Checked at commit; when false the whole transaction fails, with the optional message. |

Every operation can target a path inside a value: `stats.kills += 1`, `notes[npc] = "met"`.

There is no general `update { old -> new }`, no bounded add, no list insert or move, and no toggle. `add` being native is what fixes the legacy lost update: two engines adding coins at once both count, where read, compute, write would lose one.

### Operators are providers

Formula operators are plain provider functions in the standard library. They need the `Transaction` context and record the operation on it (decided 2026-11-04), so Kotlin and formula text share one set, and assigning in a pure field is an error because no `Transaction` is in scope:

```kotlin
context(tx: Transaction)
operator fun Settable<Int>.plusAssign(amount: Int) = tx.add(this, amount)
```

`+=` and `-=` are stored as `add`; `=` is `set`; `*=` is `multiply`; `?=` is `setIfAbsent`.

### Changes fields

An update field has the type `Var<Changes, C>`. Its syntax (change lines, their order, purity) is in [formula-language.md](formula-language.md#changes-fields). Evaluating the field writes nothing; the entry commits it through `attempt()`. `now` inside a changes field is the realm commit time.

## Transactions

`Changes` are committed with `attempt()`. One call is one transaction: all of its operations commit, or none do.

```kotlin
entry.changes(context).attempt()
entry.triggers.fire(context)
```

Most entries use the `Triggerable` shortcut `entry.complete(context)`, which applies the changes and then fires the triggers, so the next entry sees the changes (see [events-and-handlers.md](events-and-handlers.md)). Extra update fields, such as a dialogue option's changes, are applied the same way: `option.changes(context).attempt()`.

The engine predicts and the realm decides (decided 2026-11-04):

1. The engine evaluates the changes formula against its local view and applies the result there, so the next entry reads it.
2. The engine sends the formula reference and its revision, the inputs, and every live value the formula read. A provider that needs the server (`papi`) counts as a live read: the engine reads it once and sends the value.
3. The realm evaluates the formula against the committed values, outside the database transaction, so a slow provider holds up no commit. It then commits optimistically.
4. On a conflict, the realm evaluates again with the same inputs and the updated stored values, and retries. The engine is not involved.

So a line like `if (quest.coins > 100) quest.rank = gold` always decides on the committed value, never on a stale one. The realm has the extension artifacts to do this (`DefaultRealmRuntimeFactory.kt:129`). How long the realm keeps old revisions for an engine still on one during a rollout is open for the plan.

A transaction fails as a whole when a `require` guard is false, or when evaluating the formula throws (a provider error, the recursion limit). A failed transaction applies nothing. `Changed<X>` handlers run only after a successful commit.

### Transaction functions

Decided 2026-11-04. Kotlin writes a stored value only inside a transaction function, also for a single operation. The write operations need the `Transaction` context, so a write anywhere else does not compile. Codegen generates the call a handler uses, and the same function runs on the engine as the prediction and on the realm as the decision.

```kotlin
@Transaction
context(tx: Transaction)
fun addCoins(protagonist: Protagonist, amount: Int) {
    coins(protagonist) += amount
}
```

`require` exists only on `GuardedTransaction`, a `Transaction` that the signature declares. KSP reads the signature, so a guard cannot hide in a function body. A guarded function can call a plain one; a plain one cannot call a guarded one. For a guarded function, the generated `attempt()` always waits. The text checker treats a formula as guarded when it contains `require` or calls a guarded function.

```kotlin
@Transaction
context(tx: GuardedTransaction)
fun pay(protagonist: Protagonist, price: Int) {
    require(coins(protagonist).get() >= price, "Too poor")
    coins(protagonist) -= price
}

when (val paid = Pay(protagonist, 10).ensure()) {
    Committed -> give(sword)
    is Refused -> player.sendMessage(paid.message)
}
```

An `OnWrite` reaction with a guard makes every write to that variable guarded, also when the writer has no `require`. The text checker sees this from the variables a field writes. Kotlin code is compiled before a creator adds a reaction, so the engine sees it while predicting, from the variables the function wrote.

A `Triggerable` entry gets `refused` links, which fire when its changes are refused (decided 2026-11-04).

Kotlin has two calls and no `apply()` (decided 2026-11-04). `attempt()` waits only when the write is guarded; `ensure()` always waits. Both return `Committed` or `Refused(message)`. Kotlin's return value checker (`-Xreturn-value-checker`) reports an ignored result, so a refusal cannot be dropped by accident.

Kotlin reaches a creator variable only as an argument, never by looking one up (decided 2026-11-04), and stored types declared in Kotlin have no reactions. So the guard is known from the signature and the arguments, without running the function or depending on which branch it takes.

```kotlin
AddCoins(entry.coins(context), 5).attempt()
```

### Which fields are guarded

The realm answers this on the query graph, next to `check(formula)`, and the engine gets the answers with the published content:

```kotlin
fun guarded(field): Boolean =
    check(field).hasRequire
        || check(field).calls.any { it.guarded }
        || writes(field).any { guardedVariable(it) }

fun guardedVariable(variable): Boolean =
    reactions(variable).filterIsInstance<OnWrite>().any { guarded(it.changes) }
```

An edit reruns only what read the change, so adding a guard to an `OnWrite` reaction reaches every field that writes that variable, on any page. A reaction loop is a query cycle, reported as an error.

The panel gets the answers from the realm through a `WatchGuards` subscription per page and reads them as `expressions.changes.guarded`. The `refused` row (under `changes` in the inspector) and port (on the graph node) appear only when the field is guarded. When the guard goes away but `refused` links remain, the row stays with a warning, so no links silently disappear.

With a link on `refused`, the link wins and the next entry can read `refused.message`. With no link, the message goes to the subject.

The shape of the generated call is left for the plan.

### Who waits for a commit

Chosen 2026-11-03 with the [tick pipeline](events-and-handlers.md#tick-pipeline). A chain waits for the realm only at a `require` guard:

- **No guard.** The write applies to the engine's local view at once, so the next entry reads it, and goes to the realm behind the chain. The chain does not wait.
- **Reads do not wait (decided 2026-11-04).** A read does not make a write wait, because the realm evaluates the transaction again against the committed values and the engine reruns nothing. The next entry can briefly act on a stale local value; the stored result stays correct.
- **With a guard.** The chain waits for the realm's answer, so nobody spends what they do not have. Earlier writes go first, in order.
- **`ensure()`.** Kotlin code that needs the committed result writes `AddCoins(protagonist, 5).ensure()` instead of `AddCoins(protagonist, 5).attempt()`, and the chain waits for the realm's answer.
- **Batching.** An engine keeps one commit in flight; what arrives meanwhile shares the next commit. Each write has a per engine id, so a retry applies once.
- **The answer.** The committed value replaces the local one. What a player saw can briefly differ when another engine wrote the same key. The stored result stays correct.

Accepted costs for writes without a guard: when an engine crashes, a player may have seen the result of a write that never reached the realm. The window is about one realm round trip. While the realm is down, these chains keep running and their writes wait; guarded chains wait too. A limit on waiting writes during a long outage is open for the plan.

## Variables

A variable is creator declared stored data. It is a static entry: it declares data and is never triggered.

```kotlin
interface StaticEntry : Entry

Variable<K, T>(name, keys: Map<String, Type>, type: Type, default, reactions)
```

| Field | Meaning |
| --- | --- |
| `name` | Name in formulas (any name; backticks when it is not identifier like). |
| `keys` | The keys record K: named identity types. Empty means global. |
| `type` | The value type T: a catalog type or a creator type. |
| `default` | What readers see when nothing is stored. |
| `reactions` | List of `Reaction<K, T>` (see below). |

The variable's `dynamic()` binds K and T from its fields and calls `stored(name, keys = K, value = T, default)`. This is the same call KSP generates for a Kotlin `@Key` type, so formulas, readers, `Settable` members, and checks treat both alike.

Examples a creator might declare:

| Name | Keys | Type | Default |
| --- | --- | --- | --- |
| `coins` | `protagonist: Protagonist` | `Int` | `0` |
| `mood` | `npc: NpcEntry`, `protagonist: Protagonist` | `Mood` | `Neutral` |
| `island_bank` | `island: Island` | `Int` | `0` |

Variables are for data. Anything computed is a formula function instead: `protagonist.inventory.count(item)` needs no variable.

Storage is keyed by the variable's entry id, so renaming a variable keeps its data. Changing its type or keys goes through a migration (see [migrations.md](migrations.md)).

### Reacting to a variable

A handler on `Changed<Variable<K, T>>` reacts to writes. Starting a quest when a value crosses a line is an event entry on `Changed<Variable>`, not a reaction.

## Reactions

A reaction is behaviour attached to a variable. Reactions only change data; they never start interactions or touch the world.

```kotlin
interface Reaction<K, T> {
    val changes: Var<Changes, ReactionScope<K, T>>
}

interface ReactionScope<K, T> { val keys: K; val value: Settable<T>; val previous: T? }
```

Each reaction kind is a type plus handlers in an extension.

| Reaction | Runs | Typical use |
| --- | --- | --- |
| `OnWrite<K, T>` | Inside every write's own transaction. | Cap a value, guard with `require`, write a history variable, trim a list. |
| `AfterWrite<K, T>(schedule, from)` | At the next time of `schedule: Var<Schedule, ReactionScope<K, T>>` after the first or last write (`from: Write`, `First` or `Last`). `changes` defaults to `clear`. | Timed values, cooldowns, auction ends. |
| `Every<K, T>(schedule)` | For every stored key, on a `Schedule` (see [Due](#due)). | Daily resets. |

Example changes formulas:

```kotlin
// OnWrite on coins: never negative.
require(value >= 0, "coins cannot go negative")

// AfterWrite(Interval(10.minutes), from = Last) on a buff: no formula, the default clears it.

// Every(CronSchedule(midnight)) on savings: daily interest.
value = value * 1.01
```

### How timed reactions fire

Timed reactions run on the realm through `Due`, so there is one clock (decided 2026-11-04). The write and its timer commit in one transaction; one core stored only handler runs the reaction's changes when the timer elapses. Both reactions share one timer type and that handler; only the keys differ:

| Reaction | Declaration | Keys | Handler runs |
| --- | --- | --- | --- |
| `AfterWrite` | The reaction's place, such as `coins.reactions[r7]` | `K`, the same keys as the value | Once: the keys are filled from the timer |
| `Every` | The reaction's place | None | Once per stored value: the keys are free, so the parameter is a query |

- On a write, `at = schedule.next(now)` commits with that write (decided 2026-11-04). `null` arms nothing, so a `Once` in the past never fires. `AfterWrite` never sets `repeat`; `Every` always does, and it takes a plain `Schedule` because it has no single key for a formula to read.
- A reaction's own write does not arm its own timer, so `AfterWrite(from = Last)` with `value = 0` does not repeat forever.
- Clearing a value removes its armed `AfterWrite` timer, so a timer never brings a cleared value back.
- A refused timed reaction is dropped and reported, not retried: the same inputs would refuse again.

A timer needs no record key (decided 2026-11-04). `K` exists only at runtime, so the variable declares each timer with the same builder as the value. The declaration is the reaction's place, so the entry is not a key field, and each book instance gets its own timers because it duplicates its entries:

```kotlin
// In Variable.dynamic(). The exact form is for the layer 7 plan.
stored(name, keys = K, value = T, default)
stored(afterWritePlace, keys = K, value = ReactionTimer, default = null)
stored(everyPlace, keys = {}, value = ReactionTimer, default = null)

data class ReactionTimer<K, T>(
    override val at: Instant,
    override val repeat: Schedule? = null,
) : Due

@Handler
fun <K, T> Elapsed<ReactionTimer<K, T>>.run(value: VariableValue<K, T>) {
    val _ = reaction.changes(ReactionScope(value)).attempt()
}

// Rows
// coins               { protagonist: alex }
// coins.reactions[r7] { protagonist: alex }  an AfterWrite timer
// coins.reactions[r8] { }                    an Every timer
```

Kotlin entries see plain lists without item ids; the runtime gets the ids from `members(path)` and builds the place. A timer ends with its keys, or when publishing removes its reaction. `K` and `T` are not Kotlin types for a creator variable, so the handler is generic and `VariableValue` is one stored value, not the entry. The names `VariableValue` and `ReactionScope(value)`, and how the handler reaches `reaction`, are for the layer 7 plan. One handler serving both cases relies on how a dynamic `K` resolves, so the plan proves that first.

A timer is a stored value, so a formula can read when it elapses, through the exports of `stored()` ([formula-language.md](formula-language.md#scope-and-exports)). Time left and next reset read the same way, which keeps what legacy offers as `time.expires` (`TimedFactEntry`, `CronFactEntry`, `CountdownFact`). How a formula names a reaction's timer is for the layer 7 plan.

`Every` is a configured source, like `Tick<C>` (decided 2026-11-04). Nothing writes to the value when a creator publishes an `Every`, so the source arms its timer. It compares every published `Every` with its timer at startup and after each publish, and writes only differences, so a lost row heals and a schedule edit applies. The core event runtime already recomputes `Demand<C>` on publish ([events-and-handlers.md](events-and-handlers.md#configured-events)). An extension's own timed reaction can reuse `ReactionTimer` and the handler: a type, a way to arm, and nothing else.

```kotlin
class EverySource : ConfiguredSource<Elapsed<ReactionTimer<*, *>>, Every<*, *>> {
    override fun open(demand: Demand<Every<*, *>>, sink: Sink<Elapsed<ReactionTimer<*, *>>>) =
        demand.watch { reactions -> // at startup, and after each publish
            reactions.forEach { (place, every) ->
                val _ = ArmEvery(place, every.schedule).attempt()
            }
        }
}

@Transaction
context(tx: Transaction)
fun armEvery(place: BoundPath<Every<*, *>>, schedule: Schedule) {
    val timer = reactionTimer(place) // by place at runtime, no generated accessor
    if (timer.get()?.repeat != schedule) {
        timer.set(ReactionTimer(at = schedule.next(now), repeat = schedule))
    }
}
```

The `Demand<C>` API (`watch`, `(place, every)`) and how the event names its configuration are for the layer 7 plan. A midnight between the content switch and the arming is skipped once. `AfterWrite` needs no source: it arms on the next write, and a schedule edit leaves armed timers at their old time.

Each key is its own transaction, so a refusal or conflict affects only that key. The run is not one moment: at many keys, values change a little apart.

### Legacy timed data

Legacy timed, cron, countdown, and per session data needs no special storage. Each becomes a variable: timed values and cron values use `AfterWrite` with an `Interval` or a `CronSchedule`, countdowns use `AfterWrite` with a `Once`, and per session values use a `Session` key, so they are removed when the session ends.

## Due

`Due` is durable time: a stored value with a time (decided 2026-11-04). It is an ordinary `@Key` stored type plus a core source:

```kotlin
interface Due : Stored {
    val at: Instant
    val repeat: Schedule? get() = null
}

data class Elapsed<D : Due>(val due: D) : Event

interface Schedule {
    fun next(after: Instant): Instant? // null: never again
}

data class CronSchedule(val cron: CronExpression, val zone: ZoneId) : Schedule
data class Interval(val every: Duration) : Schedule
data class Once(val at: Instant) : Schedule
```

KSP reads only signatures, so it finds a timer by its class and generates its `stored()` call and accessor like any stored type. Keys follow the normal [key rule](#keys), and writing again at the same keys replaces the timer. Fields other than keys are ordinary data, also carried to the handler:

```kotlin
data class RewardDue(
    @Key val protagonist: Protagonist,
    val amount: Int,
    override val at: Instant,
) : Due

@Transaction
context(tx: Transaction)
fun promiseReward(protagonist: Protagonist, amount: Int) {
    rewardDue(protagonist).set(RewardDue(protagonist, amount, at = now + 1.hours))
}

@Handler // realm, exactly once
fun Elapsed<RewardDue>.pay() {
    val _ = AddCoins(due.protagonist, due.amount).attempt()
}
```

A value that should only end at a time needs no handler, because firing removes the row and stores the time once:

```kotlin
data class Highlighting(
    @Key val viewer: Protagonist,
    val region: RegionEntry,
    override val at: Instant,
) : Due
```

`Schedule` is an open catalog type, so an extension can add a kind such as `RandomInterval(min, max)`, in a part the realm loads (decided 2026-11-04). `at` is saved, so a random time is picked once. How a `CronSchedule` treats a daylight saving change is for the layer 7 plan.

The realm is the clock. One core source per `Due` type reads the earliest `at` across that type's declarations (the plan adds an index on `at`). Firing is one transaction: it removes the row, or sets `at = repeat.next(now)`, and adds a pending row per `Elapsed<D>` handler ([Offline changes](#offline-changes)). The pending row keeps the fired value, because the timer is already gone or moved on. Each handler then runs like any stored only reader: its writes and clearing its row are one transaction. A `Due` is a pending row with a time.

Firing is an ordinary write, so `Removed<D>` or `Changed<D>` also fire. `Elapsed<D>` is what tells firing apart from cancelling.

Handlers on `Elapsed<D>` are stored only (decided 2026-11-04). The realm reaches engines only through stored commits, no events are queued for offline protagonists, and an event without an origin is best effort ([live-data.md](live-data.md#routing)), so a live effect at a time goes through owed state:

```kotlin
data class ReminderDue(@Key val protagonist: Protagonist, override val at: Instant) : Due
data class Reminder(@Key val protagonist: Protagonist) : Stored

@Handler // realm, exactly once
fun Elapsed<ReminderDue>.owe() {
    val _ = OweReminder(due.protagonist).attempt()
}

@Handler // engine: at once if online, otherwise at join
fun Added<Reminder>.send(reminder: Reminder, chat: HasChat) {
    when (ClaimReminder(reminder.protagonist).ensure()) {
        Committed -> chat.send("Your buff is ready")
        is Refused -> Unit
    }
}

@Transaction
context(tx: GuardedTransaction)
fun claimReminder(protagonist: Protagonist) {
    require(reminder(protagonist).get() != null)
    reminder(protagonist).clear()
}
```

Every engine holding the protagonist sees `Added`, and the claim picks one winner. A crash between the claim and the effect loses the effect and never doubles it.

Guarantees:

- **Exactly once effect.** A pending row and the handler's writes clear together, so a crash reruns only what is not done.
- **No overlap.** A handler still running when its `Due` fires again keeps its row and runs again, instead of running twice at once.
- **Query handlers resume.** A query handler on a `Due` runs once per match; its pending row also holds its progress, so a crash resumes at the next match.
- **Catch up.** Dues that passed while nothing ran fire once on startup, and the next `at` counts from `now`.
- **Lifetime.** A `Due` follows the normal [owners](#owners-and-lifetime) rule: it is removed when any key identity ends.
- **Precision** is seconds and up. Below a second, use `Tick`.

## Derive with a `Stored` result

A `@Derive` function with a `Stored` result keeps a stored value in sync with its inputs. It returns the value, or `null` for none. The receiver is a stored type.

```kotlin
@Derive
fun QuestStage.owed(): SwordOwed? = ...
```

Rules:

- The result is saved, so it survives server moves, rejoins, and multiple servers.
- An equal result writes nothing; a different one is one stored write, emitting `Added`, `Changed`, or `Removed` as usual.
- Stored derives are pure over their tracked inputs and rerun only when an input changes.
- A cycle between derives is a realm check error.
- A stored derive that reads a mirror keeps its last result when that input vanished by `Tracking` (a quit or server move). The realm warns that such a derive cannot run offline.

The same `@Derive` shape with a `Hold` result is live and never saved (see [interactions.md](interactions.md)); with a `Live` result it is a computed mirror (see [live-data.md](live-data.md)).

## Offline changes

Stored data can change while its protagonist is offline, for example through a panel edit or a `Due`.

- Stored only derives and handlers run on the realm (decided 2026-11-04), through the same evaluator as transactions, also when no engine runs. They cannot touch Bukkit, so KSP requires them in a part the realm loads. Each one is evaluated outside the database transaction, so a slow one holds up other readers and never a commit; a stuck one is timed out and reported.
- No stored derive or stored only handler loses work (decided 2026-11-04). The commit also inserts a pending row per reader and key, keeping the oldest old value; the row exists only while work waits. The reader's writes and clearing the row are one transaction, so running twice has one effect. A newer change keeps the row and runs the reader again. Steps can merge: a handler may see one `Changed(9, 12)`, and a value going 9, 10, 9 shows no change. This is level triggered like Kubernetes controllers, and the same model as `Due`. A handler that needs every step writes its own record as part of the write.
- Firing links needs an engine, because a chain may need a player (decided 2026-11-04). A handler that fires links runs where its subject is live, so it does not run while the subject is offline; firing from the realm is an error, not a silent no-op. This matches legacy, which watches facts only for online players.
- Live reactions to a moment can be missed, and missed events are never replayed. The guideline is **store what is owed, not what happened**: a derive produces owed state, and a live handler acts on it whenever the protagonist is online.

The handler asks for a live trait, so it runs only while the protagonist is online. Like a hold's `Added<H>`, it fires per live connection while the value exists: when `SwordOwed` appears (`because = Value`), and again at each join or server move (`because = Tracking`). So it must be safe to repeat. A stored only handler fires once, on the realm.

A derive owns its result, so a handler cannot remove `SwordOwed`: the next input change would derive it again. The derive reads what was already given, and a guarded transaction picks one winner:

```kotlin
@Derive
fun Coins.owed(given: SwordGiven?): SwordOwed? =
    if (value >= 10 && given == null) SwordOwed(protagonist) else null

@Transaction
context(tx: GuardedTransaction)
fun claimSword(protagonist: Protagonist) {
    require(swordGiven(protagonist).get() == null)
    swordGiven(protagonist).set(SwordGiven(protagonist))
}

@Handler
fun Added<SwordOwed>.give(owed: SwordOwed, inventory: HasInventory) {
    when (ClaimSword(owed.protagonist).ensure()) {
        Committed -> inventory.give(sword)
        is Refused -> Unit
    }
}
```

The realm and the inventory cannot commit together, so a crash between the two steps costs something. This is the pattern to teach and the one the layer 6 demo uses: claim first, so a crash can lose a reward but never duplicate one. It is not a framework rule; an extension may choose the other order.

A realm check warns about live handlers on `Changed<X>` when X can change offline.

## Checks

The stored data checks from the one check list:

| Where | Severity | Check |
| --- | --- | --- |
| KSP | build error | A key field that is not an identity or a `Set` of one. |
| KSP | build error | A live parameter on an `Elapsed<D>` handler. |
| Realm | error | Keys of a stored reader that cannot be filled from scope. |
| Realm | error | A cycle between derives. |
| Realm | warning | A live handler on `Changed<X>` when X can change offline. |
| Realm | warning | A stored derive reading mirrors (not offline capable). |

Errors block publication; warnings never do.

## Open

- Variables: the direction is adopted, but details such as the variable editor are still in progress.
- Stored reads as query graph inputs (type plus partial key), so a stored commit reruns the realm checks and searches that read it (layer 10, [closed-beta-roadmap.md](closed-beta-roadmap.md)).
