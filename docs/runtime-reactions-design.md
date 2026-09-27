# Runtime reactions: working design

Status: active design discussion, 2026-09-26. This is a living record of agreed behavior, evidence, and unresolved decisions. API names and code snippets are illustrative, not approved production contracts. The [typed runtime data handoff](typed-runtime-data-handoff.md) records the paused subsystem that depends on this work.

Design correction: the earlier list of Event, State, Operation, and Lifetime was rejected as a primitive model. Those names describe behaviors but do not explain how they compose. The next proposal must begin with concrete typed connections and operators that let one producer feed another consumer. Existing decisions about observable current state, immediate decisions, typed requests, independent handler completion, and lifetime ownership remain requirements to test against that model. The sections below preserve the earlier draft as evidence, not as an approved class design.

DX direction: direct subscriptions are currently preferred. The generic source and consumer proposal below is still useful as an experiment, but it is not an approved runtime core. The following technical candidate starts from the concrete contracts behind direct subscriptions.

Second design correction: the split into public event, state, and operation interfaces was also rejected. It repeats the earlier taxonomy behind a shared registry. The current hypothesis below unifies occurrences and typed requests as interactions, derives observable current values through a generic materialized cell, and uses scope only for lifetime. It is not approved yet.

## Technical hypothesis: interaction, cell, scope

An `Interaction<I, R, M>` is a typed invocation point. `I` is the input value, `R` is the response contributed by a handler, and `M` is the execution mode. Its declaration defines how responses from several handlers combine. An immediate mode runs handlers before the publisher continues and accepts only handlers that cannot suspend. A deferred mode may run suspending handlers and records each handler's completion when delivery is durable. Event notification, cancellable Minecraft input, and a typed reset request are instances of the same interaction type with different inputs, results, and modes. The words event and operation describe their use, not distinct dispatcher classes.

```kotlin
sealed interface Mode
data object Immediate : Mode
data object Deferred : Mode

fun interface ImmediateHandler<I, R> {
    fun run(input: I): R
}

fun interface DeferredHandler<I, R> {
    suspend fun run(input: I): R
}

interface Interaction<I, R, M : Mode>

fun <I, R> Interaction<I, R, Immediate>.on(
    scope: Scope,
    handler: ImmediateHandler<I, R>,
): Registration

fun <I, R> Interaction<I, R, Deferred>.on(
    scope: Scope,
    handler: DeferredHandler<I, R>,
): Registration
```

The declaration carries a stable type identity, typed identity binding, and a response reducer. Generated receiver accessors such as `player.commandAttempts` bind the declaration to a player ID. A provider holds the right to invoke it. Global and player bound handlers for the same declaration participate in one response reduction. A native Paper listener, a packet hook, and an extension publisher can all invoke interactions without their mechanics appearing in the consumer API.

Attaching a handler creates a registration token owned by its scope. The runtime indexes it by declaration and bound identity. The first relevant registration may activate a provider's native source; removing the last may deactivate it. A provider that cannot install a native source dynamically can keep that source active and check demand before publishing. The same dispatch path handles an extension published occurrence without any native source. An immediate publisher obtains the reduced result before returning to Minecraft; a deferred publisher obtains a delivery receipt and lets handlers complete later.

`Cell<K, V>` is materialized current state keyed by `K`. It owns one value and revision for each key and exposes a current read, atomic observation, and value changes. A cell can be owned directly by an extension, derived by folding interactions, or backed by committed Realm values. `observe` is generic behavior of a cell, not an event specific feature. It attaches an observer and takes a snapshot under one owner controlled ordering boundary. The initial value is delivered before later revisions. A separate read followed by event subscription cannot satisfy this guarantee.

```kotlin
interface Cell<K, V> {
    suspend fun read(key: K): Versioned<V>
    suspend fun observe(key: K, scope: Scope, observer: Observer<V>): Registration
    val changes: Interaction<Change<K, V>, Unit, Deferred>
}

val cinematicPlaying: Cell<PlayerId, Boolean> = cinematicLifecycle.foldBy(
    key = ::playerId,
    initial = ::notPlaying,
    update = ::applyCinematicChange,
)
```

The `foldBy` call is illustrative. The important relation is that interactions can maintain cells, and cells expose changes that can invoke further interactions. The cell owner mounts the fold for the cell's lifetime, independently of observers. A cell derived from Realm data must update from committed writes; a cell derived from Minecraft activity needs an owner that sees every relevant transition. If the underlying interaction can be missed while that owner is absent, the provider must reconstruct the current value before exposing the cell. A provider may implement the cell contract without using a runtime owned map, but it must still meet atomic observation semantics.

`Scope` owns handler registrations, cell observations, child scopes, and closeable effects. Its closure deactivates registrations and releases owned resources. A cinematic segment can own both a command decision handler and a visible time override. The scope does not define whether an invocation is an occurrence, a request, or a state update.

Delivery is an invocation choice constrained by mode and payload. An immediate invocation runs handlers before returning its combined result. A deferred invocation accepts work that may suspend. A scheduler can persist an invocation of either mode when its input has a stable codec and can be resolved in the target engine later; it never persists a Kotlin callback or a live player handle. At due time the invocation follows its declared execution mode. Durable delivery records completion for each participating handler. Thus a player join handler and a Realm schedule can submit the same `ResetPlayerSession` interaction. A request that has no handler when due stays open under the earlier agreed rule. The policy for pending deliveries when a handler scope closes remains unresolved.

Illustrative composition:

```kotlin
val playerJoins: Interaction<PlayerJoined, Unit, Immediate>
val blockBreaks: Interaction<BlockBreakAttempt, Decision, Immediate>
val resetSessions: Interaction<ResetPlayerSession, Unit, Deferred>
val playing: Cell<PlayerId, Boolean>

playerJoins.on(entryScope) {
    resetSessions.submit(ResetPlayerSession(it.player.id))
}

resetSessions.on(extensionScope) {
    resetSessionValuesAtomically(it.playerId)
}

scheduler.schedule(resetSessions, ResetPlayerSession(playerId), tomorrow)

blockBreaks.on(entryScope) {
    it.player.startDialogue(dialogue)
    if (entry.cancelBreak) Deny else Pass
}

playing.observe(player.id, audienceScope) {
    sidebar.setVisible(player, !it)
}

playing.changes.on(entryScope) {
    graph.submit(ReactToCinematicChange(it.key, it.previous, it.current))
}

segmentScope.own(player.overrideVisibleTime(noon))
```

This candidate has three runtime concepts with different jobs. Interaction routes typed input to handlers and combines their responses. Cell materializes current values from interactions or committed writes and exposes transitions. Scope bounds the active registrations and resources. Behaviors emerge from handlers invoking interactions, updating cells, and observing cells inside scopes. The exact Kotlin names and code generation are unsettled. The hard checks are whether one interaction type can keep immediate execution and durable delivery distinct in the type system, whether a cell can guarantee initial plus later values for every provider, and whether a general response reducer can cover packet transformations without a collection of specialized policies.

## Earlier technical candidate, rejected as separate public contracts

This candidate separates a declaration, its bound view, and its authority to publish or change it. A declaration gives stable type identity and policy. Binding it to a player, entry, or other identity returns a lightweight view with the author facing receiver API. A provider holds the write side. A scope owns every active registration. These are proposed interfaces, not production signatures:

```kotlin
interface Registration : AutoCloseable

interface Scope {
    fun own(registration: Registration): Registration
    fun child(): Scope
}

fun interface Handler<I, O> {
    fun handle(input: I): O
}

fun interface Observer<V> {
    fun changed(value: V)
}

fun interface Worker<Q> {
    suspend fun handle(request: Q)
}

interface EventView<E, D> {
    fun on(scope: Scope, handler: Handler<E, D>): Registration
}

interface EventPublisher<E, D> {
    fun publish(value: E): D
}

interface StateView<V> {
    suspend fun read(): V
    suspend fun observe(scope: Scope, observer: Observer<V>): Registration
    val changes: EventView<Change<V>, Unit>
}

interface StateWriter<V> {
    fun set(value: V)
}

interface OperationPort<Q> {
    fun handle(scope: Scope, worker: Worker<Q>): Registration
    fun request(value: Q): Submission
}
```

`EventView` attaches a handler for future occurrences. Its declaration supplies the neutral decision, response reducer, participation rule, and execution constraints. For a notification, `D` is `Unit`. The provider uses `EventPublisher`; consumers only receive `EventView`. A shared Minecraft capability may bind `player.commandAttempts` to one declaration, while Paper, Minestom, or Fabric chooses how to publish it. An extension declared event uses the same view and publisher split.

Generated declaration descriptors supply stable type identity. An event descriptor has a typed identity key, payload type, result type, and decision policy. A bound `EventView` holds the descriptor plus an identity key such as a player ID. `minecraft.commandAttempts` and `player.commandAttempts` are views of the same event declaration: the first sees all matching occurrences, while the second filters to one player. Both sets of handlers contribute to the one decision returned to the publisher. A state descriptor similarly binds its value to a typed identity key. Generated extension properties can hide these descriptor and binding calls from everyday author code.

`StateView` is a stronger contract with a current value. Its owner supplies a matching `StateWriter` or another implementation that updates the value. `observe` is one atomic attachment at the state owner: register the observer and capture the current revision and value together, deliver that value first, then deliver later revisions in order. Reading and separately subscribing cannot implement this guarantee. `changes` exposes later transitions for code that needs previous and new values; `observe` supplies the current value followed by updates. Whether equal values emit and whether a slow observer can skip intermediate revisions remain open.

`OperationPort` receives a typed request from any caller and fans it out to every participating worker. The operation declaration has a stable type identity and a codec when requests may be durable. A scheduler persists a request value, due time, and target port identity; it does not persist an arbitrary callback. When due, it invokes the same port used by direct `request`. Durable completion is tracked for each worker. The unresolved policy for unfinished work when a worker registration closes belongs here, not in `Scope` itself.

`Scope` owns registrations and resources. Closing it first prevents new callbacks; it then releases provider registrations and owned effects in a defined order. A child scope can represent an entry, player session, audience member, or cinematic segment. The current `RuntimeScope` already has `own`; this candidate would refine its registration and child lifetime contracts.

The runtime registry is shared infrastructure, not one public stream type. It indexes event subscribers, state observers, and operation workers by declaration and identity. Attaching or closing a registration changes that index. An engine provider can install its native listener when the first relevant event registration appears and remove it on last removal, or keep its native listener if dynamic installation is impossible. This choice is invisible to extension code. A state provider must retain enough current value and revision information to fulfill `observe`; an operation dispatcher may additionally need Realm delivery records. They share registration mechanics while keeping different state and dispatch algorithms.

One composed behavior crosses the interfaces as follows. A player join publisher emits a typed occurrence. A handler attached to the join view constructs `ResetPlayerSession(playerId)` and calls its operation port. A registered worker performs the checked Realm data transaction. The value owner publishes committed state changes. An audience observes that value through `StateView`, receiving the current value even if it attached after the transaction. Each callback registration belongs to its own scope. No generic pipeline object has to represent the whole chain.

Illustrative author code for the same composition:

```kotlin
resetSessions.handle(extensionScope, ::resetSession)

minecraft.playerJoins.on(extensionScope) {
    resetSessions.request(ResetPlayerSession(it.player.id))
}

player.cinematicPlaying.observe(audienceScope) {
    sidebar.setVisible(player, !it)
}

player.commandAttempts.on(segmentScope) {
    if (it.command.isBlockedDuringCinematic()) Deny else Pass
}

segmentScope.own(player.overrideVisibleTime(noon))
```

The join callback, state observation, immediate decision, and visible time handle all use the same scope ownership mechanism. Their invocation semantics come from their specific handle types. `resetSession` can update several stored values in one Realm transaction; that transaction is a separate atomic boundary, not an implicit property of the operation port.

This is not a claim that the four interfaces are one interchangeable kind. Their shared mechanics are declaration discovery, identity binding, handler registration, scope ownership, and provider dispatch. Their different guarantees stay in their types. The open design test is whether those shared mechanics and direct Kotlin composition are sufficient, or whether a first class reaction connection is needed for behavior that cannot be expressed cleanly this way.

## Earlier source and consumer proposal, still under review

The proposed foundation has a typed producer, a typed consumer, and a scope that owns their connection. A producer can transform its output with `map` or select occurrences with `filter`; a compatible consumer accepts the resulting value. These are actual type relationships and operators, rather than four unrelated feature names. Illustrative Kotlin shape:

```kotlin
interface Source<T> {
    fun subscribe(scope: RuntimeScope, receive: (T) -> Unit)
}

interface Consumer<T> {
    fun submit(value: T)
}

fun <A, B> Source<A>.map(transform: (A) -> B): Source<B>
fun <A> Source<A>.filter(test: (A) -> Boolean): Source<A>
fun <A> Source<A>.connect(scope: RuntimeScope, target: Consumer<A>)
```

The signatures show relationships, not a chosen threading or completion API. `submit` means the consumer has accepted the value; whether work has finished requires a separate result contract. `connect` belongs to the scope and disconnects when that scope closes. Sources can come from Minecraft, an extension, a timer, an operation result, or a stored value change. Consumers can invoke typed operation handlers, start graph work, refresh an identity, or update a local effect.

For example, a player join and a scheduled due time can submit the same typed request:

```kotlin
data class ResetPlayerSession(val playerId: PlayerId)

minecraft.playerJoins
    .map { joined -> ResetPlayerSession(joined.player.id) }
    .connect(scope, resetPlayerSession)

realm.schedule(ResetPlayerSession(playerId), at = tomorrow)
```

Here `resetPlayerSession` is a `Consumer<ResetPlayerSession>` that dispatches to every registered handler. The timer is one way to provide input to that consumer, not part of what `ResetPlayerSession` means. Realm stores the typed request for the scheduled case; it does not attempt to serialize the arbitrary `map` closure above. A handler can use a stored data transaction for several atomic changes. The ordinary join connection has only the delivery guarantee its source and consumer can actually provide.

Current state and immediate decisions are stronger source contracts, rather than disconnected top level concepts. `Current<T> : Source<T>` promises that `subscribe` first delivers the current value and then every later change without a gap. `DecisionSource<T, R> : Source<T>` additionally accepts synchronous decision handlers and combines their `R` responses according to its declaration. Its ordinary source side can still feed other consumers, but only synchronous decision handlers contribute to the answer Minecraft needs before continuing. Pure `map` and `filter` can preserve immediate execution; delayed or asynchronous operators cannot participate in that decision. A typed operation target is a consumer whose handlers have independent completion records and retries when durable delivery is used. A scope owns active connections and registrations, not the definition of the event or operation.

This proposal is not yet approved. It must be tested against packet decisions, state observation, entry triggers, cinematic cleanup, group refresh, and durable requests before replacing the earlier draft. The rule for unfinished durable handler deliveries when their registration closes is also still open.

### Stress cases from legacy behavior

1. Player return and scheduled reset can submit the same `ResetPlayerSession(playerId)` request. Join is one source, while Realm persists a due request and submits it later. The request does not specify its trigger. A join occurrence alone cannot promise delivery after a crash unless that occurrence is made durable.
2. A timer audience creates a child scope for each member. A timer source attached to that scope repeatedly submits a graph request; leaving the audience closes the timer connection. The legacy implementation creates and cancels a coroutine job for each player. This is local periodic work, not necessarily a durable schedule.
3. A block break handler starts dialogue and may deny the break. A simple asynchronous source to consumer connection cannot return the denial before Minecraft continues. This needs a synchronous decision contract, with direct effects remaining independent of the decision.
4. A cinematic segment captures blocked commands, denies them immediately, then replays them after its interception has closed. It needs a decision contract, segment owned memory, and deterministic cleanup order. A stream transformation alone does not express that cleanup.
5. A cinematic audience reads whether a player is already playing when it attaches and follows later transitions. This needs the stronger current value contract on a source, not a plain occurrence stream.
6. A frozen time audience installs a packet rewrite, applies the initial visible time, refreshes it, and restores normal time on removal. A fake block audience similarly applies an initial illusion and restores the real block. These are maintained resources owned by a scope; reducing them to a single request would lose their ongoing and cleanup behavior.
7. Outgoing action bar and chat handling inspect client visible messages before delivery. Dialogue may suppress messages, retain history, and resend it later without capturing its own resend again. This needs an immediate decision or transformation contract plus local state and ordering. A generic asynchronous source connection is insufficient.
8. A group action fans one graph request out to other group members while retaining its interaction context. This tests expansion of one source value into many consumer inputs and whether the required context is live or portable for durable delivery.
9. A committed stored value change can become a source of previous and new values for graph triggers. The write itself still needs a transaction that validates dependencies and commits several changes atomically. Connecting a source to a generic consumer does not supply those transaction guarantees.

The stress cases indicate that source and consumer form a useful connection algebra for ordinary work. They do not by themselves cover immediate replies, current value attachment, or maintained resources. Those additions need precise type relationships and operators before this proposal can be approved.

## Design test: simple pieces that compose

The public model should have as few components as it can while keeping each one simple. Each component must work in several unrelated combinations: events for join, block breaks, internal cinematic notices, and client-output decisions; state for cinematic activity, group identity, and stored values; operations for graph work, identity refresh, and scheduled resets; lifetimes for entries, sessions, audiences, and cinematic segments. We should remove a proposed component if it only packages one feature, and avoid folding different contracts into one component merely to reduce the count of names.

An event-local staging buffer, a special cinematic event manager, a fact-change watcher, a packet-interceptor facade, and a universal maintained-effect registry are not core components in this draft. The relevant behaviors should be expressible by composing the reusable pieces below. Named capability behavior can still provide short ergonomic functions; that does not add a new runtime primitive.

In Kotlin DX, prefer an extension receiver for the natural owner: `player.cinematicPlaying`, `player.commandAttempts`, and `player.overrideVisibleTime(time)` are better starting points than `cinematicPlaying[player]` or `commandAttempts[player]`. The runtime can still bind these receiver-oriented views to one declared event, state, or operation underneath. For stored data with multiple identities, the settled shape remains `entry.kills[player]`: `entry` is the receiver and brackets supply the additional identity.

## Why this subsystem exists

Typewriter needs to react to Minecraft activity, packet-backed activity, internally published events, committed data changes, and timers. Some reactions observe; some must decide immediately whether an action continues or how a client-visible value changes. Others start graph execution or work that can run later. Legacy Typewriter handled these through separate Bukkit listeners, an entry trigger queue, packet interception subscriptions, and delayed coroutine jobs. We want a small set of concepts that handles their shared lifecycle and routing without exposing how an engine fulfills a capability.

Representative cases to test every proposed model:

| Case | Required behavior |
| --- | --- |
| Player joins | Active authored entries receive a typed occurrence; only needed native sources are attached where practical. |
| Player interacts | A handler may synchronously reject the interaction before the engine continues. |
| Cinematic starts | Typewriter code publishes an event directly; no native event listener or provider installation is required. |
| Cinematic is already playing | A new observer receives current playing state and every later change without missing a transition between reading and subscribing. |
| Cinematic blocks a command | A temporary player-scoped rule rejects an attempted command, regardless of whether an engine uses an API event or packet interception. |
| Cinematic can be skipped | Temporary player input observation starts a sequence action and is removed at segment end. |
| Player time is frozen | A scoped rule maintains the player's visible time; the extension does not select a packet rewriting technique. |
| Value expires | A durable, typed operation value is due at a time and catches up after an engine returns. |

### Grounding in legacy behavior

The old implementations provide concrete DX cases:

| Legacy flow | What actually happens | Model pressure |
| --- | --- | --- |
| [Block break event entry](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/event/BlockBreakEventEntry.kt) | A matching block-break attempt requests dialogue start or advance through the session manager, then may cancel the break so the block stays intact. | Requesting dialogue is a direct Typewriter effect even when the Minecraft action is denied. |
| [Interact event entry](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/event/InteractEventEntry.kt) | After matching active entries, it queues their authored triggers, then cancels the vanilla click if any matching entry requests cancellation. The [session manager](../engine/engine-paper/src/main/kotlin/com/typewritermc/engine/paper/interaction/PlayerSessionManager.kt) launches scheduling asynchronously. | Triggering Typewriter behavior and denying Minecraft's action are independent. |
| [Block command cinematic](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/cinematic/BlockCommandCinematicEntry.kt) | While a segment runs, allowed commands pass; blocked commands are captured and cancelled. When the segment ends, captured commands are replayed. | Delayed work belongs to the cinematic segment lifetime. |
| [Skip cinematic](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/cinematic/SkipCinematicEntry.kt) | Sneak input requests a frame jump; a hand-swap request also requests the jump and cancels the hand-swap. The listeners live only for the segment. | An effect may be requested even when the underlying action is denied. The source may be packet-backed or native. |
| [Freeze time audience](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/audience/FreezeTimeAudienceEntry.kt) | On audience add it installs a packet rewrite and sets player time; it refreshes time each tick, then resets on removal. | This is a scoped maintained effect, not a single event. |

None of these surveyed legacy flows requires an event-local operation buffer that applies only on `Allow`. We removed that feature from this design. The primary contract is direct effects, decisions, and lifetime-owned behavior.

### Coverage audit against the original uses

This audit tests the proposed concepts against the reasons we started this subsystem. “Fits” means the behavior has a natural composition of primitives, not that every engine must use the same mechanism. Provider feasibility and the precise shared-capability boundary can be worked out later.

| Use | Natural author experience | Fit and remaining work |
| --- | --- | --- |
| Player join, interaction, block break | An active entry subscribes to a semantic Minecraft event; a handler can request dialogue or graph work and return a decision where the event permits one. | Fits event + owned subscription. Provider registration may follow demand. Immediate live-handle execution must be verified. |
| Command blocking and cinematic skip inputs | A cinematic segment owns temporary command and input subscriptions. Blocking a command can record it for replay at segment end; skip can start a frame jump while denying a hand swap. | Fits event + direct effect + segment lifetime. The shared hook must mean the same thing across providers even if its source is a packet on one engine. |
| Cinematic start, end, and extension events | An extension declares and publishes typed occurrences that other entries subscribe to. | Fits event. Publishing needs no native listener. Event identity across extensions remains open. |
| Delayed triggers and group fan-out | An event or action invokes typed behavior with a target player or group; the caller chooses immediate, asynchronous, or durable delivery as appropriate. | Fits the intended operation concept. Routing, graph context, executor ownership, and durable guarantees still need a concrete DX. The existing local delay does not itself require durable work. |
| Committed stored-value changes | Subscribe to a typed effective-value change with previous and new values, affected identity roles, and the committed cause; use it to trigger authored content or another transaction. | Fits post-commit events, but requires a precise group-value fan-out rule, loop prevention, and an initial-value read for late subscribers. The Realm transaction remains separate from event dispatch. |
| Group-identity refresh | Join or a live read can request an asynchronous re-resolution of the player's current group; a data transaction can persist the observed link atomically with writes. | Fits an event/read trigger plus operation. The best-effort background refresh and atomic transaction path are specified in the data handoff; invocation details remain open. |
| Expiry and periodic reset | A stored-value write atomically schedules or replaces a durable typed operation value; an engine catches up when one returns and commits a checked data transaction. | Fits durable operations in principle. Due-work ownership, deduplication, replacement generation, and retry/receipt contracts are still open. |
| Frozen player time | A segment or audience requests a visible-time override that applies now, remains enforced, and closes with its owner. | Composes a scoped local operation with a lifetime-owned result. An event subscription alone only sees future time updates. The overlap rule remains to design. |
| Camera mode, fake inventory, damage protection | One cinematic lifetime owns several live state changes, semantic denials, input/output transforms, and restoration. | Composes local functions returning owned handles with decision events and perhaps transforms. One lifetime closes all pieces together. Provider-specific pieces can differ; common capability promises can be decided later. |
| Action-bar suppression and chat history | While a dialogue owns the screen, outgoing messages are inspected; some are suppressed, some pass, and chat may be saved and replayed later. | Composes a scoped outgoing-message decision, history state, and replay operation. The message contract and replay fidelity remain to design; generic packet wrappers should not leak through a shared capability. |
| Late subscribers to current state | A cinematic audience or data watcher needs the current value and later changes without missing a transition between the two. | Fits extension-declared typed observable state, accessed through a natural receiver such as `player.cinematicPlaying`. Its provider supplies an initial value and subsequent updates as one consistent subscription. |

The removal of event-local staging does not block any surveyed use. The remaining design work is to give scoped resources and observable state clear contracts. Cross-engine implementation and capability grouping are later work; the primitives should allow an engine to compose a behavior from different sources and effects internally. A local function or operation may create a maintained effect; its result must be owned and closed by a lifetime.

The desired authoring shape for sustained behavior is a receiver-oriented call whose result is owned by a lifetime, for example `segment.own(player.overrideVisibleTime(fixedTime))`. Its returned handle could update or end the effect early; closing the segment must end it. This is illustrative, not a decision to add a universal “effect registry.” Each behavior still has to say how overlapping owners compose and how state is restored. For current state, `player.cinematicPlaying.observe(segment) { playing -> ... }` is similarly illustrative: attachment must deliver the current value and subsequent changes as one consistent operation.

## Decisions and constraints

1. **Capability behavior is implementation opaque.** An extension targeting the Minecraft capability sees Typewriter-defined semantic data and decisions. Paper, Minestom, Fabric, or another engine can implement a behavior using any combination of native events, packet hooks, mixins, state, and operations. They need not implement it the same way. A capability boundary is based on advertised behavior, not the implementation library. Every engine claiming a capability must fulfill its complete contract; there must be no silent unsupported hook. Which behavior belongs in the common capability versus a narrower or engine-specific one is later work.
2. **Any extension may declare and publish typed events.** Capability-defined Minecraft events and extension-defined events use the same consumer subscription model. A producer may publish an internal event directly. Exact event ID and metadata syntax is still open.
3. **Producer activation is optional and provider-owned.** Consumers subscribe to semantic events. A provider may attach a Paper listener on first demand and remove it on last demand, keep a shared listener and skip unused decoding, always listen when necessary, or publish an internal event directly. Native registration strategy is not observable through the capability API and is not a requirement on every event.
4. **Subscriptions are owned by a lifetime.** Deployment registrars can own activation-wide subscriptions. Authored entry facets can own subscriptions while that entry is active. Player sessions, interactions, and cinematic segments need shorter child lifetimes. Closing the lifetime prevents future delivery and releases provider resources. The precise in-flight callback rule is open.
5. **Immediate decisions have an immediate boundary and need live game access.** Cancellation or transformation must complete before the underlying action or packet proceeds. The user wants these handlers to be able to inspect live player/world state, not only values captured into an event payload. They cannot rely on a Realm round trip or a durable worker; longer work is dispatched separately. The exact portable player/world API and execution context are unresolved. Durable operation inputs must be portable values.
6. **Active content determines demand.** A loaded extension containing a possible join entry does not by itself require a native join listener. The currently attached authored entries and other live subscriptions determine demand. A source that activates on first demand must be ready before the subscription is reported active.
7. **Each event declaration owns its decision rule and participation policy.** Multiple subscribers may contribute decisions. The event's semantic contract defines the neutral result, how contributions combine, and whether a decisive result may stop evaluation of later subscribers. Examples include deny-wins for a command attempt or a documented transformation order. A declaration may choose to run every subscriber even after `Deny`, so all can observe the attempt and register effects; another may explicitly allow early exit. The provider receives one final result. The exact Kotlin API, ordering tie-breaks, and failure handling remain open.
8. **Portable immediate handlers need live player/world access through shared interfaces.** A payload limited to player IDs and copied fields is insufficient for extension DX. The Minecraft capability supplies player/world interfaces implemented by each engine. An extension targeting a specific engine source set may target that implementation and receive its stronger engine-specific variant directly. The same semantic event and decision rule should remain in force; targeting Paper must not create a second, independent command-attempt event. How a packet-backed provider executes the handler safely before the underlying action proceeds remains open.
9. **Direct effects and decisions are independent.** During an event, extension code may call live systems or request Typewriter work directly and may also contribute a decision about the underlying action. A handler may deny `/spawn` and still send feedback or start another action. Direct effects are not rolled back by a later `Deny`; there is no event-local approval staging or mandatory `afterDecision` phase.
10. **Any extension may declare typed operations.** An operation is a concrete request type with typed fields. Every registered handler for that type runs when the request is dispatched; this was explicitly chosen over selecting one executor. Extension code invokes or schedules a value such as `ResetKills(entryId, playerId)`, never a handwritten operation-name string. Asynchronous and durable delivery remain to be designed for concrete uses such as scheduled resets. Operations do not depend on an event approving them. Exact declaration, discovery, handler lifecycle, and delivery APIs remain open.
11. **The primary event DX is direct effect plus decision, scoped to the behavior's lifetime.** The legacy block-break, interaction, skip, and command-blocking handlers request Typewriter work even when they deny a Minecraft action. The command blocker holds replay work until a cinematic segment ends.
12. **Any extension may declare typed observable state.** A state has a current value for a key such as a player, plus later changes. One lifetime-owned `observe` attachment must give the subscriber the current value and all later changes without a read/subscribe gap. Capability providers and extensions use the same consumer model. State may be ephemeral, such as whether a player is in a cinematic, or backed by durable stored data; declaring state does not itself imply database persistence. Exact declaration, publication, initial-delivery timing, and consistency contracts remain open.
13. **Any lifetime may own an operation handler.** An extension, entry, session, or cinematic segment can register a handler while that lifetime is active. Closing the lifetime ends its active registration. Whether unfinished durable deliveries wait for the same logical handler to return or are released is a policy choice whose owner remains open. Durable delivery identities must survive recreation when waiting is chosen, so completed work does not run again. The exact identity mechanism and behavior for work already executing when a lifetime closes remain open.

### What the decision rule must specify

A decision is a typed return value from a subscriber, not a mutation of a shared native event. The declaration supplies a neutral result for no subscribers and a rule for reducing subscriber results to one result. For a command attempt, the neutral result could be `Allow`, and any `Deny` wins regardless of subscription order. This keeps independent rules predictable: a cinematic block cannot be undone by an unrelated subscriber returning `Allow`.

That order independence applies to the returned decisions themselves. A direct effect from one handler can change live state read by a later handler, so direct effects can make the overall dispatch order-sensitive. We need a stable, documented handler order for cases that use direct effects.

The declaration also specifies **participation**: evaluate all matching subscribers, or stop when its rule says the current result is decisive. These choices can produce the same final `Deny` but different direct effects, because skipped handlers never run. This must be visible in the event's authored contract rather than inferred from whichever host event API the provider uses. For a command-attempt event that should log or respond even when blocked, evaluating all handlers is a plausible policy, but it has not been selected for that specific event yet.

Rewriting a client-visible value is different. If two subscribers produce replacements, a plain “last writer wins” rule makes activation order observable. The declaration must instead choose a meaningful merge or a stable, documented transformation order; it may also reject conflicting replacements. Whether each transformer receives the original value or the previous transform's output is part of that declaration. We have not selected a general ordering or conflict policy yet.

This rule governs Typewriter subscribers. A host's other plugins or mods may also affect the underlying action; the Minecraft capability must say what final behavior it can guarantee in that environment. An engine adapter should not promise that Typewriter has the last word unless it can actually enforce that guarantee.

## Earlier candidate model, rejected as a primitive design

This is a proposal to test, not a fixed count. Each candidate has one responsibility and must serve multiple use cases.

| Primitive | Small contract | Responsible for | Outside its responsibility |
| --- | --- | --- | --- |
| **Event** | A typed occurrence, with zero or one response from each subscriber. Its declaration combines responses into one result when the publisher needs a decision. | Publish, subscribe, dispatch, and reduce responses for this occurrence. A notification has no meaningful response. | Current values, replaying missed occurrences, scheduling work, storing data, and undoing direct effects. |
| **State** | A typed current value for a key, plus a consistent stream of later values. Any extension may declare one. | Give a late observer the current value and updates without a read/subscribe gap. | Reporting every occurrence, persisting the value, or allowing arbitrary writes. The owner decides how its value changes. |
| **Operation** | A concrete request type with typed fields. Any extension may declare one; every registered handler for that type runs. | Let the runtime save or pass a typed request and dispatch it to all relevant handlers. | Choosing when to run, owning ongoing results, transaction boundaries, and delivery guarantees. Generic dispatch/scheduling policies supply those where supported. |
| **Lifetime** | A scope that owns closeable resources, subscriptions, and child work. | End all owned behavior together and provide deterministic cleanup. | Deciding event outcomes, holding domain state, or making work durable. |

The cardinality is part of keeping the pieces understandable:

| Primitive | Who uses it | How many outcomes exist |
| --- | --- | --- |
| Event | A producer publishes; any number of active subscribers handle it. | The declaration reduces their responses to one event result if a result is needed. |
| State | One provider supplies the current value for a key; any number of observers follow it. | One current value per key, with later values delivered to observers. |
| Operation | Any caller submits a typed request; every participating handler for its type and target context receives it. A handler registered while a durable request remains open also participates. | Each handler completes independently. Successful handlers remain complete while failed handlers are retried. A durable request closes once every participating handler finishes. A due request with no handlers stays open. |
| Lifetime | One owner attaches resources and child work. | Closing it releases everything it owns. |

Their time semantics are also different:

| Primitive | What a late consumer receives |
| --- | --- |
| Event | Future occurrences after it subscribes; an immediate decision belongs to each occurrence. |
| State | The current value and then later changes, with no gap between them. |
| Durable operation request | Open requests that the handler has not yet handled, then new requests; each handler tracks its own progress. Closed requests are not replayed. A direct local invocation need not be retained. |
| Lifetime | The active period during which subscriptions and resources are owned. |

This explains why event, state, and operation can share typed registration and fan-out machinery without exposing one complicated primitive whose delivery and response rules vary implicitly. A late event subscriber gets future occurrences; a late state observer gets the current value; an operation handler can join open work.

An operation can therefore have several contributors. For example, a typed cinematic-start request could let independent extensions start camera, audio, and interface behavior. The difference from an event is semantic: an event reports that something happened and may need an immediate combined decision before a source continues; an operation requests work that its handlers perform. They may share registration and dispatch machinery, but their contracts for response and delivery still need to be tested against real uses.

Multiple handler delivery has a concrete failure case. Suppose handler A commits the stored value reset and handler B refreshes a scoreboard, then B fails. **The handlers are independent:** A's acknowledged completion remains; B is retried. The runtime therefore needs progress for each durable handler delivery. While B retries, the request remains open: a handler C registered then receives its own delivery and completion record. After B and C finish, the request closes; a later handler D does not receive it. This shared completion boundary does not make the handlers one transaction or cause A to run again. Registration and final completion need one authoritative ordering so a handler cannot fall between the last completion and closing the request. If no handler is registered when the request becomes due, it remains open until a handler can run, unless an explicit cancellation or expiry ends it. A handler can use the separate data transaction to update several values atomically. A crash after an external effect but before its completion receipt may cause that handler to repeat, so arbitrary effects such as messages need a policy that tolerates repeated delivery rather than an unsupported promise of exactly one execution.

Handler registration has the same lifetime rule at every level. For example, an extension may handle `ResetPlayerSession` for as long as it is loaded, while a cinematic segment may handle a request only while that segment runs. A local call can use the segment registration directly. A reset delivery may need to wait through an extension reload, while unfinished work tied to one cinematic segment may need to end with that segment. The owner of this choice is being reconsidered: it could be the lifetime, each handler registration, or the request. When pending deliveries are kept, the runtime must recognize the same logical handler after its lifetime is recreated; attaching a new callback object cannot by itself make completed work new again. Cancelling or expiring the request itself remains a separate choice. The exact registration syntax, default close behavior, and rule for a delivery already executing when its lifetime closes remain open.

An ordinary local function remains an ordinary function. The legacy block-break handler runs now, in the engine, and directly asks the session manager to start or advance dialogue. By contrast, “reset this stored value tomorrow” needs something Realm can keep while engines are offline: a typed request value such as `ResetKills(entryId, playerId)`. When an engine returns, the runtime decodes that request and dispatches it to every registered handler for its type in the target context. A graph could also produce that typed request without holding a direct function call. This is the working boundary: declare an operation when Typewriter needs to **save a call or route it through its runtime**. Calling `player.sendMessage(...)` now needs no declaration, even if the method comes from another extension's ordinary API. A visible-time override can likewise be an ordinary receiver function returning a closeable handle for a lifetime to own.

Illustrative typed operation DX:

```kotlin
data class ResetKills(val entryId: EntryId, val playerId: PlayerId) : Operation

context(engine: Engine)
suspend fun ResetKills.handle() {
    // Resolve the current entry/player state and perform a checked data transaction.
}

transaction.schedule(ResetKills(entry.id, player.id), at = tomorrow)
```

This sketch uses a receiver function for a handler because that fits the preferred Kotlin DX; generated registration could connect multiple such handlers to the request type. It is a proposal, not a verified production API. The author passes a `ResetKills` value, not a string key plus an untyped map. Realm still needs to encode the request's type and fields. The existing [TypeId/ResolvedTypeRef model](../services/sdk/typewriter-contracts/src/main/kotlin/com/typewritermc/types/TypeModel.kt) already separates stored type identity from Kotlin class names; whether operations use that exact registry is an implementation decision. The persisted type identity lets the runtime locate handlers, while an **invocation ID** identifies the scheduled request and separate delivery identities can track individual handlers. A JVM class name should not be the durable identifier.

The response rule belongs to an event declaration, as agreed earlier. The rule is a small reducer over subscriber responses: command attempts might use deny-wins, while a client-visible update might use an ordered transform. Subscriber callbacks can request direct effects; response reduction does not roll those effects back. A plain observation uses the same subscription/lifetime mechanics without a decision.

### Event primitive, proposed contract

An event declaration identifies a typed occurrence and, when needed, a typed response rule. A publisher emits one occurrence; active subscribers receive that occurrence; the publisher gets one combined response before it continues if the event is immediate. The occurrence may hold live capability interfaces during that dispatch. Extension-published `CinematicStarted` and provider-published `BlockBreakAttempt` follow the same subscription rules. An event that only announces something has no decision response.

An extension-owned notification might look like `publish(CinematicStarted(playerId, sceneId))`; subscribers handle the `CinematicStarted` type. The author need not pass a string event name. Runtime discovery may still encode an internal type identity, just as durable operations do, but the event payload remains a typed value in extension code.

Receiver-oriented views select where to listen: `minecraft.blockBreakAttempts` observes all players, while `player.blockBreakAttempts` filters to one player. These remain views of the same declaration, so their handlers contribute to one result. The provider can install native sources on demand, but that is invisible to the subscriber.

An illustrative decision handler is:

```kotlin
minecraft.blockBreakAttempts.on(entryScope) { attempt ->
    if (!matches(attempt)) return@on Pass
    requestDialogueStartOrAdvance(attempt.player) // requested even if the break is denied
    if (cancelFor(attempt.player)) Deny else Pass
}
```

Returning `Pass`/`Deny` is the current small candidate. It lets the event declaration reduce immutable answers without a mutable decision object in each callback. The alternative `attempt.deny()` remains open because the user has not chosen between them. Either way, an event does not schedule the handler for later or roll back its direct effects.

State deliberately has a different contract from an event. Repeated `CinematicStarted` occurrences can matter even when the player was already playing; `player.cinematicPlaying` answers what is true now. Whether equal consecutive values trigger another state callback is still open. The [Kotlin StateFlow/SharedFlow distinction](https://kotlinlang.org/docs/coroutines-flow.html#hot-flows) is a precedent for this separation, not a requirement to expose those library types.

Delivery is a policy applied to an **invocation**, not a second kind of business action: direct invocation runs now, an asynchronous dispatcher queues work locally, and a durable scheduler persists a portable call for later. A durable call carries stable identities and serializable input; handlers resolve any live handles when they run. A given operation is eligible only for the delivery modes it can actually support. The typed-data transaction remains a separate storage operation that validates reads and commits writes atomically; removing event staging did not remove it.

Declarations have stable identity and types; receiver-oriented accessors bind them to an owner. For example, `minecraft.commandAttempts` can mean the event across all players while `player.commandAttempts` is a filtered view of that same event. Both contribute to one declared decision rule during dispatch. Likewise, `player.cinematicPlaying` binds a declared state to that player, and a receiver function can prepare an operation call with the player's identity. Filtering or binding must not silently create a second event with a separate outcome.

| Behavior | Composition |
| --- | --- |
| Block break starts dialogue and denies damage to the block | Entry lifetime owns a block-break event subscription; the handler calls dialogue directly and returns `Deny`. |
| Cinematic holds commands and replays them afterward | Segment lifetime owns a command-attempt subscription and a local command list; closing the blocker precedes replay. |
| Frozen player time | A receiver function applies the initial visible time, maintains it internally, and returns a handle owned by the audience lifetime. |
| Cinematic audience follows already-active players | `player.cinematicPlaying` supplies current state and later values through one owned observation. |
| Stored value expires | A value write commits a durable typed operation request in the same data transaction; its due handlers run, and a reset handler performs a checked data transaction. |
| Dialogue hides chat and later restores it | An owned outgoing-message decision subscription captures messages in local history; a replay call runs after the subscription closes. |

These compositions exercise the same primitives in unrelated features. No “cinematic manager,” “fact watcher,” “packet interceptor,” or “timer event” has to be a public core component. Capability and extension code can still package repeated compositions behind concise receiver functions.

Two useful author-facing forms follow from those primitives:

- **Maintained effect:** call a local function or operation, then have the lifetime own its closeable result. `segment.own(player.overrideVisibleTime(time))` could express the composition. The behavior must apply the initial state, keep the desired result in force if necessary, and release it when closed. Overlapping effect rules belong to that behavior's contract.
- **Current-value observation:** `player.cinematicPlaying.observe(scope) { playing -> ... }` attaches to declared state. The state provider is responsible for the consistent initial read and subsequent delivery. This can share subscription ownership with events, while preserving its distinct initial-value contract.

These are developer-facing conveniences, not a requirement for separate generic dispatchers or a universal registry of effects. The provider may assemble each behavior from listeners, packet hooks, state snapshots, or other internal mechanisms. The exact APIs and guarantees remain open.

One cinematic segment shows the composition, with names still illustrative:

```kotlin
context(segment: ReactionScope)
fun MinecraftPlayer.runSegment(fixedTime: Int) {
    segment.own(overrideVisibleTime(fixedTime))
    commandAttempts.on(segment) { attempt ->
        if (attempt.command.isAllowedDuringCinematic()) Pass else Deny
    }
    cinematicPlaying.observe(segment) { playing ->
        updateAudience(playing)
    }
}
```

`overrideVisibleTime` is a receiver function returning an owned resource; it could itself invoke a declared operation if Typewriter needed to remember or hand off that call. `commandAttempts` is an event, `cinematicPlaying` is state, and `segment` owns their cleanup. A block-break entry can use the same event and lifetime mechanisms with different declarations. A data reset can use a state or event to decide when to invoke a durable operation. The sample intentionally has no cinematic-specific framework component.

For an extension-declared state, the owner supplies the current value and its updates for a typed key; consumers cannot publish to another extension's state through `observe`. An extension may keep that value in memory, derive it from other live state, or expose a projection of Realm data. The observable-state contract must make attachment linearizable from the consumer's perspective: an update racing with attachment appears either in the initial value or in the subsequent stream, never disappears between them. It should also define what happens when the source has not loaded its initial value yet. Current runtime [registrars](../services/sdk/typewriter-contracts/src/main/kotlin/com/typewritermc/discovery/DiscoveryRuntimeContract.kt) and [element facets](../services/sdk/typewriter-contracts/src/main/kotlin/com/typewritermc/elements/ElementRuntime.kt) already attach through suspending functions, so a suspending initial attachment is feasible at those call sites; callback context and exact API remain undecided.

The block-break sketch follows the legacy handler's order: it requests dialogue first and may then cancel the break. `Pass` means this entry does not object; the event declaration combines decisions from every matching entry. The subscription closes with the entry. An analogous cinematic-segment handler would add blocked commands to segment-owned state, return `Deny`, and replay them when that segment closes. Names and exact APIs are unsettled.

Illustrative consumer code, with unsettled names:

```kotlin
context(scope: RuntimeScope, minecraft: Minecraft)
fun register() {
    minecraft.playerJoined.on(scope) { joined ->
        refreshGroup.request(joined.playerId)
    }
}

context(segment: ReactionScope, minecraft: Minecraft)
fun blockCommands(player: MinecraftPlayer) {
    player.commandAttempts.on(segment) { attempt ->
        if (attempt.command.isAllowedDuringCinematic()) Allow else Deny
    }
}
```

The example says nothing about Paper listeners or packets. An internal publisher could emit `CinematicStarted` through the same event registry. Provider-side first/last subscriber hooks, when supplied, are an implementation concern. Maintained effects such as frozen time may deserve a scoped capability operation rather than an event callback; the use case should decide that interface instead of forcing an event-shaped API.

An alternative immediate-handler sketch is now under discussion, because extension authors need live game reads:

```kotlin
minecraft.commandAttempts.on(scope) { attempt ->
    if (attempt.player.world.key == blockedWorld) Deny else Allow
}
```

Here `attempt.player` is a live Minecraft capability interface implemented by the engine, not a captured player ID. In a Paper-targeted source set, the same handle may have a stronger `PaperPlayer` type with access to native Paper functionality. This needs compile-time specialization so authors do not scatter casts throughout handlers. Each immediate event must guarantee a safe execution context for the live methods it exposes. For packet-backed sources this may mean moving the decision to a later safe game-processing point or deferring packet processing. Whether a particular hook can do that without changing ordering or behavior needs a Paper implementation spike before promising it as a shared capability event.

A small standalone Kotlin compile check at `/private/tmp/typewriter-event-type-spike.kt` confirmed one possible type shape: `Minecraft<out P : MinecraftPlayer>` exposes `Event<P>`, shared code subscribes through `Minecraft<MinecraftPlayer>`, and Paper-specific code subscribes through `PaperMinecraft : Minecraft<PaperPlayer>` with `PaperPlayer` inferred in the callback. This checks Kotlin typing only. Runtime event identity, registration, generated source-set bindings, and actual native handle access still need design and verification.

During event dispatch, a handler can request Typewriter work and contribute its decision independently. The event declaration combines decisions and the provider applies the combined result before the underlying action continues. Work that needs to happen later belongs to an explicit owner such as a cinematic segment, an asynchronous engine job, or a durable scheduled operation. A later completion event remains a possible way to observe what the underlying action actually did, if a use case needs that distinction.

The frozen-time example tests that boundary. Its legacy implementation installs a packet rewrite, repeatedly sends the desired value, and restores normal time when the player leaves the audience. A subscription to “time packet sent” would express only the rewrite; it would leave initial application and cleanup to unrelated glue. A scoped resource such as `scope.own(player.overrideVisibleTime(value))` could express the whole behavior and let each engine choose its mechanism. How overlapping overrides resolve remains the behavior's contract, not an event decision by default.

Advertising that an engine fulfills an event and attaching its native source are different actions. An engine can register a cheap provider descriptor for every event in its claimed capability at activation, then install only the demanded native listeners. An extension-owned event can be published directly without such an engine descriptor. For immediate decisions that depend on stored values, the engine cannot wait for Realm during a hot native callback; a later decision is needed about which locally available snapshot, if any, is valid for these checks.

## Current-code evidence and integration points

- The legacy [entry listener manager](../engine/engine-paper/src/main/kotlin/com/typewritermc/engine/paper/entry/EntryListeners.kt) filters registration to active event entry types. [Cinematic start](../engine/engine-paper/src/main/kotlin/com/typewritermc/engine/paper/entry/temporal/TemporalInteraction.kt) is published internally. The legacy [packet interceptor](../engine/engine-paper/src/main/kotlin/com/typewritermc/engine/paper/interaction/PacketInterceptor.kt) owns temporary, player-scoped callbacks for observation, cancellation, and mutation. These are design references; legacy files remain unchanged.
- The legacy [frozen-time audience](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/audience/FreezeTimeAudienceEntry.kt) combines outgoing packet rewriting, periodic refresh, and restoration on removal. Its intended semantic behavior is a maintained player-visible state, rather than a single packet occurrence.
- Current [engine capability contracts](../services/runtime/engine/api/src/main/kotlin/com/typewritermc/engine/EngineContracts.kt) express a complete contract an engine must fulfill. Paper claims the [Minecraft capability](../services/runtime/engine/runtimes/paper/build.gradle.kts), and the conformance extension demonstrates [capability-targeted source sets](../services/extensions/conformance/build.gradle.kts).
- Current [RuntimeScope](../services/sdk/typewriter-contracts/src/main/kotlin/com/typewritermc/discovery/DiscoveryRuntimeContract.kt) owns activation resources. [ElementRuntimeFacet](../services/sdk/typewriter-contracts/src/main/kotlin/com/typewritermc/elements/ElementRuntime.kt) returns a handle for one attached authored element. These are natural ownership boundaries for subscriptions, though entry runtime reconciliation is not yet wired into the production content gateway.
- The legacy [cinematic audience](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/audience/CinematicAudienceEntry.kt) queries current cinematic state when attached and listens for start/end events to update afterward. This is evidence that an occurrence and an observable current value have different subscription semantics. Observable state is part of this subsystem and must give a late subscriber an initial value atomically with later updates.
- Kotlin's [SharedFlow](https://kotlinlang.org/docs/coroutines-flow.html#hot-flows) broadcasts occurrences, while [StateFlow](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-state-flow/) retains a current value for new subscribers. This is a useful precedent for two small source contracts. Typewriter still needs its own keyed identity, lifetime, and immediate-decision rules, so these library types are not automatically the public API.
- [Dapr's pub/sub contract](https://docs.dapr.io/developing-applications/building-blocks/pubsub/pubsub-overview/) explicitly delivers a message at least once to every subscriber. This is a useful precedent for durable fan-out: repeating a handler can happen after failure. Typewriter's own per-handler receipt and retry rule remains to be designed.
- [Fabric's custom event example](https://docs.fabricmc.net/develop/events/) puts `PASS`/`SUCCESS`/`FAIL` aggregation in the event's invoker and stops at the first non-`PASS` answer. [Paper's listener documentation](https://docs.papermc.io/paper/dev/event-listeners/) instead describes mutable cancellation, ordered priorities, and later listeners changing earlier results. These are useful precedents, not the portable Typewriter contract: our declaration must state its own combination rule so provider mechanics do not leak into extension behavior.
- [Paper's chat event guide](https://docs.papermc.io/paper/dev/chat-events/) warns that using Bukkit APIs from an asynchronous handler is unsafe; [PacketEvents' threading guide](https://docs.packetevents.com/introduction/prerequisites/) describes network worker threads separately from the game thread. This supports making the threading and accessible-data guarantee explicit in each portable immediate event contract, rather than inheriting the source API's accident of execution.
- [Paper's Folia guidance](https://docs.papermc.io/paper/dev/folia-support/) assigns entity work to an entity scheduler that follows it across regions. This reinforces that “run on the main thread” is not a sufficient universal live-access contract even within the Paper family; the relevant player/world ownership must be defined.

## Open decisions, in dependency order

1. Validate receiver-first event DX against authored block breaks, interactions, command blocking, skip inputs, and internally published cinematic events. A user choice is pending between returning `Deny`/`Pass` and calling `attempt.deny()` on a Typewriter-owned decision context. Decide the shape of `player.commandAttempts.on(scope)` and how a handler requests ordinary Typewriter work without an operation wrapper at every call site.
2. Define the developer-facing execution-context guarantee for live player/world interfaces and direct effects in an immediate handler. The implementation may need to move work to the player's safe execution context before the underlying action continues. Per-engine adapter feasibility and the exact common capability boundary are deferred until that guarantee is designed.
3. What consistency an immediate handler can expect when it checks database-backed runtime data; a Realm request cannot be part of every synchronous decision.
4. The decision-rule API: ordering tie-breaks, subscriber failure behavior, and whether a transforming handler sees previous transforms. Participation policy is declaration-owned; choose its concrete value per event. Also define the boundary of guarantees when other host plugins or mods can change the same action. The earlier question about a universal exception fallback is set aside while the simpler effect model is resolved.
5. Define the general owned-resource rule for functions that start ongoing work: how a lifetime owns the returned handle, how close behaves, and how the behavior specifies overlap/restoration. Test it against visible time, camera/view state, and action-bar/chat visibility. Decide portable capability boundaries later. A stream of packet transformations alone does not cover initial application and teardown.
6. Define extension-declared state keys, publication/derivation, equality or duplicate-update rules, and how an observer receives a consistent initial value followed by changes. Decide whether a slow initial read can suspend attachment and how cancellation works while it is loading. Test this against cinematic audience state and effective stored-data/group values.
7. Define closure ordering and in-flight behavior. A cinematic command blocker must stop intercepting before it replays held commands, or its own replay can be captured again. A scope therefore needs a reliable way to end subscriptions/effects before running completion work. Also define how content replacement swaps old and new subscriber sets without a gap or duplicate decision.
8. Event identity/discovery and how extension-defined events are shared across extension boundaries and exposed to authored entries.
   The shared and engine-specific typed views of one capability event must resolve to one runtime event identity and one decision aggregation.
9. Test the working operation boundary against more real examples: use ordinary Kotlin receiver functions for work that runs in the current call, and declare a typed operation request when Typewriter must save or route a call. Define request type registration, input encoding, routing to the owning engine or player, outcomes for each handler, local versus durable delivery, replacement keys, retries, and failure outcomes. Due requests with no handlers remain open until a handler runs, cancellation, or expiry. Approval staging within an event is removed. The separate stored data transaction still collects writes and atomically commits them after validating read dependencies.
