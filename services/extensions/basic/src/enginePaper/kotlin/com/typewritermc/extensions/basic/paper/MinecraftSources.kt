package com.typewritermc.extensions.basic.paper

import com.typewritermc.engine.paper.PaperEvents
import com.typewritermc.engine.paper.eventOrigin
import com.typewritermc.engine.paper.protagonist
import com.typewritermc.events.Outcome
import com.typewritermc.events.Sink
import com.typewritermc.events.Source
import com.typewritermc.extensions.basic.events.BlockBreak
import com.typewritermc.extensions.basic.events.PlayerChat
import com.typewritermc.extensions.basic.events.PlayerJoin
import com.typewritermc.extensions.basic.events.PlayerQuit
import io.papermc.paper.event.player.AsyncChatEvent
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer
import org.bukkit.event.block.BlockBreakEvent
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent

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
            sink.decide(BlockBreak(broken.player.protagonist, broken.block.type.key.toString()), broken.player.eventOrigin) {
                broken.isCancelled = it is Outcome.Denied
            }
        }
}
