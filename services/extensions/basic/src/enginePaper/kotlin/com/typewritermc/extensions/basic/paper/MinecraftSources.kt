package com.typewritermc.extensions.basic.paper

import com.destroystokyo.paper.event.server.ServerTickStartEvent
import com.typewritermc.engine.paper.PaperEvents
import com.typewritermc.engine.paper.eventOrigin
import com.typewritermc.engine.paper.protagonist
import com.typewritermc.events.Demand
import com.typewritermc.events.Outcome
import com.typewritermc.events.Sink
import com.typewritermc.events.Source
import com.typewritermc.events.SubscribedSource
import com.typewritermc.extensions.basic.events.BlockBreak
import com.typewritermc.extensions.basic.events.PlayerChat
import com.typewritermc.extensions.basic.events.PlayerJoin
import com.typewritermc.extensions.basic.events.PlayerQuit
import com.typewritermc.extensions.basic.events.Tick
import com.typewritermc.extensions.basic.events.TickSubscription
import io.papermc.paper.event.player.AsyncChatEvent
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer
import org.bukkit.event.block.BlockBreakEvent
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import java.util.concurrent.atomic.AtomicReference

/** Reports every join on this Paper. */
class PlayerJoinSource(
    private val events: PaperEvents,
) : Source<PlayerJoin> {
    override val event = PlayerJoin::class

    override fun open(sink: Sink<PlayerJoin>): AutoCloseable =
        events.listen(PlayerJoinEvent::class) { sink.decide(PlayerJoin(it.player.protagonist), it.player.eventOrigin) }
}

/** Reports every quit on this Paper. */
class PlayerQuitSource(
    private val events: PaperEvents,
) : Source<PlayerQuit> {
    override val event = PlayerQuit::class

    override fun open(sink: Sink<PlayerQuit>): AutoCloseable =
        events.listen(PlayerQuitEvent::class) { sink.decide(PlayerQuit(it.player.protagonist), it.player.eventOrigin) }
}

/** Reports every chat message as plain text; a denied message is not sent. Paper fires chat off the main thread. */
class PlayerChatSource(
    private val events: PaperEvents,
) : Source<PlayerChat> {
    override val event = PlayerChat::class

    override fun open(sink: Sink<PlayerChat>): AutoCloseable =
        events.listen(AsyncChatEvent::class) { chat ->
            val message = PlainTextComponentSerializer.plainText().serialize(chat.message())
            sink.decide(PlayerChat(chat.player.protagonist, message), chat.player.eventOrigin) { chat.isCancelled = it is Outcome.Denied }
        }
}

/** Reports every block a player breaks; a denied break leaves the block. */
class BlockBreakSource(
    private val events: PaperEvents,
) : Source<BlockBreak> {
    override val event = BlockBreak::class

    override fun open(sink: Sink<BlockBreak>): AutoCloseable =
        events.listen(BlockBreakEvent::class) { broken ->
            val block =
                broken.block.type.key
                    .asString()
            sink.decide(BlockBreak(broken.player.protagonist, block), broken.player.eventOrigin) {
                broken.isCancelled = it is Outcome.Denied
            }
        }
}

/**
 * Emits a [Tick] for each demanded subscription at the start of every server tick whose number is a multiple of its
 * interval. Subscriptions are indexed by interval as the demand changes, so a tick costs one check per distinct
 * interval and the chains it starts are picked up at the end of the same tick.
 */
class TickSource(
    private val events: PaperEvents,
) : SubscribedSource<Tick<*>, TickSubscription> {
    override val event = Tick::class
    override val subscription = TickSubscription::class

    override fun open(
        demand: Demand<TickSubscription>,
        sink: Sink<Tick<*>>,
    ): AutoCloseable {
        val byInterval = AtomicReference<Map<Int, List<TickSubscription>>>(emptyMap())
        val watching = demand.watch { subscriptions -> byInterval.set(subscriptions.groupBy { it.interval.coerceAtLeast(1) }) }
        val listening =
            events.listen(ServerTickStartEvent::class) { tick ->
                byInterval.get().forEach { (interval, subscriptions) ->
                    if (tick.tickNumber % interval == 0) subscriptions.forEach { sink.decide(Tick(it), null) }
                }
            }
        return AutoCloseable {
            listening.close()
            watching.close()
        }
    }
}
