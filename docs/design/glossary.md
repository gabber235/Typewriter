# Glossary

Every type, annotation, and term used in the design set, one line each, with the file that explains it. The primitives on one page are in [overview.md](overview.md).

## Symbols

**`@As` and `@From`**: typed roles; an event marks two fields of one kind with `@As(Role::class)` and a handler picks one with `@From(Role::class)`. See [events-and-handlers.md](events-and-handlers.md#resolution).

**`@Derive`**: marks a pure function over tracked inputs whose result type (`Stored`, `Hold`, or `Live`) decides what the system maintains. See [overview.md](overview.md#derive).

**`@Handler`**: marks a Kotlin function with an event receiver whose parameter types decide when and where it runs and whose return type decides its phase. See [events-and-handlers.md](events-and-handlers.md#handler).

**`@Key`**: marks the fields of a Kotlin `Stored`, `Live`, or `Hold` type that are its keys; KSP turns a stored type into a `stored(...)` call. See [stored-data.md](stored-data.md#kotlin-form).

**`@TypewriterType`**: the v1 type annotation; on a developer defined stored type it carries an id and a revision so the migrator can convert its data, and every event carries it, so an event crosses engines as its catalog value. See [migrations.md](migrations.md#developer-migrator) and [events-and-handlers.md](events-and-handlers.md#event).

**`ArgumentEntry<T>`**: the one generic content command argument, with `T` picked and optional `choices`; its value reaches formulas as `name.value`. See [commands.md](commands.md#end-to-end-in-content).

**`CommandArgument<T>`**: object that makes a type usable as a command argument, found by supertype. See [commands.md](commands.md#end-to-end-in-content).

**`CommandContribution`**: parent of the holds that add `nodes` to a holder's command tree. See [commands.md](commands.md).

**`CommandTree`**: the engine's shared command tree, where each node checks whether this player has it now. See [commands.md](commands.md).

**`HasCommands`**: live trait that sends a connection its command tree. See [commands.md](commands.md).

**`/tw fire`**: the command that fires an entry for a target, written target first (`/tw fire <player> <entry>`) so suggestions follow the target. See [commands.md](commands.md#end-to-end-in-content).

## A

**Action entry**: an instant entry whose handler on `Triggered<E>` does its work and fires its links without becoming a step. See [events-and-handlers.md](events-and-handlers.md#firing-and-triggered).

**`Added<T>`**: lifecycle event fired when a stored value, hold, or mirror appears for a set of keys. See [stored-data.md](stored-data.md#lifecycle-events).

**Adoption**: a hold of the same type and keys within the grace takes over the old hold and its snapshot, so neither `Removed` nor `Added` fires. See [interactions.md](interactions.md#grace-and-adoption).

**`advance`**: dialogue creator field (`Anyone`, `Everyone`, `Leader`) that says which group members may advance a party dialogue. See [interactions.md](interactions.md#party-dialogues-and-leaving).

**After phase**: the phase of handlers returning `Unit`, a `Live` type, or a `Runtime` type; they run after the outcome was applied and may suspend. See [events-and-handlers.md](events-and-handlers.md#return-value-decides-the-phase).

**`AfterWrite<K, T>`**: variable reaction that runs a duration after the first or last write (`from: Write`, `First` or `Last`). See [stored-data.md](stored-data.md#reactions).

**`All<T>`**: handler parameter that resolves to every value of type `T`. See [events-and-handlers.md](events-and-handlers.md#parameters).

**`Animating`**: dialogue `Live` value that exists only while a view animates, so the every tick draw has nothing to run otherwise. See [dialogue.md](dialogue.md#3-the-dialogue-package).

**`ArmSwing`**: example event with one meaning reached through several sources; the first source starts the occurrence and the others join it. See [events-and-handlers.md](events-and-handlers.md#event).

**`attempt()`**: runs a transaction function or `Changes` field. It waits only when the write is guarded and returns `Committed` or `Refused(message)`. `ensure()` always waits. See [stored-data.md](stored-data.md#transaction-functions).

**Audience**: an `AudienceEntry` tree whose criteria are formulas over mirrors and whose membership is the `InAudience` mirror. See [live-data.md](live-data.md#audiences).

**`AuthoringCommit`**: one record of the realm commit history: id, actor, session, and a `ValueChange` (before and after) per changed value; it stores attribution and drives undo. See [panel-engine-communication.md](panel-engine-communication.md) question 12.

## B

**`Because`**: field on every `Added` and `Removed` saying whether the value really changed (`Value`) or tracking started or stopped (`Tracking`). See [live-data.md](live-data.md#added-changed-removed-and-because).

**`bind`**: `dynamic()` builder that derives a generic type parameter from content, so a bound parameter needs no picker. See [formula-language.md](formula-language.md#bind).

**Book**: a `Resource` (not an entry) that carries variables, instances, and imports. See [formula-language.md](formula-language.md#book).

**`BookContext`**: formula context of a book's `condition`: `protagonist` and `engine`, with book variables through scope. See [book-composition.md](book-composition.md#1-the-books).

**`BookGone`**: `Live` value keyed by step that appears when a running step's book, or the book its interaction started in, stops applying; its handler stops that part at once. See [book-composition.md](book-composition.md#7-stopping).

**`BookInlet`**: authored relay where a link comes into a book; its `through` links name the entries inside; publish removes it and rewires the links. See [book-composition.md](book-composition.md#2-inlets-and-outlets).

**Book instance**: one entry in a book's `instances` map, or a `New` embed of the book; publishing makes a thin copy of the book's resources for it, identified by source plus instance path. See [formula-language.md](formula-language.md#copies-at-publish).

**Book narrowing**: the check inside `fire` that only follows links into books that apply to the subject. See [book-composition.md](book-composition.md#6-conditions).

**`BookOutlet`**: authored relay where a link leaves a book; entries inside link into it and an embed's `outlets` field links out of it; publish removes it. See [book-composition.md](book-composition.md#2-inlets-and-outlets).

**`BookVariable`**: a book variable's type and optional default. See [formula-language.md](formula-language.md#variables).

**`BookConfiguration`**: the existing configuration system whose key rules apply to a book's `variables`. See [formula-language.md](formula-language.md#variables).

**`BoundPath<T>`**: a place in authored content, such as where a capture or mode writes or which reaction a `Due` runs; its portable form is the `value_location` representation, so stored values can keep it, and it is an identity that ends when the place is gone. See [panel-engine-communication.md](panel-engine-communication.md#emit-without-extension-code-in-the-panel-engine-2026-11-01).

**Bridge**: the conversion of one Typewriter value type to and from an engine's own type (`toPlatform`, `fromPlatform`), registered per engine kind. See [engines.md](engines.md#bridges).

## C

**`CameraHold`**: the hold a scene uses for the camera; it snapshots location, flight, and velocity and restores them at the end. See [interactions.md](interactions.md#scenes).

**`CancelableEvent`**: interface of an event a verdict can deny, such as `BlockBreak`. See [events-and-handlers.md](events-and-handlers.md#event-entries).

**`CancelableEventEntry<E>`**: the shared entry for a cancelable event: `condition` and `cancel` formulas plus links. See [events-and-handlers.md](events-and-handlers.md#event-entries).

**`Candidate<E>`**: handler parameter that runs once per published entry of type `E` whose book applies to the subject. See [events-and-handlers.md](events-and-handlers.md#parameters).

**Capability**: an engine specific feature set (such as `Tick` or the Minecraft traits) kept out of the engine neutral core. See [live-data.md](live-data.md#engines-and-traits).

**`Capture`**: core event that runs a formula on a player and writes the result into a field; `captureButton` sends it from a presentation. See [capture.md](capture.md).

**`CaptureContext`**: core formula context of a `Capture` formula, providing `protagonist` and `engine`. See [capture.md](capture.md).

**Chain**: entries linked by triggers, where links fire explicitly and carry a growing context. See [events-and-handlers.md](events-and-handlers.md#chain).

**Change operations**: the native storage operations (`set`, `add`, `multiply`, `max`, `min`, `setIfAbsent`, `append`, `remove`, `addAll`, `removeAll`, `put`, `clear`, `require`) the realm applies itself. See [stored-data.md](stored-data.md#change-operations).

**`Changed<T>(old, new)`**: lifecycle event fired when the value at a set of keys changes; for stored values it runs after the commit. See [stored-data.md](stored-data.md#lifecycle-events).

**`Changes`**: the value type of an update field; an ordered list of change lines, a transaction written in formula text, that the entry commits with `attempt()`. See [stored-data.md](stored-data.md#changes-fields).

**`ChatHistory`**: `Runtime` holding a player's recent chat, including blocked messages, built on `HasChat`'s primitives. See [dialogue.md](dialogue.md#2-core-chat).

**`ChatHold`**: hold with no data that says this chat is held; it blocks other chat. See [dialogue.md](dialogue.md#2-core-chat).

**`ChatSent`**: event for a chat message going to a player, from the wire. See [dialogue.md](dialogue.md#2-core-chat).

**`check(formula)`**: the query graph step that type checks one formula. See [formula-language.md](formula-language.md#type-checking).

**Checks**: the one list of build time (KSP) and realm findings, where errors block publication and warnings and info never do. See [live-data.md](live-data.md#checks).

**`ChosenTarget`**: stored value `ChosenTarget(user, target)` naming the protagonist a panel user acts on, so the choice follows the user across devices. See [panel-engine-communication.md](panel-engine-communication.md) question 9.

**Clash**: what happens when an incoming step needs a hold type another interaction holds for the same protagonist. See [interactions.md](interactions.md#clashes).

**`ClientPosition`**: example wire event that is only a fake view, kept separate from `PlayerMove` because its effect differs. See [events-and-handlers.md](events-and-handlers.md#event).

**Command**: a hold (contributed by a derive), an event (it ran), and data (the node tree) at once. See [commands.md](commands.md).

**Command node**: a `literal`, `argument`, or `runs<Event>()` element of a command contribution; contributions merge into one tree per player. See [commands.md](commands.md).

**`complete(context)`**: the `Triggerable` shortcut that applies the entry's changes and then fires its triggers. See [events-and-handlers.md](events-and-handlers.md#triggerable-and-complete).

**`Confirm`**: intent event for advancing, naming the step whose key offer took the press. See [dialogue.md](dialogue.md#6-the-key).

**`Configuration<T>`**: root resource holding a `Partial<T>`, one named version of an extension's record. See [configurations.md](configurations.md).

**`Configured<T>`**: entry field that selects a `Configuration<T>` and overrides single values; its `value` is the full `T`, worked out at publish. See [configurations.md](configurations.md).

**`ConfigurationHolder`**: a resource in the owner chain that selects configurations: `Book`, `Page`, `RealmRoot`. The root's selection is the default. See [configurations.md](configurations.md).

**Configured event**: an event with a configuration type parameter (`Tick<Config : TickConfig>`) whose source only emits for configurations some handler can run for. See [events-and-handlers.md](events-and-handlers.md#configured-events).

**`ConfiguredSource<E, Config>`**: source interface whose `open(demand: Demand<Config>, sink: Sink<E>)` receives the configurations that currently have a runnable handler. See [events-and-handlers.md](events-and-handlers.md#configured-events).

**`ContentCommandRan`**: event a content command node runs; its handler fires the node's triggers with the arguments as context. See [commands.md](commands.md#end-to-end-in-content).

**`ContentDelivery`**: `Live` value keyed by `Engine` with the publication the engine applied or its delivery failure, so the panel shows "applied on N of M engines". See [panel-engine-communication.md](panel-engine-communication.md) question 10.

**Context (chain)**: a typed bag of produced records passed along a chain that only grows. See [events-and-handlers.md](events-and-handlers.md#context).

**Context (formula)**: the interface `C` in `Var<T, C>` whose properties are the values a field's formulas see. See [formula-language.md](formula-language.md#formula-contexts).

**`ContinueForEachMember`**: widening action that makes one copy of the chain per member, with only `protagonist` in formulas. See [interactions.md](interactions.md#widening).

**`ContinueForEveryone(who)`**: widening action that evaluates a protagonist list into a snapshot group keyed by the new interaction. See [interactions.md](interactions.md#widening).

**`ContinueForGroup(grouping)`**: widening action that fires once per distinct group of the members, with the grouping's type as `group`. See [interactions.md](interactions.md#widening).

**Conversion formula**: the creator formula that maps old stored values to a new variable type or keys; the default clears the values. See [migrations.md](migrations.md#the-conversion-formula).

**Creator type**: a `Definition` whose type is `Type`; exported types become type names and records get a constructor. See [formula-language.md](formula-language.md#definition).

**`CronSchedule`**: core `Schedule` from a cron expression and a time zone. See [stored-data.md](stored-data.md#due).

**`CommandEntry`**: the literal root of a content command, with an `available` formula, built from `LiteralEntry` and `ArgumentEntry<T>`. See [commands.md](commands.md#end-to-end-in-content).

## D

**Decision phase**: the phase of handlers returning a `Verdict`; pure, never suspending, taking part in allow, deny, change, or pass. See [events-and-handlers.md](events-and-handlers.md#return-value-decides-the-phase).

**Dedupe key**: (connection, kind, client sequence number) when a packet has one, otherwise per connection order; never timing guesses. See [events-and-handlers.md](events-and-handlers.md#occurrences-and-dedupe).

**`Definition<T>`**: static entry holding a shared named value of any type, visible by name in the book and through imports. See [formula-language.md](formula-language.md#definition).

**`DefinitionScope`**: formula context for a `Definition`'s value, providing the definition's surroundings. See [formula-language.md](formula-language.md#formula-contexts).

**Demand**: per identity and key interest from a reader that could actually run; mirrors and lazy sources only work where there is demand. It is necessity in the `TrackedGraph`: a key is demanded when a path leads from an observer to it. See [live-data.md](live-data.md#demand).

**`demand` and `mirrors` KV buckets**: per realm NATS KV buckets through which a reader on one engine demands a mirror and producers on other engines publish its values. See [live-data.md](live-data.md#demand-across-engines).

**`Demand<Config>`**: source input for configured events: the configurations that currently have a handler whose other parameters are satisfiable. See [events-and-handlers.md](events-and-handlers.md#demand).

**Derive**: a pure function over tracked inputs whose result type decides what it maintains. See [overview.md](overview.md#derive).

**Derived type**: a type built by `bind`, with id `content(at)` (the field the `bind` reads) and revision 1. See [formula-language.md](formula-language.md#bind).

**Developer migrator**: the step a developer writes to convert a stored type's data between two revisions. See [migrations.md](migrations.md#developer-migrator).

**`DialogueView`**: `Live` interface shared by the dialogue kinds, with `doneAt` and `render`; not core. See [dialogue.md](dialogue.md#3-the-dialogue-package).

**`Domain<T>`**: the formula type of a name such as `minecraft.item`; any name on it gives a `T`, such as `ItemType("diamond")`. See [domains.md](domains.md).

**`DomainValue`**: interface of a type whose valid values live elsewhere (`World`, `ItemType`, `MythicSkill`), so one picker and one check serve them all; `OpenDomainValue` makes an unknown value a warning. See [domains.md](domains.md).

**Dry run**: a read only evaluation of a migration against real stored values on every edit. See [migrations.md](migrations.md#checks-while-editing).

**`Due`**: durable time; a stored value with `at` and an optional `repeat`. When `at` passes, the realm removes the row or moves it to its next time and fires `Elapsed<D>`, whose handlers are stored only. See [stored-data.md](stored-data.md#due).

**`dynamic()`**: the hook on every resource and entry type that tells the type system what its content means through builders. See [formula-language.md](formula-language.md#dynamic-what-content-means-to-the-type-system).

## E

**`EditExpectation.exists`**: authoring guard that a value location exists or not; it replaces `resource_exists`, and list operations guard only the items they name with it. See [panel-engine-communication.md](panel-engine-communication.md) question 12.

**`EmbedBook<V, I, O>`**: entry that places a book inside another book; `instance` picks a new or listed instance, `inlets` and `outlets` come from the book's relays through `bind`. See [book-composition.md](book-composition.md#3-the-embed).

**`emit()`**: queues an event from a handler; it is decided after the current event finishes, without nesting. See [events-and-handlers.md](events-and-handlers.md#emitting).

**`Elapsed<D>`**: event fired on the realm when a `Due` of type `D` reaches `at`; carries the fired value as `due`. See [stored-data.md](stored-data.md#due).

**Engine**: runs published content through extensions (Paper, panel, future engines); engines share stored state only through the realm; live effects and events go directly between sessions. `Engine(id)` is also an identity, keyed by the stable topology engine id, so what an engine knows (`Stored`) and is doing (`Live`) are ordinary values keyed by it. See [live-data.md](live-data.md#engines-and-traits).

**Engine kind**: the engine artifact an engine runs (`EngineKind`, the topology `EngineTarget.engine_id`, such as `typewritermc:paper`); open to third party engines and stored once in the topology. Bridges register per kind, each kind supplies its session ids and grace, and interactions stay inside one kind. See [live-data.md](live-data.md#session).

**`EnginePart`**: marker for a class an extension adds to an engine; KSP finds it by supertype and it joins the deployment's Koin. See [events-and-handlers.md](events-and-handlers.md#engine-parts).

**Entry record**: a chain context record keyed by producing entry plus type, add only. See [events-and-handlers.md](events-and-handlers.md#context).

**Event**: a plain Kotlin type saying one thing happened, one type per meaning; every event is a `@TypewriterType`, so it crosses engines as its catalog value. See [events-and-handlers.md](events-and-handlers.md#event).

**`EventContext<E>`**: formula context of an event entry's fields, adding `event: E`. See [events-and-handlers.md](events-and-handlers.md#event-entries).

**`EventEntry<E>`**: the shared entry for an event that cannot be denied: a `condition` formula plus links. An extension writes only the event and its source. See [events-and-handlers.md](events-and-handlers.md#event-entries).

**Event result**: what an event emitted from a session reports back to that session: `Done`, `Denied(reason)`, `Failed(reason)`, or `NotHandled`. See [events-and-handlers.md](events-and-handlers.md#follow-ups-and-cancel).

**Event without a subject**: an event such as `Tick` whose handler parameters become a query, running once per match. See [events-and-handlers.md](events-and-handlers.md#events-without-a-subject).

**`Every<K, T>`**: variable reaction that runs for every stored key on a `Schedule`. See [stored-data.md](stored-data.md#reactions).

**`EverySource`**: core configured source that arms the `ReactionTimer` of every published `Every`, at startup and after each publish. See [stored-data.md](stored-data.md#how-timed-reactions-fire).

**`EveryTick`**: core `TickConfig` object for a handler that runs every tick. See [events-and-handlers.md](events-and-handlers.md#configured-events).

**`Exits`**: core `Live` per member and way out: which interactions it may end and whether leaving is allowed now. See [interactions.md](interactions.md#gesture-ways-out).

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

**`giveUp`**: step rule, a formula: when true, a queued step leaves the queue. See [interactions.md](interactions.md#the-queue).

**Global record**: a chain context record keyed by type only that describes the chain as a whole; newest wins, never removed. See [events-and-handlers.md](events-and-handlers.md#context).

**Grace (hold)**: the short delay (about 10 ticks) before a hold that stopped being returned is removed and restored. See [interactions.md](interactions.md#grace-and-adoption).

**Grace (session)**: how long a session survives without an engine reporting it, set per engine kind (about 10 seconds for Minecraft). See [live-data.md](live-data.md#session).

**`EntryGroup<K>`**: the group identity of our group entries, (entry, key), so deleting the entry ends its groups. See [interactions.md](interactions.md#groupings-and-membership).

**`GroupIdentity`**: catalog parent of what members belong to, with stored data and derived members: `EntryGroup` and `Snapshot`, and an extension's own. See [interactions.md](interactions.md#groupings-and-membership).

**Group subject**: the subject of chain events; protagonist kind handler parameters then iterate its members. See [events-and-handlers.md](events-and-handlers.md#resolution).

**`FormulaGroupEntry`**: grouping whose key is a formula, so outside facts decide who is in which group. See [interactions.md](interactions.md#groupings-and-membership).

**`FieldGroup`**: a presentation's statement of which group its field belongs in, so `remainingFields()` needs no knowledge of the type. See [configurations.md](configurations.md#general-parts).

**`GroupEntry<K>`**: a grouping; `K` is picked, a plain `K` means one group per player and a list such as `List<Team>` means several. See [interactions.md](interactions.md#groupings-and-membership).

**Grouping**: a way to bucket protagonists, declared by a `FormulaGroupEntry` or a `ManualGroupEntry`. See [interactions.md](interactions.md#groupings-and-membership).

## H

**`GuardedTransaction`**: a `Transaction` that also has `require`; declaring it in the signature tells codegen and the checker that the write can be refused. See [stored-data.md](stored-data.md#transaction-functions).

**Handler**: a Kotlin function with the event as receiver; parameters decide when and where it runs, the return type decides its phase. See [events-and-handlers.md](events-and-handlers.md#handler).

**`HasChat`, `HasInventory`, `HasHealth`**: example live capability traits an engine provides for its identities, each small and for one capability. See [live-data.md](live-data.md#live-capability-traits).

**`HasAttributes`**: Minecraft capability trait that sets and removes keyed, transient attribute modifiers. See [interactions.md](interactions.md#gesture-ways-out).

**`Held`**: core `Live` value per protagonist naming which interaction holds each Hold type, and which steps have settled. See [interactions.md](interactions.md#clashes).

**`HeldBy`**: who holds a Hold type: its interaction, priority, and whether it is protected. See [interactions.md](interactions.md#clashes).

**Hold**: a live, never saved change to how something looks or behaves on an engine, held while a derive returns it. See [interactions.md](interactions.md#holds).

**Holder**: an identity that can run a step or hold a Hold: `Protagonist`, `Session`, `GroupIdentity`, or `Engine`. A Hold has exactly one as a `@Key`. See [interactions.md](interactions.md#the-holder-is-a-key).

**`HoldType`**: the id of a Hold's type, the unit clashes compare. See [interactions.md](interactions.md#clashes).

**Hot publish**: publishing content while things run; content is a tracked input, so whatever read it reruns. See [live-data.md](live-data.md#hot-publish).

**`HotbarScrollHold`**: hold taken only by a step that uses the wheel; it blocks slot changes. See [dialogue.md](dialogue.md#5-the-wheel).

**`HotbarSlotChanged`**: raw event with `from` and `to` slots, from `PlayerItemHeldEvent`. See [dialogue.md](dialogue.md#5-the-wheel).

## I

**Identity**: catalog parent type for anything stored data can be about; the only types allowed as keys. See [stored-data.md](stored-data.md#identity).

**`Import`**: `Import(book, alias)` brings another book's exports into a book's contents scope. See [formula-language.md](formula-language.md#imports).

**Importer**: a separate one time tool that moves legacy 0.9 content and data into the new model. See [migrations.md](migrations.md#importer-for-09).

**`InAudience`**: `Live` mirror for a protagonist being inside an audience node, with `since`, the moment they entered. See [live-data.md](live-data.md#audiences).

**`InSteps`**, **`InStep`**: core `Live` per member listing their running steps, each with its interaction and whether that interaction is leavable. See [interactions.md](interactions.md#the-rule).

**Inlet**: see `BookInlet`.

**`initiated_by`**: the principal a trusted service names as behind a commit (the player behind an in game capture), taken from `Origin`; recorded for history, never used for authorization. See [authoring-writes.md](authoring-writes.md#principles).

**Input hold**: whatever currently holds the protagonist's input and so decides which raw key becomes an intent event. See [interactions.md](interactions.md#input-holds).

**`input(name, type, default)`**: asks the creator for a value a migration cannot decide alone. See [migrations.md](migrations.md#the-xmigrations-hook).

**`InstanceChoice<V>`**: the instance an embed uses: `New(values)` makes one, `Existing(keys)` picks listed ones, `All` takes every listed one. See [book-composition.md](book-composition.md#3-the-embed).

**Intent event**: an event such as `Confirm` made from raw input only when the key is the one offered. Input with one holder needs none. See [events-and-handlers.md](events-and-handlers.md#event).

**Interaction**: the running group of steps that one start produced, and an identity. See [interactions.md](interactions.md#interactions).

**`InteractionContext`**: core formula context evaluated once per interaction, providing `group` and `chain`. See [formula-language.md](formula-language.md#formula-contexts).

**`InteractionStart`**: stored value keyed by the interaction: the entry and context it began with, for restarting it. See [interactions.md](interactions.md#steps).

**`interpolate()`**: provider that decides how a value enters a text template; `RichText` escapes tags by default. See [formula-language.md](formula-language.md#text-templates).

**Interpreter**: the formula interpreter in the `formula` module, shared by realm and engines, that parses, binds, runs, and records reads. See [formula-language.md](formula-language.md#interpreter).

**`Interval`**: core `Schedule` that fires a fixed duration after the given time. See [stored-data.md](stored-data.md#due).

**`Island`**: example identity type that the `islands` group entry exports through `bind`. See [interactions.md](interactions.md#groupings-and-membership).

## J

**`JumpLock`**: hold that weakens jumping while Jump is the offered key, restored after a crash. See [dialogue.md](dialogue.md#6-the-key).

## K

**Keyed hold**: a hold with `@Key` fields beyond the holder, so one holder can hold many holds of one type, such as `NpcView`. See [interactions.md](interactions.md#keyed-holds).

**`KeyOffer`**: `Live` value in which a step asks for a key press. Offers do not clash; the newest takes presses. See [dialogue.md](dialogue.md#6-the-key).

**`KeyPressed`**: raw event for one of the confirmation keys. See [dialogue.md](dialogue.md#6-the-key).

**Keys**: the identities a stored value is about: none (global), one, several (ordered), or a `Set` (symmetric). See [stored-data.md](stored-data.md#keys).

**`KeysLeft`**: `Live` value saying which keys a camera or lock leaves usable. See [dialogue.md](dialogue.md#6-the-key).

**`KnownIds`**: stored value `KnownIds(engine, type, ids)` with the ids one engine reports for one domain; the shared picker and the domain check read it. See [domains.md](domains.md).

## L

**Lane**: not a separate concept; the hold type is the lane, and two things clash only on the same hold type and keys. See [interactions.md](interactions.md#holds).

**`leavable`**: step rule formula saying whether the player may leave; interaction wide, so one member it is false for blocks leaving for the whole group. See [interactions.md](interactions.md#the-rule).

**`LeaveAsked`**: core intent event that ends interactions and fires the way out's links. See [interactions.md](interactions.md#leaving).

**`LeaveEntry`**: action that ends the protagonist's leavable interactions, or fires `refused`; any trigger can fire it. See [interactions.md](interactions.md#action-way-out).

**`Leash`**, **`LeashCenter`**, **`LeashEntry`**: the walk away way out: a hold under an audience, its snapshot of where the player stood, and the entry with its radius. See [interactions.md](interactions.md#gesture-ways-out).

**Lifecycle events**: `Added<T>`, `Changed<T>(old, new)`, and `Removed<T>`, fired for every stored value, hold, and mirror. See [stored-data.md](stored-data.md#lifecycle-events).

**Link query**: a link field in formula mode, returning references at publish (`page.elements.filter { it is StepEntry }`). See [formula-language.md](formula-language.md#link-fields-as-queries).

**`Live`**: an immutable mirror of engine state, keyed by identities, never saved, maintained only while demanded. See [live-data.md](live-data.md#live-mirrors).

**Live anchor**: the one live trait parameter that pins a handler to an engine; a second one is read through its mirror. See [events-and-handlers.md](events-and-handlers.md#where-a-handler-runs).

**Live capability trait**: an engine provided interface (`HasChat`, `HasInventory`, `Player`) giving live access and effects; the engine's implementation places each one on a worker or the owner thread. See [live-data.md](live-data.md#live-capability-traits).

**Live members**: members of a group interaction, derived from `Membership`, so joins and leaves take effect at once. See [interactions.md](interactions.md#live-members).

**Lookup order**: names resolve innermost first: lambdas, context, element, page, book, imports, top level providers. See [formula-language.md](formula-language.md#lookup-order).

## M

**`ManualGroupEntry`**: grouping changed only through the `JoinGroup` and `LeaveGroup` actions, so creators build parties with data. See [interactions.md](interactions.md#groupings-and-membership).

**`MemberContext`**: core formula context evaluated per member, adding `protagonist` to `InteractionContext`. See [formula-language.md](formula-language.md#formula-contexts).

**`Partial<T>`**: a type with `T`'s fields, each nullable; every configuration layer is one. See [configurations.md](configurations.md).

**Membership**: core stored value (protagonist, group identity) that places a protagonist in a group. See [interactions.md](interactions.md#groupings-and-membership).

**Membership (interaction)**: every entry reachable from a start through trigger links, computed at publication. See [interactions.md](interactions.md#creation-and-membership).

**Migration**: the step that makes stored data or running interactions follow a content or type change. See [migrations.md](migrations.md#when-a-migration-is-needed).

**`MigrationResources`**: the realm's database schema patches, unrelated to content and data migrations. See [migrations.md](migrations.md).

**`MigrationScope`**: the formula scope migration inputs see; it contains `old`. See [migrations.md](migrations.md#pendingmigration).

**Milestones**: alpha is the first closed beta release (the PR stack), beta is added during the closed beta, after comes after the closed beta, someday has no plan. See [closed-beta-roadmap.md](closed-beta-roadmap.md).

**Mirror**: see `Live`. See [live-data.md](live-data.md#live-mirrors).

**`Mirror<K, V>`**: the generic `Live` type for a value type that says on its own what it means, such as `Mirror<Protagonist, Position>`. See [live-data.md](live-data.md#generic-mirrors).

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

**`OfferedKey`**: hold naming the one key and step a player's press goes to now; not counted in clashes. See [dialogue.md](dialogue.md#6-the-key).

**Offline changes**: stored data changing while its protagonist is offline; stored only handlers run on the realm, live reactions may be missed. See [stored-data.md](stored-data.md#offline-changes).

**`onClash`**: step rule: `Drop` (default), `Queue`, or `Replace`. See [interactions.md](interactions.md#clashes).

**`Once`**: core `Schedule` for one fixed time; a time in the past means never. See [stored-data.md](stored-data.md#due).

**`OnlinePlayer`**: `Live` mirror in the Minecraft capability with an online protagonist's name and its `Engine`, read by the panel's target list. See [panel-engine-communication.md](panel-engine-communication.md) question 9.

**`onRejoin`**: step rule: `Drop` (default), `RestartStep`, or `RestartInteraction`. See [interactions.md](interactions.md#leaving-and-rejoining).

**`OnWrite<K, T>`**: variable reaction that runs inside every write's own transaction. See [stored-data.md](stored-data.md#reactions).

**Origin**: who caused an occurrence (session and `PrincipalId`), filled by the source beside the event, never an event field; handlers ask for it as the `Origin` parameter. See [events-and-handlers.md](events-and-handlers.md).

**`Outcome`**: handler parameter with the final outcome; it lets an after handler also see denied events. See [events-and-handlers.md](events-and-handlers.md#follow-ups-and-cancel).

**Outlet**: see `BookOutlet`.

**Owed state**: the guideline to store what is owed, not what happened, so a live handler can act whenever the protagonist is online. See [stored-data.md](stored-data.md#offline-changes).

**Owner**: the key identities of a stored value; it is removed when any of them ends. See [stored-data.md](stored-data.md#owners-and-lifetime).

## P

**Panel engine**: the engine next to the realm that holds each panel tab's session and runs its handlers and derives; the tab is a thin client. See [engines.md](engines.md#engine-communication).

**`PaperWire`**: the Paper engine's helper that turns packets into sources and sends Typewriter's own packets, like `PaperEvents` for Paper events. See [packets.md](packets.md).

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

**`protected`**: step rule, a formula: while true, an incoming `Replace` queues instead. See [interactions.md](interactions.md#clashes).

**Provider**: KSP generated per type code (`XFormulaProvider`) that supplies formula members and operators. See [formula-language.md](formula-language.md#members-and-providers).

**Publication transaction**: the one transaction that runs every pending migration and switches the content, all or nothing. See [migrations.md](migrations.md#the-publication-transaction).

**`PublishScope`**: formula context for fields the realm evaluates at publish (book instances); pure values only. See [formula-language.md](formula-language.md#formula-contexts).

## Q

**Query graph**: the realm's incremental computation with early cutoff and the one tracked read mechanism for realm checks and searches (`dynamic()`, formula checks); stored reads are inputs too; it replaces `ReverseDependencyIndex`. See [formula-language.md](formula-language.md#query-graph) and [closed-beta-roadmap.md](closed-beta-roadmap.md).

**Queue (clash)**: an incoming step waits until it can start, giving up through a formula, when its book stops applying, or when its interaction ends. See [interactions.md](interactions.md#clashes).

**`Queued<E>`**: stored row of a step waiting for its holds. See [interactions.md](interactions.md#the-queue).

## R

**`random(...)`**: formula randomness seeded by (run, place), so rechecking agrees and a new run rolls again; the run is the chain's seed record, the write, or the event, depending on the context. See [formula-language.md](formula-language.md#time-and-randomness).

**`resource.relay`**: relation family of relays; an endpoint in it accepts any resource, and a link through a relay is valid when every link it becomes after rewiring is valid. See [book-composition.md](book-composition.md#2-inlets-and-outlets).

**Reaction**: behaviour attached to a variable that only changes data; kinds are `OnWrite`, `AfterWrite`, and `Every`. See [stored-data.md](stored-data.md#reactions).

**`ReactionTimer<K, T>`**: the one `Due` type of timed reactions; the variable declares one per `AfterWrite` (with the value's keys) and per `Every` (with no keys) at the reaction's place. See [stored-data.md](stored-data.md#how-timed-reactions-fire).

**`ReactionScope<K, T>`**: formula context interface for reaction changes, providing `keys`, `value`, and `previous`. See [formula-language.md](formula-language.md#formula-contexts).

**`Ready`**: `Live` value saying a queued step may begin or replace now. See [interactions.md](interactions.md#the-queue).

**Realm**: the backend that owns stored data, `Due`, publication, checks, and routing of what it owns. See [live-data.md](live-data.md#routing).

**`RealmCheckProvider`**: the existing realm check interface through which core and extensions report findings. See [live-data.md](live-data.md#checks).

**`Ref<Endpoint, T>`**: an authored relation to resource `T` through endpoint `E` of a `@ReferenceContract`; runtime values name the entry type directly instead (`npc: NpcEntry`). See [stored-data.md](stored-data.md#identity).

**`Removed<T>`**: lifecycle event fired when a value is removed; for mirrors it cancels suspended handlers that resolved it. See [stored-data.md](stored-data.md#lifecycle-events).

**`require(condition, message)`**: change operation guard; when false at commit the whole transaction fails. See [stored-data.md](stored-data.md#change-operations).

**`RestoreSnapshot<H>`**: core event that runs once when a hold really ended, after grace, to put back what its snapshot saved; also after a rejoin. See [interactions.md](interactions.md#snapshot-and-restore).

**`RichText`**: text type whose `template` provider (MiniMessage) comes from the Minecraft capability. See [formula-language.md](formula-language.md#text-templates).

**Routing**: an event goes where a handler can run; realm owned data goes through the realm; events and live effects about a protagonist go to its protagonist subject, and session subjects serve only targets that are one connection. See [live-data.md](live-data.md#routing).

**`Running<E>`**: stored row of a running step: its entry, subject, context, and `startedAt`. Handlers and derives take it as a parameter. See [interactions.md](interactions.md#steps).

**`RunningAudienceEntry`**: audience a protagonist is in while one of its `during` steps runs. See [interactions.md](interactions.md#lifetime-running-audiences).

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

**`SidebarHold`**: example display hold derived from `InAudience`, with its text as a tracked parameter and a handler on `Changed<SidebarHold>`. See [live-data.md](live-data.md#audiences).

**`Simulating(mode)`**: stored value marking a previewed step. See [interactions.md](interactions.md#preview-and-recording).

**`Snapshot` (group)**: the `group` type after `ContinueForEveryone`, a fixed snapshot group. See [interactions.md](interactions.md#widening).

**`Snapshot<H>`**: handler parameter that reads and writes a hold's stored snapshot. See [interactions.md](interactions.md#snapshot-and-restore).

**`Sink`**: what a source hands an event to; it decides the verdict and applies the outcome. See [events-and-handlers.md](events-and-handlers.md#writing-a-source).

**Source**: turns something outside Typewriter into events, lazily, only for what some handler can run for. See [events-and-handlers.md](events-and-handlers.md#source).

**Standard library**: ordinary Kotlin formula providers (`Int.plus`, `sumOf`, units, `format`). See [formula-language.md](formula-language.md#standard-library).

**Static entry**: an entry that declares data and is never triggered (`Variable`, `Definition`, `GroupEntry`). See [stored-data.md](stored-data.md#variables).

**Step**: an entry that takes time inside an interaction, started by firing into a `StepEntry`, and an identity with a new id at each start. See [interactions.md](interactions.md#steps).

**`StepEntry`**: entry that takes time; firing into it starts a step. See [interactions.md](interactions.md#steps).

**`StepRules`**: the step's rules: `onClash`, `onRejoin`, `protected`, `giveUp`. Collapsed in the inspector, and `giveUp` hidden when the entry cannot queue. See [interactions.md](interactions.md#steps).

**`Stored`**: saved data keyed by identities and removed when any key identity ends. See [stored-data.md](stored-data.md#stored-values).

**`stored(name, keys, value, default)`**: the one storage declaration both Kotlin `@Key` types and creator variables compile to. See [stored-data.md](stored-data.md#stored-values).

**Stored derive**: a `@Derive` with a `Stored` result that keeps a saved value in sync; an equal result writes nothing. See [stored-data.md](stored-data.md#derive-with-a-stored-result).

**Stored form**: what a `Var<T, C>` stores: `Value(value)` or `Formula(source, references)` (a template is stored as its string template expression), where each reference links a name in the text to its target resource. See [formula-language.md](formula-language.md#stored-form).

**Subject**: the identity an event is about, usually a protagonist; chain events have a group. See [events-and-handlers.md](events-and-handlers.md#event).

**Suspending handler**: an after handler that suspends; it is cancelled when any value it resolved is removed, never on `Changed`. See [events-and-handlers.md](events-and-handlers.md#suspending-handlers).

## T

**`TakeSnapshot<H>`**: core event that runs when a hold starts and has no stored snapshot; its one handler returns the snapshot. See [interactions.md](interactions.md#snapshot-and-restore).

**Template**: string template sugar where the expected type picks the `template` provider. See [formula-language.md](formula-language.md#text-templates).

**Thin copy**: a book copy that shares its decoded data with every other copy and owns only its key and the leaves rebound at load (formulas that read `book`, links). See [formula-language.md](formula-language.md#copies-at-publish).

**Threads**: there is no main thread; live access runs on the thread that owns the identity. See [events-and-handlers.md](events-and-handlers.md#threads).

**Tick pipeline**: how chains run: starts queue and merge during a tick, one worker runs them at tick end, world changes share one owner visit, and only `require` guards wait for the realm. See [events-and-handlers.md](events-and-handlers.md#tick-pipeline).

**`Tick<Config : TickConfig>`**: configured capability event for timed work; it accepts only after handlers. See [events-and-handlers.md](events-and-handlers.md#configured-events).

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

**Version layer**: a part of an extension or engine with `since`, loaded on that Minecraft release and newer, holding only what changed. See [engines.md](engines.md#version-layers).

**Variants**: different behaviour (Java chat versus a Bedrock form) picked by the step at start through a different stored value. See [interactions.md](interactions.md#variants).

**`Verdict`**: a decision phase result: `allow`, `deny`, `change`, or `pass`. See [events-and-handlers.md](events-and-handlers.md#verdicts).

## W

**`WatchValues`**: how a tab reads a mirror or stored value: one watch on the panel engine, with values as `DataValue`. See [panel-engine-communication.md](panel-engine-communication.md) (question 15).

**`Watched<T>`**: the mirror of a watched formula, keyed by its field and subject; its `Changed` is a real change and is what formula starts use. See [live-data.md](live-data.md#formula-changes).

**`WatchFormula`**: realm subscription that streams diagnostics, type, completions, and hover per keystroke. See [formula-language.md](formula-language.md#watchformula).

**Way out**, **`WayOut`**: an explicit way for the player to leave an interaction: a gesture (an audience child hold, such as the leash) or the `LeaveEntry` action. Replaces legacy interaction bounds. See [interactions.md](interactions.md#ways-out).

**Widening**: explicitly firing a chain for a group instead of one protagonist, making one shared interaction. See [interactions.md](interactions.md#widening).

**Wire verdict**: a verdict on a packet event; it may read only network safe data, never live traits. See [events-and-handlers.md](events-and-handlers.md#threads).

## X

**`XDraft`**: KSP generated content view of raw data that `dynamic()` runs over, where each field is a value, missing, or invalid. See [formula-language.md](formula-language.md#bind).

**`XFormulaProvider`**: KSP generated provider of formula members for one type. See [formula-language.md](formula-language.md#members-and-providers).

**`XMigrations`**: KSP generated per content type hook `fun XMigrationScope.migrate()`, live on the realm, comparing `old` and `new`. See [migrations.md](migrations.md#the-xmigrations-hook).
