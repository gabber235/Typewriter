package com.typewritermc.engine.events.testing

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.Entry
import com.typewritermc.engine.events.CancelableEventEntry
import com.typewritermc.engine.events.ChainPickup
import com.typewritermc.engine.events.ChainQueue
import com.typewritermc.engine.events.Elsewhere
import com.typewritermc.engine.events.EventEntry
import com.typewritermc.engine.events.EventParts
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.HandlerCosts
import com.typewritermc.engine.events.PublishedEntries
import com.typewritermc.engine.events.PublishedEntry
import com.typewritermc.engine.events.SubjectWork
import com.typewritermc.engine.events.complete
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.AfterHandler
import com.typewritermc.events.CancelableEvent
import com.typewritermc.events.Context
import com.typewritermc.events.Demand
import com.typewritermc.events.EnginePart
import com.typewritermc.events.EnginePartDependencies
import com.typewritermc.events.EnginePartProvider
import com.typewritermc.events.Event
import com.typewritermc.events.EventResult
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.HandlerSubscription
import com.typewritermc.events.HasChat
import com.typewritermc.events.LiveResolver
import com.typewritermc.events.Origin
import com.typewritermc.events.Outcome
import com.typewritermc.events.Param
import com.typewritermc.events.Sink
import com.typewritermc.events.Source
import com.typewritermc.events.SubscribedSource
import com.typewritermc.events.Triggered
import com.typewritermc.events.TriggeredEvent
import com.typewritermc.events.Verdict
import com.typewritermc.events.VerdictHandler
import com.typewritermc.events.emit
import com.typewritermc.formula.Var
import com.typewritermc.identity.Protagonist
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlin.reflect.KClass

/**
 * An event runtime over hand written [parts] and the test event shapes, with a [work] counter. Content is published
 * with [publish]; [tick] is one chain pickup.
 */
class EventHarness(
    vararg parts: EnginePart,
) {
    val work = CountingWork()

    /** The telemetry the runtime records handler times into, as the engine's host exports them. */
    val telemetry = TelemetryTestHarness.create()
    private val costs = HandlerCosts(telemetry.openTelemetry)
    private val queue = ChainQueue(work)
    private val runtime =
        EventRuntime(
            EventParts(
                handlers = parts.filterIsInstance<HandlerPlan<*>>(),
                shapes = testShapes,
                sources = parts.filterIsInstance<Source<*>>(),
                subscribed = parts.filterIsInstance<SubscribedSource<*, *>>(),
                live = parts.filterIsInstance<LiveResolver<*>>(),
            ),
            queue,
            costs,
            TickedPickup,
            // The harness engine holds every identity and is the only engine; holding and delivery are proven on wired engines.
            { true },
            lazy { Elsewhere { _, _, _ -> } },
        )

    init {
        runtime.publish(PublishedEntries.EMPTY)
    }

    fun publish(vararg entries: PublishedEntry<*>) = runtime.publish(written(*entries))

    /** Publishes [entries] as an engine publishes a compiled publication, with the reader it came with. */
    fun publish(entries: PublishedEntries) = runtime.publish(entries)

    /** One chain pickup: runs every waiting chain and the chains they queue. */
    suspend fun tick() = queue.runPending()

    /** Queues a run of [event] caused by [origin] and returns its result once a pickup ran it. */
    suspend fun run(
        event: Event,
        origin: Origin? = null,
    ): EventResult = runtime.run(event, origin)

    /** Runs [event] caused by [origin] through one pickup and returns its result. */
    suspend fun ran(
        event: Event,
        origin: Origin? = null,
    ): EventResult =
        coroutineScope {
            val result = async(start = CoroutineStart.UNDISPATCHED) { run(event, origin) }
            tick()
            result.await()
        }

    /** Wipes [protagonist] as the test host does between requirements. */
    fun wipe(protagonist: Protagonist) = queue.clear(protagonist)
}

/** The harness's pickup: queued chains wait for the test's [EventHarness.tick]. */
private object TickedPickup : ChainPickup {
    override fun queued() = Unit
}

/** [entry] as published on a page of [priority], about [about], in a book that applies where [appliesTo] holds. */
fun <E : Entry> published(
    entry: E,
    about: KClass<out Event>? = null,
    priority: Int = 0,
    appliesTo: (Protagonist) -> Boolean = { true },
): PublishedEntry<E> = PublishedEntry(ResourceId(entry.name), entry, priority, about, appliesTo)

/** A published chain step named [name] that links to the steps named in [next]. */
fun step(
    name: String,
    next: List<String> = emptyList(),
): PublishedEntry<StepEntry> = published(StepEntry(name, next))

/**
 * A verdict handler on [event] with [params]; a handler on a triggered step takes `TriggeredEvent` and asks for the step
 * with a first `Param.Triggered`, and for a subscribed event, [subscription] is the subscription type of its receiver.
 */
fun <E : Event> verdict(
    event: KClass<E>,
    vararg params: Param,
    subscription: HandlerSubscription? = null,
    run: (E, List<Any?>) -> Verdict,
): VerdictHandler<E> =
    object : VerdictHandler<E> {
        override val event = event
        override val params = params.toList()
        override val subscription = subscription

        override fun run(
            event: E,
            values: List<Any?>,
        ): Verdict = run(event, values)
    }

/**
 * An after handler on [event] with [params]; a handler on a triggered step takes `TriggeredEvent` and asks for the step
 * with a first `Param.Triggered`, and for a subscribed event, [subscription] is the subscription type of its receiver.
 */
fun <E : Event> after(
    event: KClass<E>,
    vararg params: Param,
    subscription: HandlerSubscription? = null,
    run: suspend (E, List<Any?>) -> Unit,
): AfterHandler<E> =
    object : AfterHandler<E> {
        override val event = event
        override val params = params.toList()
        override val subscription = subscription

        override suspend fun run(
            event: E,
            values: List<Any?>,
        ) = run(event, values)
    }

/** An after handler on [Poke] that fires [entry] for the poking protagonist [times] times, each start with no context. */
fun pokeTriggers(
    entry: Entry,
    times: Int = 1,
): AfterHandler<Poke> = after(Poke::class) { poke, _ -> repeat(times) { emit(TriggeredEvent(entry, poke.protagonist, Context.EMPTY)) } }

/**
 * An after handler on each triggered test step, as an action entry's handler runs: it keeps the step's message in
 * [sent], read through the step's accessor, and continues the chain.
 */
fun sendsStepMessages(sent: MutableList<String>): AfterHandler<TriggeredEvent<*>> =
    after(TriggeredEvent::class, Param.Triggered(StepEntry::class)) { _, values ->
        @Suppress("UNCHECKED_CAST")
        val step = values.single() as Triggered<StepEntry>
        sent += step.message
        step.complete()
    }

/** A source the test fires by hand; [fire] returns the applied outcome, or null while the runtime keeps it closed. */
class TestSource<E : Event>(
    override val event: KClass<E>,
) : Source<E> {
    private var sink: Sink<E>? = null
    var opens: Int = 0
        private set
    val open: Boolean get() = sink != null

    override fun open(sink: Sink<E>): AutoCloseable {
        opens++
        this.sink = sink
        return AutoCloseable { this.sink = null }
    }

    fun fire(
        event: E,
        origin: Origin? = null,
    ): Outcome<E>? {
        var applied: Outcome<E>? = null
        sink?.decide(event, origin) { applied = it }
        return applied
    }
}

/**
 * A subscribed source the test fires by hand: [demand] is the subscription set it was last told, or null while the
 * runtime keeps it closed; [fire] emits [make] of a subscription and returns the applied outcome, or null while closed.
 */
class TestSubscribedSource<E : Event, S : Any>(
    override val event: KClass<E>,
    override val subscription: KClass<S>,
    private val make: (S) -> E,
) : SubscribedSource<E, S> {
    private var sink: Sink<E>? = null
    var demand: Set<S>? = null
        private set
    var opens: Int = 0
        private set

    override fun open(
        demand: Demand<S>,
        sink: Sink<E>,
    ): AutoCloseable {
        opens++
        this.sink = sink
        val watching = demand.watch { this.demand = it }
        return AutoCloseable {
            watching.close()
            this.sink = null
            this.demand = null
        }
    }

    fun fire(subscription: S): Outcome<E>? {
        var applied: Outcome<E>? = null
        sink?.decide(make(subscription), null) { applied = it }
        return applied
    }
}

/** The beat source of the test events: it emits a [Beat] for any subscription. */
fun beats(): TestSubscribedSource<Beat<*>, Any> = TestSubscribedSource(Beat::class, Any::class) { Beat(it) }

/** The protagonists live on this test engine, each with a chat that keeps what it was sent. */
class LivePlayers(
    vararg protagonists: Protagonist,
) : LiveResolver<Protagonist> {
    override val identity = Protagonist::class
    private val chats = protagonists.associateWith { TestChat() }

    override fun live(identity: Protagonist): TestChat? = chats[identity]

    override fun present(): Collection<Protagonist> = chats.keys

    /** Every line [protagonist] was sent, in order. */
    fun seen(protagonist: Protagonist): List<String> = chats.getValue(protagonist).lines.toList()
}

/** A chat that keeps every line it was sent. */
class TestChat : HasChat {
    val lines: MutableList<String> = java.util.Collections.synchronizedList(mutableListOf())

    override fun send(message: String) {
        lines += message
    }
}

/** Counts chain work per protagonist and keeps every count it reached, in order. */
class CountingWork : SubjectWork {
    private val counts = mutableMapOf<Protagonist, MutableList<Int>>()

    override fun begin(
        protagonist: Protagonist,
        name: String,
    ): AutoCloseable {
        change(protagonist, +1)
        return AutoCloseable { change(protagonist, -1) }
    }

    @Synchronized
    private fun change(
        protagonist: Protagonist,
        by: Int,
    ) {
        val history = counts.getOrPut(protagonist) { mutableListOf() }
        history += (history.lastOrNull() ?: 0) + by
    }

    @Synchronized
    fun busy(protagonist: Protagonist): Int = counts[protagonist]?.lastOrNull() ?: 0

    @Synchronized
    fun history(protagonist: Protagonist): List<Int> = counts[protagonist].orEmpty().toList()
}

/**
 * [part] as the provider KSP generates for it, bound to [binds]; with [needs], building it first asks the engine for
 * that type, as a constructor parameter would.
 */
fun provided(
    part: EnginePart,
    binds: List<KClass<*>>,
    needs: KClass<*>? = null,
): EnginePartProvider =
    object : EnginePartProvider {
        override val type: KClass<out EnginePart> = part::class
        override val binds: List<KClass<*>> = binds

        override fun create(dependencies: EnginePartDependencies): EnginePart {
            needs?.let { dependencies.get(it) }
            return part
        }
    }

/** A published event entry about [E] named [name] whose condition is the written value [condition]. */
inline fun <reified E : Event> eventEntry(
    name: String,
    next: List<String> = emptyList(),
    condition: Boolean = true,
): PublishedEntry<EventEntry<E>> =
    published(
        EventEntry<E>(Ref(ResourceId("sequence")), name, GraphPlacement(), links(next), Var.Value(condition)),
        about = E::class,
    )

/** A published cancelable event entry about [E] named [name] with written [condition] and [cancel] values. */
inline fun <reified E : CancelableEvent> cancelableEntry(
    name: String,
    next: List<String> = emptyList(),
    condition: Boolean = true,
    cancel: Boolean = false,
): PublishedEntry<CancelableEventEntry<E>> =
    published(
        CancelableEventEntry<E>(Ref(ResourceId("sequence")), name, GraphPlacement(), links(next), Var.Value(condition), Var.Value(cancel)),
        about = E::class,
    )

/** Links to the entries named in [names]. */
fun links(names: List<String>): Set<Ref<SequenceTriggers.Entry, SequenceEntry>> = names.mapTo(linkedSetOf()) { Ref(ResourceId(it)) }
