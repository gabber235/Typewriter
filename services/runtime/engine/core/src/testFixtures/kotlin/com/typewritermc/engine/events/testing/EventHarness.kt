package com.typewritermc.engine.events.testing

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.Entry
import com.typewritermc.engine.events.CancelableEventEntry
import com.typewritermc.engine.events.EventEntry
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.CancelableEvent
import com.typewritermc.formula.Var
import com.typewritermc.types.Ref
import com.typewritermc.engine.events.ChainQueue
import com.typewritermc.engine.events.EventParts
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.PublishedEntries
import com.typewritermc.engine.events.PublishedEntry
import com.typewritermc.engine.events.SubjectWork
import com.typewritermc.engine.events.WrittenValues
import com.typewritermc.events.AfterHandler
import com.typewritermc.events.EnginePart
import com.typewritermc.events.EnginePartDependencies
import com.typewritermc.events.EnginePartProvider
import com.typewritermc.events.Event
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.LiveResolver
import com.typewritermc.events.Origin
import com.typewritermc.events.Outcome
import com.typewritermc.events.Param
import com.typewritermc.events.Sink
import com.typewritermc.events.Source
import com.typewritermc.events.Verdict
import com.typewritermc.events.VerdictHandler
import com.typewritermc.identity.Protagonist
import com.typewritermc.types.ResourceId
import kotlin.reflect.KClass

/**
 * An event runtime over hand written [parts] and the test event shapes, with a [work] counter. Content is published
 * with [publish]; [tick] is one chain pickup.
 */
class EventHarness(
    vararg parts: EnginePart,
) {
    val work = CountingWork()
    private val queue = ChainQueue(work)
    private val runtime =
        EventRuntime(
            EventParts(
                handlers = parts.filterIsInstance<HandlerPlan<*>>(),
                shapes = testShapes,
                sources = parts.filterIsInstance<Source<*>>(),
                live = parts.filterIsInstance<LiveResolver<*>>(),
            ),
            queue,
        )

    init {
        runtime.publish(PublishedEntries.EMPTY)
    }

    fun publish(vararg entries: PublishedEntry<*>) = runtime.publish(PublishedEntries(entries.toList(), WrittenValues))

    /** One chain pickup: runs every waiting chain and the chains they queue. */
    suspend fun tick() = queue.runPending()

    /** Wipes [protagonist] as the test host does between requirements. */
    fun wipe(protagonist: Protagonist) = queue.clear(protagonist)
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

/** A verdict handler on [event] with [params]; for a `Triggered` handler, [entry] is the entry class it runs for. */
fun <E : Event> verdict(
    event: KClass<E>,
    vararg params: Param,
    entry: KClass<out Entry>? = null,
    run: (E, List<Any?>) -> Verdict,
): VerdictHandler<E> =
    object : VerdictHandler<E> {
        override val event = event
        override val entry = entry
        override val params = params.toList()

        override fun run(
            event: E,
            values: List<Any?>,
        ): Verdict = run(event, values)
    }

/** An after handler on [event] with [params]; for a `Triggered` handler, [entry] is the entry class it runs for. */
fun <E : Event> after(
    event: KClass<E>,
    vararg params: Param,
    entry: KClass<out Entry>? = null,
    run: suspend (E, List<Any?>) -> Unit,
): AfterHandler<E> =
    object : AfterHandler<E> {
        override val event = event
        override val entry = entry
        override val params = params.toList()

        override suspend fun run(
            event: E,
            values: List<Any?>,
        ) = run(event, values)
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
