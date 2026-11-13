package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.InputStep
import com.typewritermc.playtest.wire.Message.Perception
import com.typewritermc.playtest.wire.Message.ProbeAction
import com.typewritermc.playtest.wire.Message.Region
import com.typewritermc.playtest.wire.Message.Watch
import kotlinx.coroutines.channels.Channel
import java.net.URL

/**
 * One attempt of one requirement while it holds its lease: the players' perception streams in arrival
 * order, kept whole as the attempt's timeline, and the session it talks to the pool through. Positions
 * the requirement names count from the middle of the attempt's [region]; the attempt turns them into
 * world positions on the way out and turns what the players perceive back on the way in.
 */
internal class Attempt(
    private val session: PoolSession,
    val players: List<GamePlayer>,
    val region: Region,
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
        incoming.trySend(if (event is Event.Perceived) event.copy(perception = region.local(event.perception)) else event)
    }

    /** Ends the streams: the connection to the pool broke with [cause]. */
    fun fail(cause: Throwable) {
        incoming.close(cause)
    }

    /** The next event of any leased player, kept in the timeline. */
    suspend fun nextEvent(): Event = incoming.receive().also { received += it }

    fun send(message: Message) = session.send(message)

    fun nextBarrier(): Int = session.nextBarrier()

    /** Paper runs [action] for [players] and returns once each of their clients holds its effect; the mark is the tick after which it ran. */
    suspend fun probe(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Mark = Mark(session.probe(players, action))

    /** [player]'s client runs [steps]; the mark is the tick after which its first event reached the client. */
    suspend fun input(
        player: GamePlayer,
        steps: List<InputStep>,
    ): Mark = Mark(session.input(player, steps))

    /** Every leased player's client watches these from now on. */
    fun watch(
        blocks: List<BlockRef>,
        entities: List<EntityRef>,
    ) = players.forEach { send(Watch(it.uuid, blocks.map { block -> region.world(block.at) }, entities.map { entity -> entity.uuid })) }

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
