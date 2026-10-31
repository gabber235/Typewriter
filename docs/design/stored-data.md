# Stored data

Stored data is everything Typewriter saves about the world of a realm: quest stages, coins, reputation, the marker of a running step, owed rewards, durable timers. There is one storage concept, `Stored`. It is the stored value from [the data storage vision](../vision/data-storage.md) with keys that decide what it is about and how long it lives.

This file covers identities, stored values and their keys, change operations, transactions, creator variables and their reactions, `Due`, offline changes, and derives with a `Stored` result. For how handlers receive stored values as parameters, see [events-and-handlers.md](events-and-handlers.md). For live values that are never saved, see [live-data.md](live-data.md). For the formula language that reads and changes stored data, see [formula-language.md](formula-language.md). For type changes of stored data, see [migrations.md](migrations.md).

## Identity

An identity is something stored data can be about. Identities are the only types allowed as keys.

| Identity | What it is |
| --- | --- |
| `Protagonist` | The engine neutral person: a Minecraft player, also the panel user. Owns stored data. |
| `Step` | One running step of an interaction. |
| `Interaction` | The running group of steps (see [interactions.md](interactions.md)). |
| `Session` | One connection of a protagonist (see [live-data.md](live-data.md)). |
| `Ref<E>` | Any published entry. |
| `ItemRef<X>` | One item of a list field inside an entry, by v1 `ItemId`. Ends when the item is removed. |
| Group identity | A (group entry, key) pair such as `Group(islands, "42")`. Each group entry exports its own identity type through `bind` (`islands` gives `Island`). |
| Book instance | One instance of a book (see [formula-language.md](formula-language.md)). |

`Identity` is a catalog parent type. Every type above has it as a parent, so the catalog, KSP, and realm admission can all ask "is this an identity?" the same way.

### Identities end

Every identity has a lifetime:

- A step or interaction ends when it finishes.
- A session ends when no engine reports it for longer than the grace of its engine kind.
- An identity defined by an entry ends when that entry is removed by a publication.
- An `ItemRef` ends when its list item is removed.

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
    @Key val npc: Ref<NpcEntry>,
    val value: Int,
) : Stored

// Symmetric: order free, any size.
data class Friendship(@Key val pair: Set<Protagonist>, val level: Int) : Stored

// Ordered: two keys of one kind, each with its own meaning.
data class Debt(@Key val from: Protagonist, @Key val to: Protagonist, val amount: Int) : Stored

// The marker of a running step: stores a moment, not progress.
data class Speaking(@Key val step: Step, val entry: Ref<DialogueEntry>, val startedAt: Instant) : Stored
```

Developer defined stored types are Typewriter types (`@TypewriterType` with an id and a revision), because they are persisted. The migrator converts their data between revisions (see [migrations.md](migrations.md)).

### Keys

| Keys | Meaning |
| --- | --- |
| No key | Global: one value for the whole realm. |
| One key | About one identity (`Speaking` on a `Step`). |
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
| `Added<T>` | A value appears for a set of keys. |
| `Changed<T>(old, new)` | The value at those keys changes. |
| `Removed<T>` | The value is removed (cleared, or a key identity ended). |

`Changed<D>` also works on a storage declaration: `Changed<Reputation>`, or `Changed<Variable<K, T>>` for a creator variable. `Changed` handlers run after the commit of the transaction that caused the change.

### Reading

Handlers take a stored type as a parameter; the keys are filled from the event (see [events-and-handlers.md](events-and-handlers.md)). A nullable parameter is optional.

```kotlin
@Handler
fun Tick<EveryTick>.type(speaking: Speaking, dialogue: DialogueHold, step: Step) = ...
```

Formulas read stored values through generated readers. Each `stored()` declaration generates a `Settable<T>` reader that takes the keys as parameters filled from scope, and `.all` reads every key:

```kotlin
reputation(protagonist, npc): Settable<Int>
```

In formula text the keys are implicit, so a dialogue line reads `reputation` and a changes field writes `reputation += 5`. When a key cannot be filled from scope, the realm reports it on the field.

Stored values are indexed per type, so finding every value of a type, or every value for one key, costs about the number of values found.

### Where values live at runtime

The guideline is **store moments, not counters**: `startedAt`, `skippedAt`. Steps then rarely write, and a restarted step is a real resume.

Stored values of a running step are local on the interaction's home engine, which is their single writer. They are saved to the realm at checkpoints: server move, step end, and every few seconds. All other stored data is owned by the realm. Engines subscribe to the stored keys they currently demand and receive `Changed<X>` pushes in commit order per identity (see [live-data.md](live-data.md) for routing).

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

Formula operators are plain provider functions in the standard library that return a `Change`:

```kotlin
operator fun Settable<Int>.plusAssign(amount: Int): Change = Change.add(this, amount)
```

`+=` and `-=` are stored as `add`; `=` is `set`; `*=` is `multiply`; `?=` is `setIfAbsent`.

### Changes fields

An update field has the type `Var<Changes, C>`. Its syntax (change lines, their order, purity) is in [formula-language.md](formula-language.md#changes-fields). Evaluating the field writes nothing; the entry applies the returned `Changes` through `apply()`. `now` inside a changes field is the realm commit time.

## Transactions: `apply()`

`Changes` are committed with `apply()`. One `apply()` is one transaction: all of its operations commit, or none do.

```kotlin
entry.changes(context).apply()
entry.triggers.fire(context)
```

Most entries use the `Triggerable` shortcut `entry.complete(context)`, which applies the changes and then fires the triggers, so the next entry sees the changes (see [events-and-handlers.md](events-and-handlers.md)). Extra update fields, such as a dialogue option's changes, are applied the same way: `option.changes(context).apply()`.

The transaction is optimistic:

1. The changes formula is evaluated against the current stored values.
2. The realm tries to commit.
3. On a conflict, the formula is evaluated again with the same inputs but the updated stored values, and the commit is retried.

So a line like `if (quest.coins > 100) quest.rank = gold` always decides on the committed value, never on a stale one.

A transaction fails as a whole when a `require` guard is false, or when evaluating the formula throws (a provider error, the recursion limit). A failed transaction applies nothing. `Changed<X>` handlers run only after a successful commit.

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
| `mood` | `npc: Ref<NpcEntry>`, `protagonist: Protagonist` | `Mood` | `Neutral` |
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
| `AfterWrite<K, T>(duration, from)` | `duration` after the first or last write (`from: Write`, `First` or `Last`). | Timed values: clear a buff ten minutes after it was set. |
| `At<K, T>(at)` | At `at: Var<Instant, ReactionScope<K, T>>`, computed from the value and re-armed on each write. | Cooldowns, auction ends. |
| `Every<K, T>(cron)` | For every stored key, on a cron schedule. | Daily resets. |

`AfterWrite` is the friendly shortcut for the common case of `At`.

Example changes formulas:

```kotlin
// OnWrite on coins: never negative.
require(value >= 0, "coins cannot go negative")

// AfterWrite(10.minutes, from = Last) on a buff: reset it.
value = 0
```

### How timed reactions fire

Timed reactions run through `Due`:

| Reaction | Event delivered through a `Due` | Fields |
| --- | --- | --- |
| `AfterWrite` | `AfterWriteElapsed<K>` | `variable`, `keys`, `reaction` |
| `At` | `AtElapsed<K>` | `variable`, `keys`, `reaction` |
| `Every` | `EveryElapsed` | `variable`, `reaction` |

All fields are identities, so the `Due` disappears when the variable, the reaction item, or a key identity ends. `Every` keeps its last run time in an `EveryRan` stored value keyed by the reaction item (one per `Every` reaction, removed with it).

### Legacy timed data

Legacy timed, cron, countdown, and per session data needs no special storage. Each becomes a variable: timed values use `AfterWrite`, cron values use `Every`, countdowns use `At`, and per session values use a `Session` key, so they are removed when the session ends.

## Due

`Due` is durable time. It is an ordinary stored value plus a core source:

```kotlin
data class Due<E>(@Key val event: E, val at: Instant) : Stored
```

The realm is the clock. When `at` passes, the realm delivers `event` to an engine where a handler for it can run:

- Stored only handlers: any engine that runs the book.
- Handlers asking for live traits: the subject's engine. For an offline subject the event fires when it joins.

Guarantees:

- **Exactly once effect.** Removing the `Due` is part of the handler's transaction, so a crash before commit redelivers.
- **Catch up.** Dues that passed while nothing ran fire once on startup.
- **Lifetime.** A `Due` disappears when any identity inside `event` ends.
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
- A stored derive that reads a mirror keeps its last result when that input vanished by `Tracking` (a quit or server move), so group sync keeps the last group while the protagonist is offline. The realm warns that such a derive cannot run offline.

The same `@Derive` shape with a `Hold` result is live and never saved (see [interactions.md](interactions.md)); with a `Live` result it is a computed mirror (see [live-data.md](live-data.md)).

## Offline changes

Stored data can change while its protagonist is offline, for example through a panel edit or a `Due`.

- Stored only derives and handlers run on any engine that runs the book. The realm picks one; when none runs, they catch up when one starts.
- Live reactions to a moment can be missed, and missed events are never replayed. The guideline is **store what is owed, not what happened**: a derive produces owed state, and a live handler acts on it whenever the protagonist is online.

```kotlin
@Derive
fun QuestStage.owed(): SwordOwed? = ...

@Handler
fun Added<SwordOwed>.give(owed: SwordOwed, inventory: HasInventory) = ...
```

The handler asks for a live trait, so it runs only while the protagonist is online: when `SwordOwed` appears, or on join if it appeared while they were away.

A realm check warns about live handlers on `Changed<X>` when X can change offline.

## Checks

The stored data checks from the one check list:

| Where | Severity | Check |
| --- | --- | --- |
| KSP | build error | A key field that is not an identity or a `Set` of one. |
| Realm | error | Keys of a stored reader that cannot be filled from scope. |
| Realm | error | A cycle between derives. |
| Realm | warning | A live handler on `Changed<X>` when X can change offline. |
| Realm | warning | A stored derive reading mirrors (not offline capable). |

Errors block publication; warnings never do.

## Open

- Key fields that are records: whether a key may be a record whose fields are all identities. `Due<E>(@Key event: E, at)` relies on it to satisfy the key rule.
- Book instance identity: whether an instance is the identity (book, key), the same shape as groups, so that renaming an instance key creates a new instance and the book's migration moves its data.
- Variables: the direction is adopted, but details such as the variable editor are still in progress.
