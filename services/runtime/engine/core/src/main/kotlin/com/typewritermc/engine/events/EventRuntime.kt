package com.typewritermc.engine.events

import com.typewritermc.events.AfterHandler
import com.typewritermc.events.Candidate
import com.typewritermc.events.ChainQueueing
import com.typewritermc.events.Chains
import com.typewritermc.events.ConfiguredEvent
import com.typewritermc.events.ConfiguredSource
import com.typewritermc.events.Context
import com.typewritermc.events.Demand
import com.typewritermc.events.Event
import com.typewritermc.events.EventShape
import com.typewritermc.events.HandlerConfig
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.LiveResolver
import com.typewritermc.events.Origin
import com.typewritermc.events.Outcome
import com.typewritermc.events.Param
import com.typewritermc.events.ProtagonistLeft
import com.typewritermc.events.Sink
import com.typewritermc.events.Source
import com.typewritermc.events.Triggered
import com.typewritermc.events.VerdictHandler
import com.typewritermc.events.pass
import com.typewritermc.identity.Identity
import com.typewritermc.identity.Protagonist
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.withContext
import java.util.logging.Level
import java.util.logging.Logger
import kotlin.reflect.KClass

/** The engine parts the event runtime is built from, as the engine's Koin finds them. */
class EventParts(
    val handlers: List<HandlerPlan<*>>,
    val shapes: List<EventShape<*>>,
    val sources: List<Source<*>>,
    val configured: List<ConfiguredSource<*, *>>,
    val live: List<LiveResolver<*>>,
)

/**
 * Runs handlers for every occurrence. A source's occurrence is decided inline: each verdict handler runs once per
 * combination of its resolved parameters, the verdicts merge into one outcome, and the source applies it before
 * [Sink.decide] returns. Follow ups and after handlers queue as one chain of the subject. Events emitted from a chain
 * queue as chains of their own; a chain start equal to a waiting one merges into it. Every queued chain is reported to
 * the engine kind's [ChainPickup], which drains the queue.
 *
 * An occurrence about a protagonist this engine does not hold (see [holding]) runs no handler and is dropped, until
 * cross engine delivery forwards it; occurrences about another subject, or none, always run here. The session keeper's
 * own events skip that check through [asHolder].
 *
 * [publish] swaps the content handlers see and opens each source while a handler could run for its events, closing
 * it once none can. A configured source is opened with its demand instead: every configuration a runnable handler on
 * its event uses, recomputed on each publish, and closed once that demand is empty.
 *
 * An event without a subject, such as a tick, turns a handler's required identity parameter into a query: the handler
 * runs once per identity live on this engine, each as the run's subject.
 */
class EventRuntime(
    private val parts: EventParts,
    private val queue: ChainQueue,
    private val costs: HandlerCosts,
    private val pickup: ChainPickup,
    private val holding: SubjectHolding,
) : ChainQueueing,
    AutoCloseable {
    @Volatile
    private var published: PublishedEntries = PublishedEntries.EMPTY
    private val opened = mutableMapOf<Source<*>, AutoCloseable>()
    private val openedConfigured = mutableMapOf<ConfiguredSource<*, *>, OpenedConfigured>()
    private val shapes = parts.shapes.associateBy { it.event }
    private val verdicts = parts.handlers.filterIsInstance<VerdictHandler<*>>()
    private val afters = parts.handlers.filterIsInstance<AfterHandler<*>>()

    /** Makes [content] the content every following occurrence sees, and opens or closes sources to match. */
    @Synchronized
    fun publish(content: PublishedEntries) {
        published = content
        parts.sources.forEach { source ->
            val wanted = parts.handlers.any { it.couldRun(source.event, content) }
            val handle = opened[source]
            if (wanted && handle == null) opened[source] = source.openWith()
            if (!wanted && handle != null) opened.remove(source)?.close()
        }
        parts.configured.forEach { source ->
            val demand = demandOf(source, content)
            val open = openedConfigured[source]
            when {
                demand.isEmpty() -> openedConfigured.remove(source)?.handle?.close()
                open == null -> openedConfigured[source] = source.openWith(demand)
                else -> open.demand.update(demand)
            }
        }
    }

    @Synchronized
    override fun close() {
        opened.values.forEach { it.close() }
        opened.clear()
        openedConfigured.values.forEach { it.handle.close() }
        openedConfigured.clear()
    }

    private class OpenedConfigured(
        val demand: PublishedDemand<Any>,
        val handle: AutoCloseable,
    )

    /**
     * The configurations of [source] a runnable handler uses under [content]: a handler's object configuration, or
     * every published entry of its entry configuration type, for each handler on the source's event whose configuration
     * type the source is opened with.
     */
    private fun demandOf(
        source: ConfiguredSource<*, *>,
        content: PublishedEntries,
    ): Set<Any> =
        parts.handlers
            .filter { plan ->
                val config = plan.config ?: return@filter false
                source.config.java.isAssignableFrom(config.type.java) && plan.couldRun(source.event, content)
            }.flatMapTo(linkedSetOf()) { plan ->
                when (val config = checkNotNull(plan.config)) {
                    is HandlerConfig.Object -> listOf(config.instance)
                    is HandlerConfig.Entries -> content.entries(config.type).map { it.entry }
                }
            }

    /** Opens this source with [configurations] as its demand; the runtime updates the demand on each publish. */
    private fun <E : Event, C : Any> ConfiguredSource<E, C>.openWith(configurations: Set<Any>): OpenedConfigured {
        val demand = PublishedDemand(configurations)
        @Suppress("UNCHECKED_CAST")
        return OpenedConfigured(demand, open(demand as Demand<C>, sink()))
    }

    /**
     * Queues [event] as a chain: it is decided on the worker, then its follow ups and after handlers run there. An event
     * about a protagonist this engine does not hold is dropped.
     */
    override fun emit(event: Event) = start(event, repeat = 0)

    /**
     * Queues events without the hold check, for an emitter that already decided this engine holds their subject: the
     * session keeper, whose [ProtagonistLeft] comes after the protagonist's last session ended.
     */
    val asHolder: ChainQueueing =
        object : ChainQueueing {
            override fun emit(event: Event) = enqueue(event, repeat = 0)
        }

    /** Whether an occurrence of [event] runs here: it is about no protagonist, or about one this engine holds. */
    private fun held(event: Event): Boolean {
        val subject = subjectOf(event)
        return subject !is Protagonist || holding.holds(subject)
    }

    /**
     * Queues [event] as [emit] does, dropping it when it is about a protagonist this engine does not hold; a chain start
     * merges into an equal waiting start, except that [repeat], the count of earlier equal starts in the same `fire`
     * call, keeps each repeat a run of its own.
     */
    private fun start(
        event: Event,
        repeat: Int,
    ) {
        if (held(event)) enqueue(event, repeat)
    }

    /** Queues [event] as [start] does, without the hold check. */
    private fun enqueue(
        event: Event,
        repeat: Int,
    ) {
        val subject = subjectOf(event)
        val key =
            when {
                event !is Triggered<*> -> null
                repeat == 0 -> event
                else -> event to repeat
            }
        queue.enqueue(workOf(subject), event::class.simpleName ?: "event", key = key) {
            val content = published
            val decision = decideOn(event, null, content)
            after(event, null, decision, content)
        }
        pickup.queued()
    }

    private fun <E : Event> Source<E>.openWith(): AutoCloseable = open(sink())

    private fun <E : Event> sink(): Sink<E> =
        object : Sink<E> {
            override fun decide(
                event: E,
                origin: Origin?,
                apply: (Outcome<E>) -> Unit,
            ) {
                if (!held(event)) return
                val content = published
                val decision = decideOn(event, origin, content)
                apply(decision.outcome)
                queue.enqueue(workOf(subjectOf(event)), event::class.simpleName ?: "event") { after(event, origin, decision, content) }
                pickup.queued()
            }
        }

    private fun <E : Event> decideOn(
        event: E,
        origin: Origin?,
        content: PublishedEntries,
    ): Decision<E> {
        val ranked =
            verdicts.filter { it.accepts(event) }.flatMap { plan ->
                @Suppress("UNCHECKED_CAST")
                plan as VerdictHandler<Event>
                runs(plan, event, origin, null, content).map { run ->
                    val verdict =
                        measured(event) {
                            try {
                                plan.run(event, run.values)
                            } catch (
                                @Suppress("TooGenericExceptionCaught") failure: Exception,
                            ) {
                                log.log(Level.WARNING, "A verdict handler failed and counts as a pass.", failure)
                                pass()
                            }
                        }
                    Ranked(verdict, run.priority)
                }
            }
        return merge(event, ranked)
    }

    private suspend fun <E : Event> after(
        source: E,
        origin: Origin?,
        decision: Decision<E>,
        content: PublishedEntries,
    ) = withContext(Chains(this) + ChainContent(content, ::start)) {
        decision.followUps.forEach { it() }
        val event = decision.outcome.event
        afters
            .filter { it.accepts(event) && (decision.outcome is Outcome.Allowed || Param.Outcome in it.params) }
            .forEach { plan ->
                @Suppress("UNCHECKED_CAST")
                plan as AfterHandler<Event>
                runs(plan, event, origin, decision.outcome, content).forEach { run ->
                    measured(event) {
                        try {
                            plan.run(event, run.values)
                        } catch (cancelled: CancellationException) {
                            throw cancelled
                        } catch (
                            @Suppress("TooGenericExceptionCaught") failure: Exception,
                        ) {
                            log.log(Level.WARNING, "An after handler on ${source::class.simpleName} failed.", failure)
                        }
                    }
                }
            }
    }

    /** Runs [block] and records its time as one handler run on [event]. */
    private inline fun <T> measured(
        event: Event,
        block: () -> T,
    ): T {
        val started = System.nanoTime()
        try {
            return block()
        } finally {
            costs.record(event::class, System.nanoTime() - started)
        }
    }

    private class Run(
        val values: List<Any?>,
        val priority: Int,
    )

    /**
     * Every run of [plan] for [event]: one per subject (the event's own, or each queried identity for an event without
     * one), and per subject one per combination of resolved parameters.
     */
    private fun runs(
        plan: HandlerPlan<*>,
        event: Event,
        origin: Origin?,
        outcome: Outcome<*>?,
        content: PublishedEntries,
    ): List<Run> {
        val subjects = subjectOf(event)?.let(::listOf) ?: queried(plan, event) ?: listOf(null)
        return subjects.flatMap { runs(plan, event, it, origin, outcome, content) }
    }

    /**
     * The identities a handler on an event without a subject runs for: the live identities of its first required
     * identity parameter that no event field fills; null when it asks for none.
     */
    private fun queried(
        plan: HandlerPlan<*>,
        event: Event,
    ): List<Identity>? {
        val fields = identitiesOf(event)
        val param =
            plan.params.filterIsInstance<Param.Identity>().firstOrNull { param ->
                !param.optional && fields.none { param.type.isInstance(it) }
            } ?: return null
        return parts.live.flatMap { it.present() }.filter { param.type.isInstance(it) }
    }

    /** The published entries [param] offers for [subject]: of the event's class or configuration when it asks for one. */
    private fun candidates(
        param: Param.Candidate,
        event: Event,
        subject: Identity?,
        context: Context,
        content: PublishedEntries,
    ): List<Candidate<*>> {
        val about = if (param.ofEvent) event::class else null
        val config = if (param.ofConfig) (event as? ConfiguredEvent<*>)?.config else null
        return content
            .entries(param.entry, about)
            .filter { (!param.ofConfig || it.entry == config) && it.appliesTo(subject) }
            .map { Candidate(it.entry, it.priority, subject, context, content.reader) }
    }

    /** Every combination of resolved parameters for [subject]: one run per candidate, none when a required one is missing. */
    private fun runs(
        plan: HandlerPlan<*>,
        event: Event,
        subject: Identity?,
        origin: Origin?,
        outcome: Outcome<*>?,
        content: PublishedEntries,
    ): List<Run> {
        val context = if (event is Triggered<*>) event.context else Context.EMPTY.with(event)
        val options =
            plan.params.map { param ->
                when (param) {
                    is Param.Candidate -> {
                        val found = candidates(param, event, subject, context, content)
                        if (found.isEmpty() && param.optional) listOf(null) else found
                    }

                    else -> {
                        val value = resolve(param, event, subject, origin, outcome, context, content)
                        if (value == null && !param.optional) emptyList() else listOf(value)
                    }
                }
            }
        val combinations = options.fold(listOf(emptyList<Any?>())) { acc, values -> acc.flatMap { prefix -> values.map { prefix + it } } }
        return combinations.map { values ->
            Run(values, values.filterIsInstance<Candidate<*>>().maxOfOrNull { it.priority } ?: EXTENSION_PRIORITY)
        }
    }

    private fun resolve(
        param: Param,
        event: Event,
        subject: Identity?,
        origin: Origin?,
        outcome: Outcome<*>?,
        context: Context,
        content: PublishedEntries,
    ): Any? =
        when (param) {
            is Param.Identity -> {
                subject?.takeIf { param.type.isInstance(it) }
                    ?: identitiesOf(event).firstOrNull { param.type.isInstance(it) }
            }

            is Param.Trait -> {
                subject?.let { liveOf(it) }?.takeIf { param.type.isInstance(it) }
            }

            is Param.Field -> {
                val triggered = event as? Triggered<*> ?: return null
                content.reader.read(param.field, Candidate(triggered.entry, EXTENSION_PRIORITY, subject, context, content.reader))
            }

            is Param.Origin -> {
                origin
            }

            is Param.Outcome -> {
                outcome
            }

            is Param.Config -> {
                (event as? ConfiguredEvent<*>)?.config?.takeIf { param.type.isInstance(it) }
            }

            is Param.Candidate -> {
                error("Candidates resolve as runs.")
            }
        }

    private fun HandlerPlan<*>.accepts(event: Event): Boolean {
        if (!this.event.isInstance(event)) return false
        val config = config
        if (config != null && !config.type.isInstance((event as? ConfiguredEvent<*>)?.config)) return false
        val entry = entry ?: return true
        return event is Triggered<*> && entry.isInstance(event.entry)
    }

    /** Whether this handler could run for an occurrence of [event] given [content]: every required candidate exists. */
    private fun HandlerPlan<*>.couldRun(
        event: KClass<out Event>,
        content: PublishedEntries,
    ): Boolean {
        if (!this.event.java.isAssignableFrom(event.java)) return false
        return params.filterIsInstance<Param.Candidate>().filterNot { it.optional }.all { param ->
            content.entries(param.entry, if (param.ofEvent) event else null).isNotEmpty()
        }
    }

    /**
     * Whose work a chain of an occurrence with [subject] is: its protagonist; for an occurrence without a subject, every
     * protagonist live on this engine, since its handlers query them; nobody for any other subject.
     */
    private fun workOf(subject: Identity?): Set<Protagonist> =
        when (subject) {
            is Protagonist -> setOf(subject)
            null -> parts.live.flatMap { it.present() }.filterIsInstanceTo(linkedSetOf())
            else -> emptySet()
        }

    @Suppress("UNCHECKED_CAST")
    private fun subjectOf(event: Event): Identity? =
        when (event) {
            is Triggered<*> -> event.subject
            else -> (shapes[event::class] as EventShape<Event>?)?.subject(event)
        }

    @Suppress("UNCHECKED_CAST")
    private fun identitiesOf(event: Event): List<Identity> = (shapes[event::class] as EventShape<Event>?)?.identities(event).orEmpty()

    @Suppress("UNCHECKED_CAST")
    private fun liveOf(identity: Identity): Any? =
        parts.live.firstOrNull { it.identity.isInstance(identity) }?.let { (it as LiveResolver<Identity>).live(identity) }

    private companion object {
        /** The priority of a handler's verdict when no entry gave it: below every page. */
        const val EXTENSION_PRIORITY = Int.MIN_VALUE

        val log: Logger = Logger.getLogger(EventRuntime::class.java.name)
    }
}
