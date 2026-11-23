package com.typewritermc.events

import com.typewritermc.identity.Identity

/**
 * Turns something outside Typewriter (a Paper event, a timer) into events. The runtime opens a source on the first
 * handler that could run for its events and closes it after the last, so a source never produces what no handler uses.
 * The engine a source runs on supplies a helper for its own event system, so a source is mostly its conversion.
 */
interface Source<E : Event> : EnginePart {
    /** The event class it produces, which decides when the runtime opens it. */
    val event: kotlin.reflect.KClass<E>

    fun open(sink: Sink<E>): AutoCloseable
}

/**
 * Where a source hands each occurrence. [decide] runs the verdicts inline, on the caller's thread, merges them into
 * one outcome, and calls [apply] with it before returning, so the source can cancel or change what caused it. After
 * handlers and follow ups run later, once the outcome was applied.
 */
interface Sink<E : Event> {
    fun decide(
        event: E,
        origin: Origin?,
        apply: (Outcome<E>) -> Unit = {},
    )
}

/**
 * A source of subscribed events: it is opened with the subscriptions that currently have a runnable handler, and
 * indexes them its own way (a timing wheel, a map by region). The demand changes as content is published; the runtime
 * opens the source while the demand holds a subscription and closes it once the demand is empty.
 */
interface SubscribedSource<E : Event, S : Any> : EnginePart {
    /** The event class it produces. */
    val event: kotlin.reflect.KClass<E>

    /** The subscription class it is opened with. */
    val subscription: kotlin.reflect.KClass<S>

    fun open(
        demand: Demand<S>,
        sink: Sink<E>,
    ): AutoCloseable
}

/**
 * The subscriptions of a subscribed event that currently have a runnable handler, watched as they change: a Kotlin
 * object subscription while its handler can run, and each published entry of an entry subscription type.
 */
interface Demand<S : Any> {
    val current: Set<S>

    /**
     * Calls [changed] with the current set at once and with every new set after it, until the returned handle is
     * closed, so a source adds and removes its own indexes as content is published.
     */
    fun watch(changed: (Set<S>) -> Unit): AutoCloseable
}

/** An event of a subscribed source: [subscription] is the subscription it was emitted for. */
interface SubscribedEvent<S : Any> : Event {
    val subscription: S
}

/**
 * Gives handlers the live engine object of an identity, such as a Paper player for a protagonist. The runtime checks
 * the object against the trait a handler asks for; null or the wrong type means the handler does not apply.
 */
interface LiveResolver<I : Identity> : EnginePart {
    val identity: kotlin.reflect.KClass<I>

    fun live(identity: I): Any?

    /**
     * Every identity of this kind that has a live object on this engine now. An event without a subject runs a handler
     * asking for this identity once per value, so a tick handler reaches each online player.
     */
    fun present(): Collection<I>
}

/** A live object that can show a chat line to its protagonist. */
interface HasChat {
    fun send(message: String)
}

/**
 * What the runtime needs to know of one event type without reflection: its subject and its identity fields. KSP
 * generates one per event; an event names one field per identity kind, so a handler's identity parameter has one
 * field to come from.
 */
interface EventShape<E : Event> : EnginePart {
    val event: kotlin.reflect.KClass<E>

    /** The identity the event is about: its only identity field, or null for an event without a subject. */
    fun subject(event: E): Identity?

    /** Every identity field of the event, one per identity kind. */
    fun identities(event: E): List<Identity>
}
