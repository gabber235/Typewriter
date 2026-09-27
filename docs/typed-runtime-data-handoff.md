# Typed runtime data: design handoff

Status: paused design discussion, 2026-09-26. The event, interception, and invocation subsystem now has priority because typed data needs it for automatic changes and other gameplay features need it too. This document records decisions and open work; it is not an implementation plan. No production code or storage schema was changed for this design.

## Goal and scope

Replace the **legacy fact system** with database-backed, typed runtime data. An extension can declare a stored value for any entry, including an action entry, or for another identity such as a player, entity, or derived group. Entries remain ordinary authored entries; a stored value does not require a special fact entry type. Values are available to other entries, engine code, and the panel.

The new system should be pleasant to declare and use frequently. The system must work across Minecraft servers with Realm as the authority, retain the identities behind a value, and let the panel inspect data offline. This is separate from the current `DeploymentFacts` used for runtime/discovery availability.

## Agreed stored-value DX

- Declare values at top level. A stable explicit ID preserves the persisted value if the Kotlin property is renamed. A typed default is required.
- Exactly one declared identity is the primary receiver. Additional identities are ordered, named roles. Roles may share a type, such as speaker and listener.
- Generate Kotlin accessors so reads look like `entry.kills[player]` or `speaker.trust[listener]`: the primary identity is an extension receiver, and brackets supply additional identities. This shape was reaffirmed after the broader preference for extension receivers. For a value with no extra roles, use `player.rank()` to read and `player.rank(newValue)` to write. Indexed assignment should work inside a transaction. `reset()` removes the override.
- A typed key may be expressed by a top-level declaration along these lines (syntax remains a sketch):

  ```kotlin
  @Stored("stable-id")
  val kills = stored(default = 0)
      .on<Ref<Entry>>("entry")
      .with<PlayerId>("player")
  ```

- Reads are available in a `context(data: DataRead)` scope. `data.transaction { ... }` supplies `DataTransaction : DataRead`, so the same read syntax works within a transaction and tracks dependencies. Writes are confined to transactions.
- An absent override and an explicitly stored default value are distinguishable. Reset means absence, with the declared default used for the effective read.
- The panel should use generated type metadata and the same stable IDs. A future type change can use the generic Typewriter type migrator; a storage-specific migration system was not designed. Data and identity links should remain recoverable after an owning entry is deleted.

### DX feasibility checked

A temporary KSP/Kotlin spike in `/private/tmp/typewriter-ksp-dx-spike` compiled with Kotlin 2.4.10 and KSP 2.3.10. KSP resolved the inferred declaration type and generated the receiver accessor. A `Ref<ActionEntry>` could use `entry.kills[player]`; `player.rank()` and `player.rank(7)` compiled and ran. The temporary consumer's `:consumer:run` passed. A separate Kotlin context-parameter spike verified that a nested transaction scope selects its `DataTransaction` receiver over an outer read scope. These checks establish that the accessor shape is feasible; they do **not** establish the production persistence, registration, or panel integration design.

## Identity, groups, and offline inspection

- Each stored value has a canonical identity key based on its declared roles. A group-owned value belongs to the group; a player's group lookup is a separate identity relationship. Composite identities and multiple same-type roles must remain possible.
- Group resolution can depend on live server state that Realm and the offline panel cannot recompute. Persist the **observed player-to-group relationship**, including when it was observed, even when the player only reads a group value and never writes it.
- The panel may display the last observed group and its observation time. It must not claim that this is the player's current live membership.
- A live engine read that finds group B while Realm still records group A returns B immediately and updates its local cache. It queues an asynchronous persistence refresh rather than making an identity-read database call. Until that refresh commits, the panel may still show A. A crash before persistence may lose the hint; this eventual-refresh behavior was explicitly accepted.
- A transaction that uses B before the queued refresh commits includes the new player-to-B observation in the **same atomic commit** as its value changes. Group resolution should carry this provenance so the transaction needs no separate lookup. An explicit observe operation also exists for link-only persistence.
- Event and scheduled refreshes can use the future invocation subsystem. Refresh execution should re-resolve current state rather than persist a group captured earlier in a queued request.

## Transaction and consistency contract

- Engine code may read several stored values, including across entries and identities, compute changes, and submit all writes as one Realm transaction. Realm is authoritative and commits all or none.
- This transaction's write collection is specific to atomic stored-data commits. It remains required even though event-local approval staging was removed from the runtime reactions design.
- Reads become dependencies even if they are not written. Dependencies include absent/default reads and observed identity relationships. Realm validates revisions or equivalent prior-state tokens at commit. A mismatch returns a recoverable conflict.
- On conflict, the engine reruns the **pure decision closure**, rereads and rediscovers dependencies, and resubmits. Retries are bounded. Gameplay side effects run after a successful commit, outside the retrying closure.
- A stable **transaction invocation ID** and commit receipt resolve an unknown result when the connection fails after Realm may have committed. This identifies one attempted commit, not an operation type. Panel edits use the same conflict semantics.
- There is no requirement for arbitrary predicate queries against stored values in Realm. Earlier speculation in that direction was corrected.
- Effective value changes should be observable for gameplay and panel updates, including changes to a shared group value. The runtime reactions design now includes extension-declared typed observable state: a late observer receives the current effective value and later changes without a gap. A committed change may also be published as an occurrence when its cause and old/new values matter. Feedback loops and high-frequency sources need explicit control.

## Automatic changes and scheduled work

Requirements include resets on future events such as player join, selected bulk resets, one-shot expiries, and periodic refreshes. Pending work may be replaced or retained when a new write occurs, according to the call's policy. A reset made due by a value write should be scheduled atomically with that write. If an older request has already been picked up, its generation must be checked when it commits so it cannot clear a newer value.

Realm persists due work and its identity. Extension code runs on an engine. If every Minecraft server is offline at the due time, it is sufficient to catch up when an engine reconnects; Realm does not need to execute extension logic itself. A one-shot reset should have one effective application. A periodic refresh should calculate the current state once after an outage rather than replay every missed interval.

The automation API is **not settled**. An early sketch used typed `Source<T>` pipelines, named `Operation<T>` handlers, and an explicit boundary between requesting and scheduling. The current runtime reactions proposal instead treats an operation as a **concrete typed request**, such as `ResetKills(entryId, playerId)`, dispatched to its participating handlers. Extension code does not pass handwritten strings to name operations. Any lifetime, including an extension, entry, or segment, may own a handler registration. Closing that lifetime removes the active registration. The owner of the rule for unfinished durable deliveries is being reconsidered: it could be the lifetime, each registration, or the request. The runtime needs stable delivery identity when pending work survives recreation of a lifetime. Cancellation or expiry of the request itself is separate from one handler's delivery. Handlers are independent: a completed handler stays complete while failed handlers are retried; they do not automatically share one Realm transaction. A durable request stays open while any handler is pending. A handler registered while it is open gets its own delivery, even if another handler already completed; after all participating handlers finish, the request closes and later handlers do not receive it. A due request with no handlers remains open until a handler can run, unless cancelled or expired. Invocation delivery may be local synchronous, local asynchronous, or durable; event sources, stored value changes, timers, and graph execution can request those invocations. Exact declaration syntax, overall outcomes, execution affinity, and durable delivery remain to be designed. A live event decision such as cancellation must finish synchronously; durable requests contain portable identities and values and may run later or again after failure. A handler can use the separate atomic stored data transaction to update several values together.

## Why the event/invocation subsystem is first

Legacy Typewriter supplies concrete uses beyond data: [delayed graph continuation](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/action/DelayedActionEntry.kt), [group fan-out](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/action/GroupTriggerActionEntry.kt), [fact-change reactions](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/event/FactChangeEventEntry.kt), and [synchronous event cancellation](../extensions/BasicExtension/src/main/kotlin/com/typewritermc/basic/entries/event/InteractEventEntry.kt). The [packet interceptor](../engine/engine-paper/src/main/kotlin/com/typewritermc/engine/paper/interaction/PacketInterceptor.kt) adds short-lived, player-scoped subscriptions that observe, modify, or cancel packets. These are design references only; legacy directories must not be edited.

The current [engine capability contract](../services/runtime/engine/api/src/main/kotlin/com/typewritermc/engine/EngineContracts.kt) says that an engine claiming a capability implements its complete API. Paper declares the [Minecraft capability](../services/runtime/engine/runtimes/paper/build.gradle.kts); the conformance extension demonstrates a [capability-targeted source set](../services/extensions/conformance/build.gradle.kts). The new event/interception model must let an extension target the Minecraft capability while Paper, and later Minestom or Fabric if they claim it, fulfill the same **semantic** contract. A capability user must not be able to tell whether the engine fulfilled a hook through a native Minecraft event, packet interception, or another mechanism. Capability contracts describe observable input and allowed decisions, not the adapter technique. A narrower capability or engine-specific API is appropriate only when a shared semantic guarantee cannot be implemented by every engine claiming the broader capability; capability boundaries must not mirror implementation libraries. Event subscriptions need activation-scoped cleanup; [RuntimeScope](../services/sdk/typewriter-contracts/src/main/kotlin/com/typewritermc/discovery/DiscoveryRuntimeContract.kt) already has ownership hooks.

The provider must also control **how its sources are activated**. An engine should be able to register a native Paper listener only when an active consumer needs its event, rather than registering every possible event. This is an optimization, not a capability-level obligation: some sources are emitted internally (the legacy [cinematic start event](../engine/engine-paper/src/main/kotlin/com/typewritermc/engine/paper/events/AsyncCinematicStartEvent.kt) is an example), and others may need a permanent or shared native listener. The public contract promises delivery to active subscriptions and correct cleanup; it does not require a particular native registration strategy. The provider can receive first-subscriber/last-subscriber demand signals, while owning any native registration and making first-subscription readiness unambiguous.

## Open work when this design resumes

1. Finalize the event/interception/invocation model first, including synchronous decisions, packet mutation, subscription ownership, execution affinity, and durable delivery.
2. Use that model to express data-change reactions, identity refresh, expiries, and event-driven resets without a special automation path inside stored values.
3. Specify production stored-value registration, portable type metadata, identity keys and provenance, transaction validation/retry, scheduling in the same commit, Realm APIs, panel querying/editing, and engine caching.
4. Verify the DX in the real SDK and codegen, then implement a vertical slice through Realm, engine, and panel. Preserve the current dirty worktree and update all affected current-code consumers together. No database table design, migration, or production implementation has been approved or done here.
