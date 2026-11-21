package com.typewritermc.engine.events

import com.typewritermc.events.AfterHandler
import com.typewritermc.events.Candidate
import com.typewritermc.events.ChainQueueing
import com.typewritermc.events.Chains
import com.typewritermc.events.ConfiguredEvent
import com.typewritermc.events.Context
import com.typewritermc.events.Event
import com.typewritermc.events.EventShape
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.LiveResolver
import com.typewritermc.events.Origin
import com.typewritermc.events.Outcome
import com.typewritermc.events.Param
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
    val live: List<LiveResolver<*>>,
)

/**
 * Runs handlers for every occurrence. A source's occurrence is decided inline: each verdict handler runs once per
 * combination of its resolved parameters, the verdicts merge into one outcome, and the source applies it before
 * [Sink.decide] returns. Follow ups and after handlers queue as one chain of the subject. Events emitted from a chain
 * queue as chains of their own; a chain start equal to a waiting one merges into it.
 *
 * [publish] swaps the content handlers see and opens each source while a handler could run for its events, closing
 * it once none can.
 */
class EventRuntime(
    private val parts: EventParts,
    private val queue: ChainQueue,
) : ChainQueueing,
    AutoCloseable {
    @Volatile
    private var published: PublishedEntries = PublishedEntries.EMPTY
    private val opened = mutableMapOf<Source<*>, AutoCloseable>()
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
    }

    @Synchronized
    override fun close() {
        opened.values.forEach { it.close() }
        opened.clear()
    }

    /** Queues [event] as a chain: it is decided on the worker, then its follow ups and after handlers run there. */
    override fun emit(event: Event) {
        val subject = subjectOf(event)
        queue.enqueue(subject as? Protagonist, event::class.simpleName ?: "event", key = event.takeIf { it is Triggered<*> }) {
            val content = published
            val decision = decideOn(event, null, content)
            after(event, null, decision, content)
        }
    }

    private fun <E : Event> Source<E>.openWith(): AutoCloseable =
        open(
            object : Sink<E> {
                override fun decide(
                    event: E,
                    origin: Origin?,
                    apply: (Outcome<E>) -> Unit,
                ) {
                    val content = published
                    val decision = decideOn(event, origin, content)
                    apply(decision.outcome)
                    val subject = subjectOf(event) as? Protagonist
                    queue.enqueue(subject, event::class.simpleName ?: "event") { after(event, origin, decision, content) }
                }
            },
        )

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
                        try {
                            plan.run(event, run.values)
                        } catch (failure: Exception) {
                            log.log(Level.WARNING, "A verdict handler failed and counts as a pass.", failure)
                            pass()
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
    ) = withContext(Chains(this) + ChainContent(content)) {
        decision.followUps.forEach { it() }
        val event = decision.outcome.event
        afters
            .filter { it.accepts(event) && (decision.outcome is Outcome.Allowed || Param.Outcome in it.params) }
            .forEach { plan ->
                @Suppress("UNCHECKED_CAST")
                plan as AfterHandler<Event>
                runs(plan, event, origin, decision.outcome, content).forEach { run ->
                    try {
                        plan.run(event, run.values)
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (failure: Exception) {
                        log.log(Level.WARNING, "An after handler on ${source::class.simpleName} failed.", failure)
                    }
                }
            }
    }

    private class Run(
        val values: List<Any?>,
        val priority: Int,
    )

    /** Every combination of resolved parameters: one run per candidate, none when a required one is missing. */
    private fun runs(
        plan: HandlerPlan<*>,
        event: Event,
        origin: Origin?,
        outcome: Outcome<*>?,
        content: PublishedEntries,
    ): List<Run> {
        val subject = subjectOf(event)
        val context = if (event is Triggered<*>) event.context else Context.EMPTY.with(event)
        val options =
            plan.params.map { param ->
                when (param) {
                    is Param.Candidate -> {
                        val about = if (param.ofEvent) event::class else null
                        val found =
                            content
                                .entries(param.entry, about)
                                .filter { it.appliesTo(subject) }
                                .map { Candidate(it.entry, it.priority, subject, context, content.reader) }
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
            is Param.Identity -> subject?.takeIf { param.type.isInstance(it) } ?: identitiesOf(event).firstOrNull { param.type.isInstance(it) }
            is Param.Trait -> subject?.let { liveOf(it) }?.takeIf { param.type.isInstance(it) }
            is Param.Field -> {
                val triggered = event as? Triggered<*> ?: return null
                val receiver = Candidate(triggered.entry, EXTENSION_PRIORITY, subject, context, content.reader)
                receiver.read(param.read(triggered.entry))
            }
            is Param.Origin -> origin
            is Param.Outcome -> outcome
            is Param.Config -> (event as? ConfiguredEvent<*>)?.config?.takeIf { param.type.isInstance(it) }
            is Param.Candidate -> error("Candidates resolve as runs.")
        }

    private fun HandlerPlan<*>.accepts(event: Event): Boolean {
        if (!this.event.isInstance(event)) return false
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
