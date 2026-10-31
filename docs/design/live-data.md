# Live data

How Typewriter tracks state that lives on an engine (health, position, region, audience membership), routes it between engines, and keeps working when a protagonist moves between servers. Stored, saved data is in [stored-data.md](stored-data.md). Events, handlers, and parameter resolution are in [events-and-handlers.md](events-and-handlers.md). The primitives on one page are in [overview.md](overview.md).

## Live data never notifies

Engine state (a player's health, the block under their feet) has no change signal of its own. Typewriter never asks the engine to notify it. Instead, ordinary handlers turn live state into tracked values, and everything downstream (formulas, derives, reactions) recomputes from those tracked values automatically.

A change that has no event behind it is found by looking: a handler on an ordinary event such as `Tick` reads the state and returns the new value.

## Live mirrors

A `Live` value is a mirror of live engine state. It is immutable, keyed by identities through `@Key` fields, never saved, and maintained only while something demands it.

```kotlin
data class Health(@Key val protagonist: Protagonist, val value: Double) : Live
```

`Live` sits next to the other keyed value kinds:

| Kind | Saved | Lifetime | Mutable |
| --- | --- | --- | --- |
| `Stored` | yes | until a key identity ends | through `Changes` |
| `Hold` | no | while a derive returns it, plus grace | no |
| `Live` | no | while demanded | no (a new value replaces it) |
| `Runtime` | no | with whatever created it | yes |

`Runtime` objects (mutable, local, such as an NPC activity) are covered in [interactions.md](interactions.md). Holds are covered there too.

### Writers

A mirror is written by handlers that return it. The handler's return type tells KSP which mirror it produces.

```kotlin
// Exact event: the value changes because of this event.
@Handler
fun EntityDamage.health(player: PaperPlayer): Health = Health(player.protagonist, player.health)

// Safety net or polling: a slow Tick handler reads the current value.
@Handler
fun Tick<EveryTick>.health(player: PaperPlayer): Health = Health(player.protagonist, player.health)

// First read: Seed fires when the mirror is first needed for an identity.
@Handler
fun Seed<Health>.health(player: PaperPlayer): Health = Health(player.protagonist, player.health)
```

Phase decides which value a reader sees. A writer in the Unit phase (after the event was allowed) records the post event value; verdict handlers on the same event still see the pre event value.

Returning `null` means there is no value for that identity; a handler that asks for it is skipped.

### Seed

`Seed<X>` is a core event emitted when mirror `X` is first needed for an identity. Its handler reads the current value once. Seeding starts tracking, so the resulting `Added<X>` carries `because = Tracking`.

### Added, Changed, Removed and Because

Every mirror emits the same lifecycle events as stored values and holds: `Added<X>`, `Changed<X>(old, new)`, `Removed<X>`. `Added` and `Removed` carry `because: Because`:

| `Because` | Meaning | Examples |
| --- | --- | --- |
| `Value` | the value really appeared or vanished | the player entered or left a region |
| `Tracking` | tracking started or stopped | join, quit, server move, first or last reader |

Display reacts to both. Logic reacts to `Value` only.

```kotlin
@Handler
fun Removed<InRegion>.leftArena(chat: HasChat) {
    if (because == Because.Value) chat.send("You left the arena")
}
```

### Equality, rate, and threads

- Equality is defined by the mirror type, so the type chooses its own precision (a position mirror may round).
- At most one `Changed` fires per mirror and identity per tick; the last value in the tick wins.
- The thread that owns the identity writes the mirror. Other threads read the last committed value without a thread hop.
- A miss on the owner thread seeds inline. A miss on any other thread is unresolved once (the handler is skipped) while demand starts, so the next read finds a value.

## Demand

Mirrors and lazy sources share one notion of demand. Demand is per identity and key, and it exists only where some reader could actually run, meaning all its other parameters are satisfiable. Readers that create demand:

- formula subscriptions (for example a watched dialogue text)
- derive inputs
- parameters of suspended handlers
- queued step give up formulas
- handlers on `Added<X>`, `Changed<X>`, `Removed<X>`, gated by their other parameters and by `Candidate` keys

A one shot handler parameter pulls once (seeding if missing) and does not subscribe. Producing handlers run only for identities with demand; KSP knows which mirror each handler produces from its return type.

### Demanded

`Demanded<X>` is a core parameter: the keys of mirror `X` demanded for the handler's subject right now. Producers check only those keys. A producer that returns a list replaces the subject's values for the demanded keys.

```kotlin
data class InRegion(
    @Key val protagonist: Protagonist,
    @Key val region: Ref<RegionEntry>,
) : Live

@Handler
fun Tick<EveryTick>.regions(player: PaperPlayer, demanded: Demanded<InRegion>): List<InRegion> =
    demanded.keys
        .filter { it.region.contains(player.location) }
        .map { InRegion(player.protagonist, it.region) }
```

Entering and leaving a region is `Added<InRegion>` and `Removed<InRegion>`; there are no separate enter and exit events.

### Demand for configured sources

Configured events (`Tick<C>` and other real events with a configuration, see [events-and-handlers.md](events-and-handlers.md)) use the same demand. A source receives `Demand<C>`, the configurations that currently have a runnable handler, so only those are active:

```kotlin
interface ConfiguredSource<E, C> {
    fun open(demand: Demand<C>)
}
```

## Finders are mirrors

Anything that "finds" a value for a handler (the nearest NPC, NPCs in range) is a `Live` type plus producing handlers. Extensions add value types, never resolution logic.

- Pull at event time through `Seed<X>`; keep it current with a `Tick` handler while it is watched.
- `null` means no value, so the handler is skipped.
- Free keys iterate: a handler runs once per value.
- `Removed<X>` cancels a suspended handler that resolved it.
- A parameter nothing can produce is a build error.

```kotlin
data class NearestNpc(@Key val protagonist: Protagonist, val npc: Npc) : Live

@Handler
fun Seed<NearestNpc>.find(player: PaperPlayer, npcs: All<Npc>): NearestNpc? =
    npcs.minByOrNull { it.distanceTo(player) }?.let { NearestNpc(player.protagonist, it) }
```

### Parameterized mirrors

A parameter is a key, and a key is an identity. Content configuration is an entry, so the entry reference is a key:

```kotlin
data class NearbyNpcs(
    @Key val protagonist: Protagonist,
    @Key val trigger: Ref<NearbyTriggerEntry>,
    val npcs: List<Npc>,
) : Live
```

A parameter that exists only in code uses one wider mirror, and the handler filters it.

## Derives with a Live result

`@Derive` picks its behaviour from the result type: `Stored` is saved, `Hold` is live with priority and grace, and `Live` is a computed mirror (demand driven, never saved). The `Stored` and `Hold` forms are in [stored-data.md](stored-data.md) and [interactions.md](interactions.md).

Derive inputs are tracked; incrementality comes from read tracking and early cutoff (an unchanged result stops propagation).

### Stored derives over mirrors

A stored derive that reads a mirror keeps its last result when the input vanished with `because = Tracking`. Group sync from a placeholder or world therefore keeps the protagonist's last group while they are offline. A stored derive that reads mirrors cannot run offline; the realm flags it (see checks).

## Formula changes

Formulas read mirrors like any other input. On the engine, evaluation records its reads, as the realm does, and each read kind has a change signal:

| Read | Change signal |
| --- | --- |
| stored value | `Changed<X>` |
| mirror | `Changed<X>` of the `Live` type |
| content | hot publish |
| `now` | timer recheck |

`FormulaChanged<T>(entry, subject, old, new)` is the event for a watched formula whose result changed. A condition becoming true is the Boolean case. A trigger can fire whenever a formula's output changes and receives the old and new value. A reaction when a variable crosses a line is an event entry on `Changed<Variable>` or `FormulaChanged`, not a variable reaction. Formulas themselves are in [formula-language.md](formula-language.md).

PlaceholderAPI is a provider function (`papi("player_level")`) backed by a `Tick` mirror that is polled only where a formula uses it.

## Audiences

Audience entries stay their own entry system with the same visible behaviour as legacy: trees, enter and leave, children, inversion. Their criteria are formulas, and membership is a mirror. Objectives likewise stay their own entry system (display, tracking, progress); only their criteria become formulas.

```kotlin
data class InAudience(
    @Key val protagonist: Protagonist,
    @Key val node: Ref<AudienceEntry>,
) : Live, Indexed

@Derive
fun AudienceEntry.inside(
    protagonist: Protagonist,
    parent: InAudience?,
    criterion: Formula<Boolean>,
): InAudience? = ...
```

- Criteria are formulas over mirrors.
- A child recomputes when its parent changes.
- There is no offline last known audience.

Enter and exit triggers come from `TriggerAudienceEntry(onEnter, onExit, fireOnJoin = true)`. Like legacy, enter fires on every join by default. Exit fires only on `because == Value`, so quitting or moving servers does not count as leaving.

Displays derive from membership: a `SidebarHold` is derived from `InAudience`, and its text updates through `FormulaChanged<SidebarText>`. Competing displays of the same hold type are settled by hold priority ([interactions.md](interactions.md)).

### Indexed

`Indexed` marks a `Live` type whose `Added` and `Removed` the engine reports to the realm. The realm keeps an online index for the session, which powers the panel ("who is in spawn"), network counts, and formula readers such as `spawn_audience.players`.

## Session

`Session(protagonist, id: SessionId) : Identity` is one connection of a protagonist. The engine kind supplies the id through a `SessionReporter`:

```kotlin
interface SessionReporter {
    fun connected(protagonist: Protagonist, id: SessionId)
    fun disconnected(id: SessionId)
}
```

| Engine kind | Session id | Survives |
| --- | --- | --- |
| Minecraft | proxy connection id | server moves |
| Panel | per tab id kept in sessionStorage | reloads; each tab is its own session |
| Future engines | defined by the engine | engine specific |

- A protagonist may have several sessions at once (tabs, Minecraft plus panel).
- A session ends when no engine reports its id for longer than a grace set per engine kind (about 10 seconds for Minecraft).
- A protagonist is online while it has at least one session. `ProtagonistJoined` fires on the first session, its counterpart on the last.
- Values keyed by a session are removed when it ends.
- The single writer lease is per session. Mirrors live on the engine that produces them.

## Engines and traits

An engine runs published content through extensions ([../vision/engines.md](../vision/engines.md)). None of the primitives is Minecraft shaped, so the same model serves Paper, the panel engine, and future engines.

- `Tick` is a capability, not core.
- Tracked inputs for formulas and derives are an extensible set of sources (the panel engine tracks draft content).
- Hold lifecycle runs per live connection of the holder (a Minecraft session, a browser tab), not per server.
- Engines meet only through stored state in the realm; interactions do not span engines.

### Live capability traits

An engine provides live traits for its identities, such as `PaperProtagonist : Player, HasChat, ...`. A trait gives live access and effects (teleport, packets, inventory). Optional capabilities are plain Kotlin type checks.

A handler asks for one parameter per trait, ECS style. Parameters of the same identity kind refer to the same identity; typed roles (`@As`, `@From`) split them when an event has two.

```kotlin
@Handler
fun SwapHands.heal(living: Living, inventory: HasInventory) = ...
```

When the subject is a group, protagonist kind parameters iterate its members; see [events-and-handlers.md](events-and-handlers.md#resolution).

Capabilities declare their formula functions as interfaces that engines implement; see [formula-language.md](formula-language.md#members-and-providers).

Where a handler runs, threads, wire verdicts, live anchors, and cancelling follow the parameter types; see [events-and-handlers.md](events-and-handlers.md#where-a-handler-runs).

## Routing

Routing is hybrid: an event goes where a handler for it can run, and engines run what they can locally.

What the realm owns goes through the realm:

- stored commits
- `Changed<X>` pushes (engines subscribe to the stored keys they currently demand)
- `Due` deliveries ([stored-data.md](stored-data.md))
- `Indexed` reports
- session reports

Live effects for a protagonist on another engine go directly to that session. The engine holding a session subscribes to its NATS subject `typewriter.session.<id>`, so senders need no routing table and a server move keeps the address.

- Order is per identity, in commit order.
- No events are queued for offline protagonists.
- Cross server live effects keep working while the realm is down.

## NATS JetStream

Short lived data lives on NATS JetStream. This needs NATS 2.11 or newer with JetStream, for per message TTL and per key TTL with expiry markers. The realm creates these resources at startup.

| Resource | Content | Behaviour |
| --- | --- | --- |
| `sessions` KV bucket | one key per session | refreshed by the holding engine with a TTL equal to the grace; an expired key ends the session, so a crashed engine's sessions end on their own and the realm keeps no grace timers |
| session stream | backs each `typewriter.session.<id>` subject, about 30 seconds | after a server move the new engine continues where the session stopped, so live effects sent in the move gap are not lost |
| `Indexed` KV bucket per type | keys `<protagonist>.<node>` | refreshed on change, expiring when the engine dies; watched by the panel and engines, so the online index survives realm restarts and outages |

Not on streams: stored data and `Due` (transactions, exactly once, realm owned) and mirrors that are not `Indexed`.

## Hot publish

Content is a tracked input. Publishing new content reruns whatever read it; there is no `Republished` event.

- Step data the protagonist sees is a derive over the step marker plus the entry. The marker stores only moments (`startedAt`), so text is live and a publish updates it in place.
- Configured event configurations and `Candidate<E>` entries are live across hot publish.
- An identity defined by an entry ends when that entry is removed, and with it every value keyed by it.

```kotlin
data class Speaking(@Key val step: Step, val entry: Ref<DialogueEntry>, val startedAt: Instant) : Stored

@Derive
fun Speaking.show(...): DialogueHold = ...
```

Typing is a `Tick` handler over `DialogueHold`.

## Multiple servers

A server move is a leave and a rejoin. There is no separate continue or follow setting.

| Part | On a server move |
| --- | --- |
| Session | kept (Minecraft uses the proxy connection id) |
| Live effects in flight | kept by the session stream and delivered to the new engine |
| Mirrors | `Removed` then `Added` with `because = Tracking`; tracking restarts on the new engine |
| Stored derives over mirrors | keep their last result |
| Holds | `Removed` on the old connection, `Added` on the new one; derives rerun |
| `Runtime` objects | closed with their creator, re-created through `Added<H>` |
| Running steps | follow the step entry's `onRejoin` ([interactions.md](interactions.md)) |

While a protagonist is away, live handlers simply do not apply because their parameters cannot be resolved.

## Checks

All checks form one list. Errors block publication; warnings and info never block. Findings show on the causing field or entry, with quick fixes where possible. Extensions add checks through the same `RealmCheckProvider`.

**Build time (KSP)**

- unresolvable handler parameters
- key fields that are not identities
- live access in wire verdicts, or two live anchors
- command nodes whose event fields do not match the path arguments
- incomplete capability implementations
- Kotlin exhaustiveness

**Realm while editing** (existing `RealmCheckProvider`, computed through the query graph)

| Level | Finding |
| --- | --- |
| error | formula type errors (unhandled union kinds, non exhaustive `when`) |
| error | formulas needing engine or stored data in realm run fields |
| error | keys not fillable from scope |
| error | `dynamic()` cycles |
| error | derive cycles |
| error | unfinished migration inputs |
| error | failing migration dry runs |
| warning | tied allow and deny priorities |
| warning | tied hold priorities for the same hold type, holder, and key |
| warning | live handlers on `Changed<X>` when X can change offline |
| warning | stored derives reading mirrors |
| info | mirrors always tracked because of a handler |
| info | formulas reading polled values |

## Open

- How the legacy quest item audience (`QuestItemAudienceEntry`) maps onto `InAudience` and holds.
