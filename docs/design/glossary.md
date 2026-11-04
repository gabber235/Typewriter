# Glossary

Every type, annotation, and term used in the design set, one line each, with the file that explains it. The primitives on one page are in [overview.md](overview.md).

## Symbols

**`@As` and `@From`**: typed roles; an event marks two fields of one kind with `@As(Role::class)` and a handler picks one with `@From(Role::class)`. See [events-and-handlers.md](events-and-handlers.md#resolution).

**`@Derive`**: marks a pure function over tracked inputs whose result type (`Stored`, `Hold`, or `Live`) decides what the system maintains. See [overview.md](overview.md#derive).

**`@Handler`**: marks a Kotlin function with an event receiver whose parameter types decide when and where it runs and whose return type decides its phase. See [events-and-handlers.md](events-and-handlers.md#handler).

**`@Key`**: marks the fields of a Kotlin `Stored`, `Live`, or `Hold` type that are its keys; KSP turns a stored type into a `stored(...)` call. See [stored-data.md](stored-data.md#kotlin-form).

**`@TypewriterType`**: the v1 type annotation; on a developer defined stored type it carries an id and a revision so the migrator can convert its data, and every event carries it, so an event crosses engines as its catalog value. See [migrations.md](migrations.md#developer-migrator) and [events-and-handlers.md](events-and-handlers.md#event).

**`/tw fire`**: the command that fires an entry for a target, written target first (`/tw fire <player> <entry>`) so suggestions follow the target. See [events-and-handlers.md](events-and-handlers.md#content-commands).

## A

**Action entry**: an instant entry whose handler on `Triggered<E>` does its work and fires its links without becoming a step. See [events-and-handlers.md](events-and-handlers.md#firing-and-triggered).

**`Added<T>`**: lifecycle event fired when a stored value, hold, or mirror appears for a set of keys. See [stored-data.md](stored-data.md#lifecycle-events).

**Adoption**: an equal hold for the same protagonist within the grace takes over the old hold and its snapshot, so neither `Removed` nor `Added` fires. See [interactions.md](interactions.md#grace-and-adoption).

**`advance`**: dialogue creator field (`Anyone`, `Everyone`, `Leader`) that says which group members may advance a party dialogue. See [interactions.md](interactions.md#party-dialogues-and-leaving).

**After phase**: the phase of handlers returning `Unit`, a `Live` type, or a `Runtime` type; they run after the outcome was applied and may suspend. See [events-and-handlers.md](events-and-handlers.md#return-value-decides-the-phase).

**`AfterWrite<K, T>`**: variable reaction that runs a duration after the first or last write (`from: Write`, `First` or `Last`). See [stored-data.md](stored-data.md#reactions).

**`All<T>`**: handler parameter that resolves to every value of type `T`. See [events-and-handlers.md](events-and-handlers.md#parameters).

**`ArmSwing`**: example event with one meaning reached through several sources; the first source starts the occurrence and the others join it. See [events-and-handlers.md](events-and-handlers.md#event).

**`attempt()`**: runs a transaction function or `Changes` field. It waits only when the write is guarded and returns `Committed` or `Refused(message)`. `ensure()` always waits. See [stored-data.md](stored-data.md#transaction-functions).

**Audience**: an `AudienceEntry` tree whose criteria are formulas over mirrors and whose membership is the `InAudience` mirror. See [live-data.md](live-data.md#audiences).

**`AuthoringCommit`**: one record of the realm commit history: id, actor, session, and a `ValueChange` (before and after) per changed value; it stores attribution and drives undo. See [panel-engine-communication.md](panel-engine-communication.md) question 12.

## B

**`Because`**: field on every `Added` and `Removed` saying whether the value really changed (`Value`) or tracking started or stopped (`Tracking`). See [live-data.md](live-data.md#added-changed-removed-and-because).

**`bind`**: `dynamic()` builder that derives a generic type parameter from content, so a bound parameter needs no picker. See [formula-language.md](formula-language.md#bind).

**Book**: a `Resource` (not an entry) that carries variables, instances, and imports. See [formula-language.md](formula-language.md#book).

**Book instance**: one entry in a book's `instances` map, keyed by the instance key, and an identity stored data can be about. See [formula-language.md](formula-language.md#instances).

**Book narrowing**: the check inside `fire` that only follows links into books that apply to the subject. See [events-and-handlers.md](events-and-handlers.md#firing-and-triggered).

**`BookConfiguration`**: the existing configuration system whose key rules apply to a book's `variables`. See [formula-language.md](formula-language.md#variables).

**`BookScope`**: formula context whose purpose is open; the book's `instances` field uses `PublishScope`. See [formula-language.md](formula-language.md#formula-contexts).

**`BoundPath<T>`**: a place in authored content, such as where a capture or mode writes or which reaction a `Due` runs; its portable form is the `value_location` representation, so stored values can keep it, and it is an identity that ends when the place is gone. See [panel-engine-communication.md](panel-engine-communication.md#emit-without-extension-code-in-the-panel-engine-2026-11-01).

**Bridge**: the conversion of one Typewriter value type to and from an engine's own type (`toPlatform`, `fromPlatform`), registered per engine kind. See [engines.md](engines.md#bridges).

## C

**`CameraHold`**: the hold a scene uses for the camera; it snapshots location, flight, and velocity and restores them at the end. See [interactions.md](interactions.md#scenes).

**`Candidate<E>`**: handler parameter that runs once per published entry of type `E` whose book applies to the subject. See [events-and-handlers.md](events-and-handlers.md#parameters).

**Capability**: an engine specific feature set (such as `Tick` or the Minecraft traits) kept out of the engine neutral core. See [live-data.md](live-data.md#engines-and-traits).

**Capability root**: a scope contribution from a capability (such as `minecraft`) that formulas resolve last. Holds pure values only (constants, registry ids, types); live data hangs off `engine: Engine`. See [formula-language.md](formula-language.md#lookup-order).

**Chain**: entries linked by triggers, where links fire explicitly and carry a growing context. See [events-and-handlers.md](events-and-handlers.md#chain).

**Change operations**: the native storage operations (`set`, `add`, `multiply`, `max`, `min`, `setIfAbsent`, `append`, `remove`, `addAll`, `removeAll`, `put`, `clear`, `require`) the realm applies itself. See [stored-data.md](stored-data.md#change-operations).

**`Changed<T>(old, new)`**: lifecycle event fired when the value at a set of keys changes; for stored values it runs after the commit. See [stored-data.md](stored-data.md#lifecycle-events).

**`Changes`**: the value type of an update field; an ordered list of change lines, a transaction written in formula text, that the entry commits with `attempt()`. See [stored-data.md](stored-data.md#changes-fields).

**`check(formula)`**: the query graph step that type checks one formula. See [formula-language.md](formula-language.md#type-checking).

**Checks**: the one list of build time (KSP) and realm findings, where errors block publication and warnings and info never do. See [live-data.md](live-data.md#checks).

**`ChosenTarget`**: stored value `ChosenTarget(user, target)` naming the protagonist a panel user acts on, so the choice follows the user across devices. See [panel-engine-communication.md](panel-engine-communication.md) question 9.

**Clash**: what happens when an incoming step needs a hold type another interaction holds for the same protagonist. See [interactions.md](interactions.md#clashes).

**`ClientPosition`**: example wire event that is only a fake view, kept separate from `PlayerMove` because its effect differs. See [events-and-handlers.md](events-and-handlers.md#event).

**Command**: a hold (contributed by a derive), an event (it ran), and data (the node tree) at once. See [events-and-handlers.md](events-and-handlers.md#commands).

**Command node**: a `literal`, `argument`, or `runs<Event>()` element of a command contribution; contributions merge into one tree per player. See [events-and-handlers.md](events-and-handlers.md#shape).

**`complete(context)`**: the `Triggerable` shortcut that applies the entry's changes and then fires its triggers. See [events-and-handlers.md](events-and-handlers.md#triggerable-and-complete).

**`Confirm`**: intent event for advancing, raised only when the raw key is the one currently offered. See [events-and-handlers.md](events-and-handlers.md#event).

**Configured event**: an event with a configuration type parameter (`Tick<C : TickConfig>`) whose source only emits for configurations some handler can run for. See [events-and-handlers.md](events-and-handlers.md#configured-events).

**`ConfiguredSource<E, C>`**: source interface whose `open(demand: Demand<C>, sink: Sink<E>)` receives the configurations that currently have a runnable handler. See [events-and-handlers.md](events-and-handlers.md#configured-events).

**`ContentCommandRan`**: event a content command node runs; its handler fires the node's triggers with the arguments as context. See [events-and-handlers.md](events-and-handlers.md#content-commands).

**`ContentDelivery`**: `Live` value keyed by `Engine` with the publication the engine applied or its delivery failure, so the panel shows "applied on N of M engines". See [panel-engine-communication.md](panel-engine-communication.md) question 10.

**Context (chain)**: a typed bag of produced records passed along a chain that only grows. See [events-and-handlers.md](events-and-handlers.md#context).

**Context (formula)**: the interface `C` in `Var<T, C>` whose properties are the values a field's formulas see. See [formula-language.md](formula-language.md#formula-contexts).

**`ContinueForEachMember`**: widening action that makes one copy of the chain per member, with only `protagonist` in formulas. See [interactions.md](interactions.md#widening).

**`ContinueForEveryone(who)`**: widening action that evaluates a protagonist list into a snapshot group keyed by the new interaction. See [interactions.md](interactions.md#widening).

**`ContinueForGroup(grouping)`**: widening action that fires once per distinct group of the members, with the grouping's type as `group`. See [interactions.md](interactions.md#widening).

**Conversion formula**: the creator formula that maps old stored values to a new variable type or keys; the default clears the values. See [migrations.md](migrations.md#the-conversion-formula).

**Creator type**: a `Definition` whose type is `Type`; exported types become type names and records get a constructor. See [formula-language.md](formula-language.md#definition).

**`CronSchedule`**: core `Schedule` from a cron expression and a time zone. See [stored-data.md](stored-data.md#due).

**`CustomCommandEntry`**: manifest entry that, with its argument entries, builds content command nodes. See [events-and-handlers.md](events-and-handlers.md#content-commands).

## D

**Decision phase**: the phase of handlers returning a `Verdict`; pure, never suspending, taking part in allow, deny, change, or pass. See [events-and-handlers.md](events-and-handlers.md#return-value-decides-the-phase).

**Dedupe key**: (connection, kind, client sequence number) when a packet has one, otherwise per connection order; never timing guesses. See [events-and-handlers.md](events-and-handlers.md#occurrences-and-dedupe).

**`Definition<T>`**: static entry holding a shared named value of any type, visible by name in the book and through imports. See [formula-language.md](formula-language.md#definition).

**`DefinitionScope`**: formula context for a `Definition`'s value, providing the definition's surroundings. See [formula-language.md](formula-language.md#formula-contexts).

**Demand**: per identity and key interest from a reader that could actually run; mirrors and lazy sources only work where there is demand. It is necessity in the `TrackedGraph`: a key is demanded when a path leads from an observer to it. See [live-data.md](live-data.md#demand).

**`demand` and `mirrors` KV buckets**: per realm NATS KV buckets through which a reader on one engine demands a mirror and producers on other engines publish its values. See [live-data.md](live-data.md#demand-across-engines).

**`Demand<C>`**: source input for configured events: the configurations that currently have a handler whose other parameters are satisfiable. See [events-and-handlers.md](events-and-handlers.md#demand).

**Derive**: a pure function over tracked inputs whose result type decides what it maintains. See [overview.md](overview.md#derive).

**Derived type**: a type built by `bind`, with id `content(at)` (the field the `bind` reads) and revision 1. See [formula-language.md](formula-language.md#bind).

**Developer migrator**: the step a developer writes to convert a stored type's data between two revisions. See [migrations.md](migrations.md#developer-migrator).

**`DialogueHold`**: example hold derived from `Speaking` that shows a dialogue. See [interactions.md](interactions.md#holds).

**Dry run**: a read only evaluation of a migration against real stored values on every edit. See [migrations.md](migrations.md#checks-while-editing).

**`Due`**: durable time; a stored value with `at` and an optional `repeat`. When `at` passes, the realm removes the row or moves it to its next time and fires `Elapsed<D>`, whose handlers are stored only. See [stored-data.md](stored-data.md#due).

**`dynamic()`**: the hook on every resource and entry type that tells the type system what its content means through builders. See [formula-language.md](formula-language.md#dynamic-what-content-means-to-the-type-system).

## E

**`EditExpectation.exists`**: authoring guard that a value location exists or not; it replaces `resource_exists`, and list operations guard only the items they name with it. See [panel-engine-communication.md](panel-engine-communication.md) question 12.

**`emit()`**: queues an event from a handler; it is decided after the current event finishes, without nesting. See [events-and-handlers.md](events-and-handlers.md#emitting).

**`Elapsed<D>`**: event fired on the realm when a `Due` of type `D` reaches `at`; carries the fired value as `due`. See [stored-data.md](stored-data.md#due).

**Engine**: runs published content through extensions (Paper, panel, future engines); engines share stored state only through the realm; live effects and events go directly between sessions. `Engine(id)` is also an identity, keyed by the stable topology engine id, so what an engine knows (`Stored`) and is doing (`Live`) are ordinary values keyed by it. See [live-data.md](live-data.md#engines-and-traits).

**Engine kind**: the engine artifact an engine runs (`EngineKind`, the topology `EngineTarget.engine_id`, such as `typewritermc:paper`); open to third party engines and stored once in the topology. Bridges register per kind, each kind supplies its session ids and grace, and interactions stay inside one kind. See [live-data.md](live-data.md#session).

**`EnginePart`**: marker for a class an extension adds to an engine; KSP finds it by supertype and it joins the deployment's Koin. See [events-and-handlers.md](events-and-handlers.md#engine-parts).

**Entry record**: a chain context record keyed by producing entry plus type, add only. See [events-and-handlers.md](events-and-handlers.md#context).

**Event**: a plain Kotlin type saying one thing happened, one type per meaning; every event is a `@TypewriterType`, so it crosses engines as its catalog value. See [events-and-handlers.md](events-and-handlers.md#event).

**Event result**: what an event emitted from a session reports back to that session: `Done`, `Denied(reason)`, `Failed(reason)`, or `NotHandled`. See [events-and-handlers.md](events-and-handlers.md#follow-ups-and-cancel).

**Event without a subject**: an event such as `Tick` whose handler parameters become a query, running once per match. See [events-and-handlers.md](events-and-handlers.md#events-without-a-subject).

**`Every<K, T>`**: variable reaction that runs for every stored key on a `Schedule`. See [stored-data.md](stored-data.md#reactions).

**`EverySource`**: core configured source that arms the `ReactionTimer` of every published `Every`, at startup and after each publish. See [stored-data.md](stored-data.md#how-timed-reactions-fire).

**`EveryTick`**: core `TickConfig` object for a handler that runs every tick. See [events-and-handlers.md](events-and-handlers.md#configured-events).

**Exceptions**: a throwing provider or the recursion limit fails one evaluation: text shows a fallback, conditions are not met, changes are not applied. See [formula-language.md](formula-language.md#exceptions).

**`exports { }`**: `dynamic()` builder saying what other resources get when they name this one. See [formula-language.md](formula-language.md#scope-and-exports).

## F

**Finder**: a `Live` type plus producing handlers that finds a value for a handler, such as the nearest NPC. See [live-data.md](live-data.md#finders-are-mirrors).

**`fire(context)`**: fires a link set, emitting one `Triggered<E>` per linked entry; `for = group` widens it. See [events-and-handlers.md](events-and-handlers.md#firing-and-triggered).

**Follow up**: a block on a verdict (`allow { }`, `deny { }`, `pass { }`) that runs when the final outcome matches it. See [events-and-handlers.md](events-and-handlers.md#follow-ups-and-cancel).

**Formula**: a creator or extension expression in its own typed language with its own interpreter, separate from v1 portable expressions. See [formula-language.md](formula-language.md).

**Formula kind**: Pure, Stored, or Live, the strongest kind a formula calls, which decides where it can run. See [formula-language.md](formula-language.md#where-formulas-run).

**`FormulaReads`**: what a formula or part can read, computed by the checker at publish. It decides the formula's kind and its memo key, so a formula is identified by what it reads, not by who asked. See [formula-language.md](formula-language.md#what-a-formula-reads).

**Formula start**: a chain start that fires when a formula turns true or whenever its output changes. See [formula-language.md](formula-language.md#formula-starts).

**`FormulaSnapshot`**: one streamed answer to `WatchFormula` with diagnostics, result type, completions, and hover. See [formula-language.md](formula-language.md#watchformula).

**Forwarding**: a start fired into an entry already in a running interaction joins that interaction when the trigger type is marked forwardable. See [interactions.md](interactions.md#creation-and-membership).

**Function typed field**: a `Var` whose `T` is a function type (`FunctionTypeTemplate`); its text is the body with the parameters in scope. See [formula-language.md](formula-language.md#function-typed-fields).

## G

**`GeneratedProviderLoader`**: loads the KSP generated formula providers. See [formula-language.md](formula-language.md#members-and-providers).

**Generation**: counter on steps and interactions so events and writes for a finished owner are dropped. See [stored-data.md](stored-data.md#identities-end).

**Global record**: a chain context record keyed by type only that describes the chain as a whole; newest wins, never removed. See [events-and-handlers.md](events-and-handlers.md#context).

**Grace (hold)**: the short delay (about 10 ticks) before a hold that stopped being returned is removed and restored. See [interactions.md](interactions.md#grace-and-adoption).

**Grace (session)**: how long a session survives without an engine reporting it, set per engine kind (about 10 seconds for Minecraft). See [live-data.md](live-data.md#session).

**Group identity**: a (group entry, key) pair such as `Group(islands, "42")` with stored data and derived members. See [interactions.md](interactions.md#groupings-and-membership).

**Group subject**: the subject of chain events; protagonist kind handler parameters then iterate its members. See [events-and-handlers.md](events-and-handlers.md#resolution).

**Grouping**: a way to bucket protagonists, declared by a static `GroupEntry`. See [interactions.md](interactions.md#groupings-and-membership).

## H

**`GuardedTransaction`**: a `Transaction` that also has `require`; declaring it in the signature tells codegen and the checker that the write can be refused. See [stored-data.md](stored-data.md#transaction-functions).

**Handler**: a Kotlin function with the event as receiver; parameters decide when and where it runs, the return type decides its phase. See [events-and-handlers.md](events-and-handlers.md#handler).

**`HasChat`, `HasInventory`, `Living`**: example live capability traits an engine provides for its identities. See [live-data.md](live-data.md#live-capability-traits).

**Hold**: a live, never saved change to how something looks or behaves on an engine, held while a derive returns it. See [interactions.md](interactions.md#holds).

**Hot publish**: publishing content while things run; content is a tracked input, so whatever read it reruns. See [live-data.md](live-data.md#hot-publish).

## I

**Identity**: catalog parent type for anything stored data can be about; the only types allowed as keys. See [stored-data.md](stored-data.md#identity).

**`Import`**: `Import(book, alias)` brings another book's exports into a book's contents scope. See [formula-language.md](formula-language.md#imports).

**Importer**: a separate one time tool that moves legacy 0.9 content and data into the new model. See [migrations.md](migrations.md#importer-for-09).

**`InAudience`**: `Live` mirror for a protagonist being inside an audience node, with `since`, the moment they entered. See [live-data.md](live-data.md#audiences).

**`initiated_by`**: the principal a trusted service names as behind a commit (the player behind an in game capture), taken from `Origin`; recorded for history, never used for authorization. See [authoring-writes.md](authoring-writes.md#principles).

**Input hold**: whatever currently holds the protagonist's input and so decides which raw key becomes an intent event. See [interactions.md](interactions.md#input-holds).

**`input(name, type, default)`**: asks the creator for a value a migration cannot decide alone. See [migrations.md](migrations.md#the-xmigrations-hook).

**Intent event**: an event such as `Confirm` made from raw input only when the key is the one offered. See [events-and-handlers.md](events-and-handlers.md#event).

**Interaction**: the running group of steps that one start produced, and an identity. See [interactions.md](interactions.md#interactions).

**`InteractionContext`**: core formula context evaluated once per interaction, providing `group` and `chain`. See [formula-language.md](formula-language.md#formula-contexts).

**`InteractionState`**: core stored value keyed by the interaction that keeps its rules while the protagonist is gone. See [interactions.md](interactions.md#stepstate).

**`interpolate()`**: provider that decides how a value enters a text template; `RichText` escapes tags by default. See [formula-language.md](formula-language.md#text-templates).

**Interpreter**: the formula interpreter in the `formula` module, shared by realm and engines, that parses, binds, runs, and records reads. See [formula-language.md](formula-language.md#interpreter).

**`Interval`**: core `Schedule` that fires a fixed duration after the given time. See [stored-data.md](stored-data.md#due).

**`Island`**: example identity type that the `islands` group entry exports through `bind`. See [interactions.md](interactions.md#groupings-and-membership).

## K

**Keyed hold**: a hold with `@Key` fields so one holder can hold many holds of one type, such as `NpcView`. See [interactions.md](interactions.md#keyed-holds).

**Keys**: the identities a stored value is about: none (global), one, several (ordered), or a `Set` (symmetric). See [stored-data.md](stored-data.md#keys).

**`KnownIds`**: stored value `KnownIds(engine, type, ids)` with the ids one engine reports for one reported id type; the shared picker and the reported id check read it. See [panel-engine-communication.md](panel-engine-communication.md) question 10.

## L

**Lane**: not a separate concept; the hold type is the lane, and two things clash only on the same hold type for the same holder. See [interactions.md](interactions.md#holds).

**Lifecycle events**: `Added<T>`, `Changed<T>(old, new)`, and `Removed<T>`, fired for every stored value, hold, and mirror. See [stored-data.md](stored-data.md#lifecycle-events).

**`Live`**: an immutable mirror of engine state, keyed by identities, never saved, maintained only while demanded. See [live-data.md](live-data.md#live-mirrors).

**Live anchor**: the one live trait parameter that pins a handler to an engine; a second one is read through its mirror. See [events-and-handlers.md](events-and-handlers.md#where-a-handler-runs).

**Live capability trait**: an engine provided interface (`HasChat`, `HasInventory`, `Player`) giving live access and effects; the engine's implementation places each one on a worker or the owner thread. See [live-data.md](live-data.md#live-capability-traits).

**Live members**: members of a group interaction, derived from `Membership`, so joins and leaves take effect at once. See [interactions.md](interactions.md#live-members).

**Lookup order**: names resolve innermost first: lambdas, context, element, page, book, imports, capability roots. See [formula-language.md](formula-language.md#lookup-order).

## M

**`ManualGroupEntry`**: grouping changed only through the `JoinGroup` and `LeaveGroup` actions, so creators build parties with data. See [interactions.md](interactions.md#groupings-and-membership).

**`MemberContext`**: core formula context evaluated per member, adding `protagonist` to `InteractionContext`. See [formula-language.md](formula-language.md#formula-contexts).

**Membership**: core stored value (grouping, protagonist, key) that places a protagonist in a group. See [interactions.md](interactions.md#groupings-and-membership).

**Membership (interaction)**: every entry reachable from a start through trigger links, computed at publication. See [interactions.md](interactions.md#creation-and-membership).

**Migration**: the step that makes stored data or running interactions follow a content or type change. See [migrations.md](migrations.md#when-a-migration-is-needed).

**`MigrationResources`**: the realm's database schema patches, unrelated to content and data migrations. See [migrations.md](migrations.md).

**`MigrationScope`**: the formula scope migration inputs see; it contains `old`. See [migrations.md](migrations.md#pendingmigration).

**Milestones**: alpha is the first closed beta release (the PR stack), beta is added during the closed beta, after comes after the closed beta, someday has no plan. See [closed-beta-roadmap.md](closed-beta-roadmap.md).

**Mirror**: see `Live`. See [live-data.md](live-data.md#live-mirrors).

**Mirror reader**: the read only formula call KSP generates from a `Live` type, such as `health` or `inRegion(arena)`. See [live-data.md](live-data.md#reading-a-mirror-in-a-formula).

## N

**NATS JetStream**: store for short lived data (`sessions`, `demand`, and `mirrors` KV buckets); never holds stored data or `Due`. See [live-data.md](live-data.md#nats-jetstream).

**`NearestNpc`, `NearbyNpcs`**: example finder mirrors; the second shows an entry reference as a parameter key. See [live-data.md](live-data.md#finders-are-mirrors).

**`now`**: the time, fixed per evaluation; in a `Changes` field it is the realm commit time. See [formula-language.md](formula-language.md#time-and-randomness).

**`NpcActivity`**: example `Runtime` for a running NPC activity, created on `Added<NpcRunning>`. See [interactions.md](interactions.md#runtime-objects).

**`NpcRunning`**: the hold whose holder (server, group, protagonist) decides NPC scope. See [interactions.md](interactions.md#npc-scope).

**`NpcView`**: example keyed hold, one per NPC shown to a viewer. See [interactions.md](interactions.md#keyed-holds).

## O

**Objective**: an entry system of its own (display, tracking, progress) whose criteria are formulas. See [live-data.md](live-data.md#audiences).

**Occurrence**: one real happening that may reach several sources; sources of the same meaning join it. See [events-and-handlers.md](events-and-handlers.md#occurrences-and-dedupe).

**Offline changes**: stored data changing while its protagonist is offline; stored only handlers run on the realm, live reactions may be missed. See [stored-data.md](stored-data.md#offline-changes).

**`onClash`**: step entry field and `startStep` argument: `Drop` (default), `Queue`, or `Replace`. See [interactions.md](interactions.md#clashes).

**`Once`**: core `Schedule` for one fixed time; a time in the past means never. See [stored-data.md](stored-data.md#due).

**`OnlinePlayer`**: `Live` mirror in the Minecraft capability with an online protagonist's name and its `Engine`, read by the panel's target list. See [panel-engine-communication.md](panel-engine-communication.md) question 9.

**`onRejoin`**: step entry field and `startStep` argument: `Drop` (default), `RestartStep`, or `RestartInteraction`. See [interactions.md](interactions.md#leaving-and-rejoining).

**`OnWrite<K, T>`**: variable reaction that runs inside every write's own transaction. See [stored-data.md](stored-data.md#reactions).

**Origin**: who caused an occurrence (session and `PrincipalId`), filled by the source beside the event, never an event field; handlers ask for it as the `Origin` parameter. See [events-and-handlers.md](events-and-handlers.md).

**`Outcome`**: handler parameter with the final outcome; it lets an after handler also see denied events. See [events-and-handlers.md](events-and-handlers.md#follow-ups-and-cancel).

**Owed state**: the guideline to store what is owed, not what happened, so a live handler can act whenever the protagonist is online. See [stored-data.md](stored-data.md#offline-changes).

**Owner**: the key identities of a stored value; it is removed when any of them ends. See [stored-data.md](stored-data.md#owners-and-lifetime).

## P

**Panel engine**: the engine next to the realm that holds each panel tab's session and runs its handlers and derives; the tab is a thin client. See [engines.md](engines.md#engine-communication).

**`PaperPlayer`, `PaperProtagonist`**: the Paper engine's live object for a protagonist, implementing traits such as `Player` and `HasChat`. See [live-data.md](live-data.md#live-capability-traits).

**`PaperPlayerFormulas`**: example engine implementation of a capability's formula function interface, checked for completeness by KSP. See [formula-language.md](formula-language.md#members-and-providers).

**`PaperServer`**: the live trait of the `Engine` identity on Paper, as `PaperPlayer` is for a protagonist. See [panel-engine-communication.md](panel-engine-communication.md) question 10.

**`papi(...)`**: PlaceholderAPI provider function, backed by a `Tick` mirror polled only where used. Takes `engine: Engine` as a context parameter. See [formula-language.md](formula-language.md#standard-library).

**`PendingMigration`**: core resource storing a migration's creator inputs as `Var` values; unfinished inputs block publication. See [migrations.md](migrations.md#pendingmigration).

**Phase**: decision or after, chosen by a handler's return type. See [events-and-handlers.md](events-and-handlers.md#return-value-decides-the-phase).

**`Player`**: Minecraft capability trait; core code says protagonist, never player. See [events-and-handlers.md](events-and-handlers.md#event).

**`PlayerMove`**: example Paper event that really moves the player. See [events-and-handlers.md](events-and-handlers.md#event).

**Portable expression**: the v1 panel operation encoding, unrelated to formulas and never reused by them. See [formula-language.md](formula-language.md).

**Portable kernels**: the Kotlin and Dart implementations of `operations.yaml` that keep panel and realm expression results equal; formula stdlib providers may call the Kotlin ones as a library. See [formula-language.md](formula-language.md#standard-library).

**Preview**: adds a `Simulating(mode)` stored value to the previewed step; handlers run for real unless they check it. See [interactions.md](interactions.md#preview-and-recording).

**`PrincipalId`**: an authenticated party, `kind` plus `id` (user, service, minecraft), derived from the transport credential. See [authoring-writes.md](authoring-writes.md#skir-sketch).

**Priority (hold)**: the highest priority derive wins when several produce the same hold type, holder, and key; a tie is a check warning. See [interactions.md](interactions.md#priority).

**Priority (verdict)**: the inherited entry priority a verdict carries; changes apply low to high and the highest decides allow versus deny. See [events-and-handlers.md](events-and-handlers.md#verdicts).

**`produces { }`**: `dynamic()` builder declaring the chain context records an entry adds for downstream entries. See [formula-language.md](formula-language.md#dynamic-what-content-means-to-the-type-system).

**Protagonist**: the engine neutral person (a Minecraft player, also the panel user) that owns stored data; named `protagonist` in formulas. Portable form: `Protagonist(principal: PrincipalId)`, the account it comes from; nothing mints it. A linked panel tab (beta) reports as the player's protagonist. See [stored-data.md](stored-data.md#identity).

**Protagonist subject**: `typewriter.protagonist.<id>`, subscribed by every engine holding a session of that protagonist; events about the protagonist go there and each engine runs the handlers it can. See [live-data.md](live-data.md#routing).

**`ProtagonistJoined`**: core event fired when a protagonist with no session gets one. See [live-data.md](live-data.md#session).

**`ProtagonistLeft`**: best effort core event fired by the last holder when a protagonist has no session left anywhere. See [live-data.md](live-data.md#session).

**`Protected`**: stored value on a running step that turns an incoming `Replace` into `Queue`. See [interactions.md](interactions.md#clashes).

**Provider**: KSP generated per type code (`XFormulaProvider`) that supplies formula members and operators. See [formula-language.md](formula-language.md#members-and-providers).

**Publication transaction**: the one transaction that runs every pending migration and switches the content, all or nothing. See [migrations.md](migrations.md#the-publication-transaction).

**`PublishScope`**: formula context for fields the realm evaluates at publish (book instances); pure values only. See [formula-language.md](formula-language.md#formula-contexts).

## Q

**Query graph**: the realm's incremental computation with early cutoff and the one tracked read mechanism for realm checks and searches (`dynamic()`, formula checks); stored reads are inputs too; it replaces `ReverseDependencyIndex`. See [formula-language.md](formula-language.md#query-graph) and [closed-beta-roadmap.md](closed-beta-roadmap.md).

**Queue (clash)**: an incoming step waits until it can start, giving up through a formula, when its book stops applying, or when its interaction ends. See [interactions.md](interactions.md#clashes).

## R

**`random(...)`**: formula randomness seeded by (run, place), so rechecking agrees and a new run rolls again; the run is the chain's seed record, the write, or the event, depending on the context. See [formula-language.md](formula-language.md#time-and-randomness).

**Reaction**: behaviour attached to a variable that only changes data; kinds are `OnWrite`, `AfterWrite`, and `Every`. See [stored-data.md](stored-data.md#reactions).

**`ReactionTimer<K, T>`**: the one `Due` type of timed reactions; the variable declares one per `AfterWrite` (with the value's keys) and per `Every` (with no keys) at the reaction's place. See [stored-data.md](stored-data.md#how-timed-reactions-fire).

**`ReactionScope<K, T>`**: formula context interface for reaction changes, providing `keys`, `value`, and `previous`. See [formula-language.md](formula-language.md#formula-contexts).

**Realm**: the backend that owns stored data, `Due`, publication, checks, and routing of what it owns. See [live-data.md](live-data.md#routing).

**`RealmCheckProvider`**: the existing realm check interface through which core and extensions report findings. See [live-data.md](live-data.md#checks).

**`Ref<E, T>`**: an authored relation to resource `T` through endpoint `E` of a `@ReferenceContract`; runtime values name the entry type directly instead (`npc: NpcEntry`). See [stored-data.md](stored-data.md#identity).

**`Removed<T>`**: lifecycle event fired when a value is removed; for mirrors it cancels suspended handlers that resolved it. See [stored-data.md](stored-data.md#lifecycle-events).

**`require(condition, message)`**: change operation guard; when false at commit the whole transaction fails. See [stored-data.md](stored-data.md#change-operations).

**`restore(snapshot)`**: hold method run once at the end to put back what `snapshot()` captured. See [interactions.md](interactions.md#snapshot-and-restore).

**`RichText`**: text type whose `template` provider (MiniMessage) comes from the Minecraft capability. See [formula-language.md](formula-language.md#text-templates).

**Reported id**: an id type whose valid values only engines know (`World`, registry ids such as `BlockType`, extension ids such as `NexoItemId`); implements `ReportedId`, engines record their values in `KnownIds`, and one panel picker and one realm check serve every such type. See [panel-engine-communication.md](panel-engine-communication.md).

**Routing**: an event goes where a handler can run; realm owned data goes through the realm; events and live effects about a protagonist go to its protagonist subject, and session subjects serve only targets that are one connection. See [live-data.md](live-data.md#routing).

**`Runtime`**: a mutable local object on one server, never saved, with a creator lifetime; created by returning it from a handler. See [interactions.md](interactions.md#runtime-objects).

## S

**Scene**: a step whose holds take the camera and hide the protagonist by packets. See [interactions.md](interactions.md#scenes).

**`Schedule`**: open catalog type that answers when a repeating `Due` fires next; `next(after)` returns `null` for never again. See [stored-data.md](stored-data.md#due).

**`scope(target) { }`**: `dynamic()` builder saying what one own field's formulas, or my contents, can see. See [formula-language.md](formula-language.md#scope-and-exports).

**`scopeAt(field)`**: query graph step computing the scope a field's formulas see. See [formula-language.md](formula-language.md#query-graph).

**Server move**: a leave plus a rejoin; the session is kept and everything else follows its own rule. See [live-data.md](live-data.md#multiple-servers).

**`Session`**: identity for one connection of a protagonist, `Session(protagonist, id: SessionId)`. See [live-data.md](live-data.md#session).

**`SessionArrived`**: fired by the engine that takes a session, each time it takes one. See [live-data.md](live-data.md#session).

**Session subject**: `typewriter.session.<id>`, subscribed by the engine holding that session; used only for targets that are one connection, such as the tab that started a capture, and for event results. See [live-data.md](live-data.md#routing).

**`SessionReporter`**: engine kind interface reporting session `connected` and `disconnected`. See [live-data.md](live-data.md#session).

**`sessions` KV bucket**: NATS KV bucket with one key per session, refreshed with a TTL equal to the grace; an expired key ends the session. See [live-data.md](live-data.md#nats-jetstream).

**`Settable<T>`**: generated reader and write target for a `stored()` declaration, with keys filled from scope. See [stored-data.md](stored-data.md#reading).

**`SidebarHold`**: example display hold derived from `InAudience`, whose text updates through `Changed<Watched<RichText>>`. See [live-data.md](live-data.md#audiences).

**`Simulating(mode)`**: stored value marking a previewed step. See [interactions.md](interactions.md#preview-and-recording).

**`Snapshot` (group)**: the `group` type after `ContinueForEveryone`, a fixed snapshot group. See [interactions.md](interactions.md#widening).

**`Snapshot<H>`**: handler parameter that reads and writes a hold's stored snapshot. See [interactions.md](interactions.md#snapshot-and-restore).

**`snapshot()`**: hold method run once on first start, returning a stored snapshot of what to restore. See [interactions.md](interactions.md#snapshot-and-restore).

**`Sink`**: what a source hands an event to; it decides the verdict and applies the outcome. See [events-and-handlers.md](events-and-handlers.md#writing-a-source).

**Source**: turns something outside Typewriter into events, lazily, only for what some handler can run for. See [events-and-handlers.md](events-and-handlers.md#source).

**`Speaking`**: example step marker storing the dialogue entry and `startedAt`. See [stored-data.md](stored-data.md#kotlin-form).

**Standard library**: ordinary Kotlin formula providers (`Int.plus`, `sumOf`, units, `format`). See [formula-language.md](formula-language.md#standard-library).

**`startStep(...)`**: starts a step with its marker values and its `onClash` and `onRejoin` rules. See [interactions.md](interactions.md#stepstate).

**Static entry**: an entry that declares data and is never triggered (`Variable`, `Definition`, `GroupEntry`). See [stored-data.md](stored-data.md#variables).

**Step**: an entry that takes time inside an interaction, and an identity with a generation. See [interactions.md](interactions.md#steps).

**Step marker**: the stored value a step keeps, holding only moments such as `startedAt` and `skippedAt`. See [interactions.md](interactions.md#step-markers-store-moments).

**`StepState`**: core stored value `StepState(entry, context, onClash, onRejoin)` keyed by the step. See [interactions.md](interactions.md#stepstate).

**`Stored`**: saved data keyed by identities and removed when any key identity ends. See [stored-data.md](stored-data.md#stored-values).

**`stored(name, keys, value, default)`**: the one storage declaration both Kotlin `@Key` types and creator variables compile to. See [stored-data.md](stored-data.md#stored-values).

**Stored derive**: a `@Derive` with a `Stored` result that keeps a saved value in sync; an equal result writes nothing. See [stored-data.md](stored-data.md#derive-with-a-stored-result).

**Stored form**: what a `Var<T, C>` stores: `Value(value)` or `Formula(source, references)` (a template is stored as its string template expression), where each reference links a name in the text to its target resource. See [formula-language.md](formula-language.md#stored-form).

**Subject**: the identity an event is about, usually a protagonist; chain events have a group. See [events-and-handlers.md](events-and-handlers.md#event).

**Suspending handler**: an after handler that suspends; it is cancelled when any value it resolved is removed, never on `Changed`. See [events-and-handlers.md](events-and-handlers.md#suspending-handlers).

## T

**Template**: string template sugar where the expected type picks the `template` provider. See [formula-language.md](formula-language.md#text-templates).

**Threads**: there is no main thread; live access runs on the thread that owns the identity. See [events-and-handlers.md](events-and-handlers.md#threads).

**Tick pipeline**: how chains run: starts queue and merge during a tick, one worker runs them at tick end, world changes share one owner visit, and only `require` guards wait for the realm. See [events-and-handlers.md](events-and-handlers.md#tick-pipeline).

**`Tick<C : TickConfig>`**: configured capability event for timed work; it accepts only after handlers. See [events-and-handlers.md](events-and-handlers.md#configured-events).

**Trigger**: an ordinary handler on a world event that fires an entry's links. See [events-and-handlers.md](events-and-handlers.md#firing-and-triggered).

**`TriggerAudienceEntry`**: audience entry with `onEnter`, `onExit`, and `fireOnJoin`; exit fires only on `because == Value`. See [live-data.md](live-data.md#audiences).

**Transaction function**: a Kotlin function with a `Transaction` context, the only way Kotlin writes a stored value; it runs on the engine as the prediction and on the realm as the decision. See [stored-data.md](stored-data.md#transaction-functions).

**`Triggerable`**: core trait for entries with `triggers` and a `changes: Var<Changes, InteractionContext>` field. See [events-and-handlers.md](events-and-handlers.md#triggerable-and-complete).

**`Triggered<E>`**: event emitted per linked entry when a link fires, with the entry, the group subject, and the context. See [events-and-handlers.md](events-and-handlers.md#firing-and-triggered).

**`Type`**: the value type of a type field; `Var<Type, TypeScope>` holds a type picked or written as text. See [formula-language.md](formula-language.md#type-fields).

**Type checking**: local and bidirectional; the field pushes the expected type down and expressions infer up. See [formula-language.md](formula-language.md#type-checking).

**`TypeDefinition`**: describes a named type; its id is `declared` (Kotlin), `qualified` (builtins) or `content` (types declared by content), with a revision. Structural types have none. See [formula-language.md](formula-language.md#members-and-providers).

**`TypeScope`**: formula context for type fields; pure values only, types in scope. See [formula-language.md](formula-language.md#formula-contexts).

**`TypeSelection`**: keeps an unbound type parameter creator picked. See [formula-language.md](formula-language.md#bind).

## U

**Union**: catalog subtyping (an abstract record plus `parents`) narrowed with `is`, smart casts, and exhaustive `when`. See [formula-language.md](formula-language.md#unions-and-errors).

**Update field**: a `Var<Changes, C>` field holding change lines that the entry applies. See [formula-language.md](formula-language.md#changes-fields).

## V

**`ValueAdmission`**: the existing admission that flags stored values and instances that no longer fit their type. See [formula-language.md](formula-language.md#bind).

**`value_location`**: the representation and `DataValue` variant for a place in authored content, the portable form of `BoundPath<T>`; named so it never reads as the Minecraft `Location`. See [panel-engine-communication.md](panel-engine-communication.md#emit-without-extension-code-in-the-panel-engine-2026-11-01).

**`Var<T, C>`**: the one formula field kind; `T` decides what the text may be and `C` what it sees. See [formula-language.md](formula-language.md#vart-c-the-one-field-kind).

**`Variable<K, T>`**: creator declared stored data as a static entry with name, keys, type, default, and reactions. See [stored-data.md](stored-data.md#variables).

**Variants**: different behaviour (Java chat versus a Bedrock form) picked by the step at start through a different stored value. See [interactions.md](interactions.md#variants).

**`Verdict`**: a decision phase result: `allow`, `deny`, `change`, or `pass`. See [events-and-handlers.md](events-and-handlers.md#verdicts).

## W

**`WatchValues`**: how a tab reads a mirror or stored value: one watch on the panel engine, with values as `DataValue`. See [panel-engine-communication.md](panel-engine-communication.md) (question 15).

**`Watched<T>`**: the mirror of a watched formula, keyed by its field and subject; its `Changed` is a real change and is what formula starts use. See [live-data.md](live-data.md#formula-changes).

**`WatchFormula`**: realm subscription that streams diagnostics, type, completions, and hover per keystroke. See [formula-language.md](formula-language.md#watchformula).

**Widening**: explicitly firing a chain for a group instead of one protagonist, making one shared interaction. See [interactions.md](interactions.md#widening).

**Wire verdict**: a verdict on a packet event; it may read only network safe data, never live traits. See [events-and-handlers.md](events-and-handlers.md#threads).

## X

**`XDraft`**: KSP generated content view of raw data that `dynamic()` runs over, where each field is a value, missing, or invalid. See [formula-language.md](formula-language.md#bind).

**`XFormulaProvider`**: KSP generated provider of formula members for one type. See [formula-language.md](formula-language.md#members-and-providers).

**`XMigrations`**: KSP generated per content type hook `fun XMigrationScope.migrate()`, live on the realm, comparing `old` and `new`. See [migrations.md](migrations.md#the-xmigrations-hook).
