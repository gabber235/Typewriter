package com.typewritermc.events

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.elements.Entry
import com.typewritermc.identity.Identity
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.coroutineContext
import kotlin.reflect.KClass

/**
 * Marks a function as a handler: the event, or the [Triggered] step for a triggered entry, is its receiver, its
 * parameters say when and where it runs, and its return type says its phase. A [Verdict] decides inline and never
 * suspends; `Unit` runs after the outcome was applied and may suspend. KSP generates a [HandlerPlan] for it. The body
 * reads entry values through the generated accessors: bare on a [Triggered] receiver, on the candidate otherwise.
 *
 * ```kotlin
 * @Handler
 * suspend fun Triggered<SimpleMessageActionEntry>.send(chat: HasChat) {
 *     chat.send(message)
 *     complete()
 * }
 * ```
 */
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.BINARY)
annotation class Handler

/**
 * One parameter of a handler, as data: the runtime resolves each kind, computes demand from them, and places the
 * handler by them. A nullable parameter is [optional]: when it cannot be resolved the handler still runs with null.
 * Later layers add kinds with their resolvers.
 */
sealed interface Param {
    val optional: Boolean

    /** The subject, or the event's only field of [type]. */
    data class Identity(
        val type: KClass<out com.typewritermc.identity.Identity>,
        override val optional: Boolean = false,
    ) : Param

    /** The live engine object of the subject, checked against [type] (a capability trait such as [HasChat]). */
    data class Trait(
        val type: KClass<*>,
        override val optional: Boolean = false,
    ) : Param

    /**
     * One run per published entry of [entry] that applies to the subject. With [ofEvent], the entry's type argument is
     * the event, so `Candidate<CancelableEventEntry<E>>` only finds entries about the occurring event. With [ofSubscription],
     * the entry is the subscribed event's subscription type, so `Candidate<IntervalEventEntry>` on
     * `Tick<IntervalEventEntry>` only finds the entry the occurrence was emitted for.
     */
    data class Candidate(
        val entry: KClass<out Entry>,
        val ofEvent: Boolean = false,
        val ofSubscription: Boolean = false,
        override val optional: Boolean = false,
    ) : Param

    /**
     * The receiver of a handler on `Triggered<X>`: the step a [TriggeredEvent] of an [entry] fired into, built with the
     * engine's entry reader. KSP puts it first, ahead of the declared parameters.
     */
    data class Triggered(
        val entry: KClass<out Entry>,
    ) : Param {
        override val optional: Boolean get() = false
    }

    /** Who caused the occurrence; an event without a cause skips the handler unless [optional]. */
    data class Origin(
        override val optional: Boolean = false,
    ) : Param

    /** The final outcome, so an after handler also sees denied events. */
    data object Outcome : Param {
        override val optional: Boolean = false
    }

    /** The subscription a subscribed event was opened for, such as a tick's interval. */
    data class Subscription(
        val type: KClass<*>,
        override val optional: Boolean = false,
    ) : Param
}

/**
 * The generated plan of one handler: which event it takes, its parameters as data, and how to call it. The plan is
 * the one source for resolution, demand, and placement; resolution itself is ordinary runtime code.
 */
sealed interface HandlerPlan<E : Event> : EnginePart {
    /** The event class it takes; for a generic handler, the bound every matching event implements. */
    val event: KClass<E>

    /** For a handler on `Triggered<X>`, the entry class X it runs for; null for any other handler. */
    val entry: KClass<out Entry>? get() = params.firstNotNullOfOrNull { (it as? Param.Triggered)?.entry }

    val params: List<Param>

    /**
     * The subscription type of a subscribed event receiver (`Tick<EveryTick>` names [HandlerSubscription.Object] of
     * `EveryTick`), or null for any other event. KSP writes it, so the runtime knows every (event, subscription type)
     * pair a handler uses without reflection; the handler only runs for occurrences of that subscription.
     */
    val subscription: HandlerSubscription? get() = null
}

/**
 * The subscription type a handler on a subscribed event uses, and how publication turns it into subscriptions: one
 * for a Kotlin object, one per published entry for an entry type.
 */
sealed interface HandlerSubscription {
    val type: KClass<*>

    /** A Kotlin object subscription: [instance] is its only subscription, present while its handler can run. */
    data class Object(
        val instance: Any,
    ) : HandlerSubscription {
        override val type: KClass<*> get() = instance::class
    }

    /** An entry subscription type: every published entry of [type] is one subscription. */
    data class Entries(
        override val type: KClass<out Entry>,
    ) : HandlerSubscription
}

/** A decision handler: pure, inline, never suspends. A handler that throws counts as [pass] and is logged. */
interface VerdictHandler<E : Event> : HandlerPlan<E> {
    fun run(
        event: E,
        values: List<Any?>,
    ): Verdict
}

/** An after handler: runs once the outcome was applied, may suspend. */
interface AfterHandler<E : Event> : HandlerPlan<E> {
    suspend fun run(
        event: E,
        values: List<Any?>,
    )
}

/**
 * A published entry a handler runs for, as the scope its generated accessors read through: `entry.cancel` reads a
 * formula as a plain value for [subject] and [context]. [priority] is the entry's inherited priority, which its verdict
 * carries.
 */
class Candidate<out E : Entry>(
    override val entry: E,
    val priority: Int,
    override val subject: Identity?,
    override val context: Context,
    @property:GeneratedSdkApi
    override val reader: EntryReader,
) : EntryScope<E> {
    override fun toString(): String = "Candidate(${entry.name}, $subject)"
}

/**
 * What a chain carries from entry to entry: the records produced along it, such as the event that started it. It only
 * grows; a record of the same type replaces the earlier one.
 */
class Context private constructor(
    private val records: Map<KClass<*>, Any>,
) {
    /** This context with [record] added. */
    fun with(record: Any): Context = Context(records + (record::class to record))

    /** The record of [type], or null. */
    @Suppress("UNCHECKED_CAST")
    fun <T : Any> get(type: KClass<T>): T? = records[type] as T?

    /** Every record, oldest type first. */
    val all: Collection<Any> get() = records.values

    override fun equals(other: Any?): Boolean = other is Context && other.records == records

    override fun hashCode(): Int = records.hashCode()

    override fun toString(): String = "Context(${records.values})"

    companion object {
        val EMPTY: Context = Context(emptyMap())
    }
}

/**
 * Where after handlers and follow ups queue their work: emitted events and chain starts. The engine puts it in the
 * coroutine context of every after run, so [emit] needs no parameter and a verdict, which runs inline, cannot reach it.
 */
interface ChainQueueing {
    /** Queues [event]; it is decided after the current one finishes. */
    fun emit(event: Event)
}

/** The coroutine context element carrying the [ChainQueueing] of the current run. */
class Chains(
    val queueing: ChainQueueing,
) : AbstractCoroutineContextElement(Key) {
    companion object Key : CoroutineContext.Key<Chains>
}

/** Queues [event] from an after handler or a follow up; decided after the current event finishes. */
suspend fun emit(event: Event) {
    val chains = checkNotNull(coroutineContext[Chains]) { "Events are emitted from after handlers and follow ups only." }
    chains.queueing.emit(event)
}
