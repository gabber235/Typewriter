package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.Perception
import kotlinx.coroutines.channels.Channel
import java.net.URL

/**
 * One attempt of one requirement while it holds its lease: the players' perception streams in arrival
 * order, kept whole as the attempt's timeline, and the session it talks to the pool through.
 */
internal class Attempt(
    private val session: PoolSession,
    val players: List<GamePlayer>,
    private val requirementCode: URL?,
) {
    /** One event of a leased player's stream. */
    sealed interface Event {
        val player: GamePlayer

        data class Perceived(
            override val player: GamePlayer,
            val perception: Perception,
        ) : Event

        data class Barrier(
            override val player: GamePlayer,
            val id: Int,
        ) : Event
    }

    private val incoming = Channel<Event>(Channel.UNLIMITED)
    private val received = mutableListOf<Event>()

    /** Every event the body has taken so far, in arrival order. */
    val timeline: List<Event> get() = received

    /** Hands an event of one of [players] to the attempt; called by the session's reader. */
    fun deliver(event: Event) {
        incoming.trySend(event)
    }

    /** Ends the streams: the connection to the pool broke with [cause]. */
    fun fail(cause: Throwable) {
        incoming.close(cause)
    }

    /** The next event of any leased player, kept in the timeline. */
    suspend fun nextEvent(): Event = incoming.receive().also { received += it }

    fun send(message: Message) = session.send(message)

    fun nextBarrier(): Int = session.nextBarrier()

    suspend fun probeChat(
        to: GamePlayer,
        text: String,
    ): Mark = Mark(session.probeChat(to, text))

    /** The first frame of [trace] in the requirement's own code, as `File.kt:line`. */
    fun requirementLine(trace: Array<StackTraceElement>): String? =
        trace.firstOrNull { frame -> frame.codeLocation() == requirementCode }?.let { "${it.fileName}:${it.lineNumber}" }

    private fun StackTraceElement.codeLocation(): URL? =
        runCatching {
            Class
                .forName(className, false, Attempt::class.java.classLoader)
                .protectionDomain.codeSource
                ?.location
        }.getOrNull()
}
