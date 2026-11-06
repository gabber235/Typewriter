# Core model overview

Typewriter's runtime is built from seven primitives. Every legacy system (dialogues, cinematics, audiences, NPCs, sidebars, commands, quests) and every vision feature is expressed with them; there is no separate audience, entity, or rule system. None of the primitives is Minecraft shaped, so the same model serves the Paper engine, the panel engine, and future engines.

This page shows each primitive once and how they fit together. Product intent lives in [`../vision/`](../vision/README.md); the build order lives in [`closed-beta-roadmap.md`](closed-beta-roadmap.md).

## The seven primitives

| Primitive | In one line | Details |
| --- | --- | --- |
| Event and Source | Something happened; a source delivers it, only where demanded. | [events-and-handlers.md](events-and-handlers.md) |
| Handler | A function whose parameter types decide when and where it runs. | [events-and-handlers.md](events-and-handlers.md) |
| Identity and Stored | Saved data keyed by identities, removed when a key identity ends. | [stored-data.md](stored-data.md) |
| Derive | A pure function whose result type decides what it maintains: `Stored`, `Hold`, or `Live`. | [stored-data.md](stored-data.md), [interactions.md](interactions.md), [live-data.md](live-data.md) |
| Runtime | Local values never saved: `Runtime` objects and `Live` mirrors. | [live-data.md](live-data.md), [interactions.md](interactions.md) |
| Formula | Creator and extension expressions with their own typed language. | [formula-language.md](formula-language.md) |
| Chain | Entries linked by triggers; links fire explicitly and carry context. | [events-and-handlers.md](events-and-handlers.md) |

A new concept is only added when it is useful in several unrelated scenarios and cannot be expressed with these primitives (or is much more ergonomic than the alternative). Entries keep the v1 shape (`@TypewriterType`, `@TypewriterDisplay`, `page`, `placement`, relation refs, presentation object); the primitives add behaviour next to them.

## Event and Source

An event is one type per meaning (`PlayerMove`, `ArmSwing`, `Confirm`, `Tick`). What a delivery can do (decide, change, run on which thread) is typed on the source, not on the event. Sources receive `Demand<Config>`, so they only work for events some handler can actually run for.

```kotlin
ConfiguredSource<E, Config>.open(demand: Demand<Config>, sink: Sink<E>)
```

`emit()` queues an event; it is decided after the current one finishes. See [events-and-handlers.md](events-and-handlers.md).

## Handler

A handler asks for the event plus parameters. If any parameter cannot be resolved, the handler does not apply. The return type decides the phase: a `Verdict` takes part in the decision (allow, deny, change, pass), a `Unit` handler runs after the outcome is applied.

```kotlin
@Handler
fun NpcClicked.talk(running: Running<SpokenDialogueEntry>, mood: Mood) = ...

@Handler
fun Tick<EveryTick>.animate(animating: Animating, chat: HasChat, history: ChatHistory) = ...
```

Parameter types also decide where a handler runs: live traits (`HasChat`, `HasInventory`) pin it to the engine where its subject is live; stored data only lets it run wherever the event happened. See [events-and-handlers.md](events-and-handlers.md).

## Identity and Stored

An identity is something data can be about: `Protagonist`, `Interaction`, `Step`, `Session`, a group, any entry `Ref`. A stored value is saved data keyed by identities and removed when any key identity ends, so nothing leaks after a crash, server move, or hot publish.

```kotlin
data class Friendship(@Key val pair: Set<Protagonist>, val level: Int) : Stored
```

`@Key` is sugar for the storage declaration `stored(name, keys, value, default)`. Creators declare the same thing as a `Variable` static entry. Writes are transactions committed by `attempt()` as one transaction. Every stored value emits `Added<T>`, `Removed<T>`, and `Changed<T>(old, new)`. See [stored-data.md](stored-data.md).

## Derive

A derive is a pure function over tracked inputs. Its result type decides what the system does with the result.

| Result | Meaning | Details |
| --- | --- | --- |
| `Stored` | Saved; an equal result writes nothing. | [stored-data.md](stored-data.md) |
| `Hold` | Live view state with priority, grace, and a stored snapshot to restore. | [interactions.md](interactions.md) |
| `Live` | A computed mirror, demand driven, never saved. | [live-data.md](live-data.md) |

```kotlin
@Derive
fun Running<SpokenDialogueEntry>.chat(who: Protagonist) = ChatHold(who)

@Derive
fun AudienceEntry.inside(protagonist: Protagonist, @From(Parent::class) inParents: List<InAudience>, criterion: Boolean): InAudience?
```

## Runtime

Local values that are never saved. A `Runtime` is a mutable object on one server with a creator lifetime (an NPC activity created on `Added<NpcRunning>`). A `Live` value is an immutable mirror of engine state with a demand lifetime: handlers write it by returning it, and everything downstream recomputes. Live data never notifies on its own.

```kotlin
data class Health(@Key val protagonist: Protagonist, val value: Double) : Live

@Handler
fun EntityDamage.health(player: PaperPlayer): Health = ...
```

See [live-data.md](live-data.md) for mirrors, sessions, and routing, and [interactions.md](interactions.md) for `Runtime` objects tied to holds.

## Formula

Formulas are a separate language from the v1 portable expressions, with their own interpreter in the shared `formula` module. A formula field is `Var<T, C>`: `T` decides what the text may be (a value, a function body, `Changes`), `C` is the context interface whose properties become the context parameters of the formula's function type. Formulas stay pure; `Changes` are applied by the entry.

```kotlin
val text: Var<RichText, MemberContext>
val changes: Var<Changes, InteractionContext>
```

```
quest.coins += 50
if (quest.coins > 100) quest.rank = gold
```

Handlers read a `Var` field of their receiver as a plain parameter with the field's name, always current. See [formula-language.md](formula-language.md).

## Chain

Entries are linked by triggers. Links always fire explicitly; nothing follows links automatically. Firing emits an ordinary `Triggered<E>` event per linked entry, queued like `emit`. Context is a typed bag of records that only grows along the chain.

```kotlin
fun <E : Event> E.fire(entry: Candidate<EventEntry<E>>) {
    if (entry.condition) entry.complete(context)
}
```

Entries with the `Triggerable` trait use `entry.complete(context)`: apply changes, then fire triggers. See [events-and-handlers.md](events-and-handlers.md).

## How they fit together

A typical dialogue, end to end:

1. A **source** delivers `NpcClicked`. A trigger **handler** with a `Candidate<E>` parameter matches the entry and fires its links.
2. The **chain** fires into a `StepEntry`. Core starts it: a step inside an **interaction**, stored as a `Running<SpokenDialogueEntry>` row (a **stored** value keyed by the step).
3. A **derive** over `Running` returns a `ChatHold`, which blocks other chat. Another returns a `Live` view, and handlers on `Added` and `Changed` of that view draw it.
4. The dialogue text is a **formula** read as a tracked parameter of the view derive, so it stays live through value changes and hot publish.
5. A `Confirm` event reaches `fun Confirm.advance(running: Running<SpokenDialogueEntry>)`, which calls `running.complete()`: it ends the step and then runs `entry.complete(context)`: the option's `Changes` commit in one transaction and the next links fire.
6. The derive stops returning the hold; once the chain has settled and a short grace passed, `Removed<ChatHold>` restores the chat, unless the next step adopts the same hold.

Interactions, steps, groups, and holds are covered in [interactions.md](interactions.md); chat and input in [dialogue.md](dialogue.md). Changing content that existing data depends on goes through [migrations.md](migrations.md). Every type and term is listed in [glossary.md](glossary.md).

## Where things run

| Data | Lives on | Saved |
| --- | --- | --- |
| Stored values, `Due` | The realm; every write is a transaction, also for a running step | Yes |
| `Hold` | The engine holding the protagonist's session | Snapshot only |
| `Live` mirrors | The engine that produces them; values demanded across engines are published to the `mirrors` KV bucket | No |
| `Runtime` objects | One server | No |

Engines share stored state only through the realm; live effects and events go directly between sessions ([live-data.md](live-data.md#routing)); interactions do not span engines. A server move is a leave and a rejoin.

## Open

- What `force` does for `/tw fire`.
- The same occurrence reaching a handler twice through forwarding.
