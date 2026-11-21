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
 * A source of configured events: it is opened with the configurations that currently have a runnable handler, and
 * indexes them its own way (a timing wheel, a map by region). The demand changes as content is published.
 */
interface ConfiguredSource<E : Event, C : Any> : EnginePart {
    /** The event class it produces. */
    val event: kotlin.reflect.KClass<E>

    /** The configuration class it is opened with. */
    val config: kotlin.reflect.KClass<C>

    fun open(
        demand: Demand<C>,
        sink: Sink<E>,
    ): AutoCloseable
}

/** The configurations of a configured event that currently have a runnable handler, watched as they change. */
interface Demand<C : Any> {
    val current: Set<C>

    /** Calls [changed] with every new set of configurations until the returned handle is closed. */
    fun watch(changed: (Set<C>) -> Unit): AutoCloseable
}

/** An event of a configured source: [config] is the configuration it was emitted for. */
interface ConfiguredEvent<C : Any> : Event {
    val config: C
}

/**
 * Gives handlers the live engine object of an identity, such as a Paper player for a protagonist. The runtime checks
 * the object against the trait a handler asks for; null or the wrong type means the handler does not apply.
 */
interface LiveResolver<I : Identity> : EnginePart {
    val identity: kotlin.reflect.KClass<I>

    fun live(identity: I): Any?
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
