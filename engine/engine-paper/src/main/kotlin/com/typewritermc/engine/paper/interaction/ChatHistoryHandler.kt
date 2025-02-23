package com.typewritermc.engine.paper.interaction

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.event.PacketListenerAbstract
import com.github.retrooper.packetevents.event.PacketListenerPriority
import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.protocol.chat.message.ChatMessage_v1_19_3
import com.github.retrooper.packetevents.protocol.packettype.PacketType
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerChatMessage
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSystemChatMessage
import com.github.shynixn.mccoroutine.bukkit.registerSuspendingEvents
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.plainText
import lirand.api.extensions.server.server
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.TextComponent
import net.kyori.adventure.text.format.TextColor
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerQuitEvent
import org.koin.java.KoinJavaComponent.get
import java.util.*
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.math.min

private val darkenLimit by snippet(
    "chat.darken-limit",
    12,
    "The amount of messages displayed in the chat history during a dialogue"
)
private val spacing by snippet("chat.spacing", 3, "The amount of padding between the dialogue and the chat history")

class ChatHistoryHandler :
    PacketListenerAbstract(PacketListenerPriority.HIGH), Listener {

    fun initialize() {
        PacketEvents.getAPI().eventManager.registerListener(this)
        server.pluginManager.registerSuspendingEvents(this, plugin)
    }

    private val histories = mutableMapOf<UUID, ChatHistory>()

    // When the serer sends a message to the player
    override fun onPacketSend(event: PacketSendEvent?) {
        try {
            if (event == null) return
            val component = findMessage(event) ?: return
            val history = getHistory(event.user.uuid)
            if (component is TextComponent && component.content().startsWith("no-index")) {
                if (component.content().endsWith("resend")) return

                history.allowedMessageThrough()
                return
            }
            history.addMessage(component)

            if (history.isBlocking()) {
                event.isCancelled = true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun findMessage(event: PacketSendEvent): Component? {
        return when (event.packetType) {
            PacketType.Play.Server.CHAT_MESSAGE -> {
                val packet = WrapperPlayServerChatMessage(event)
                val message = packet.message as? ChatMessage_v1_19_3 ?: return packet.message.chatContent
                message.unsignedChatContent.orElseGet {
                    // Use the default minecraft formatting
                    "\\<<name>> <message>".asMiniWithResolvers(
                        Placeholder.component("name", message.chatFormatting.name),
                        Placeholder.component("message", message.chatContent)
                    )
                }
            }

            PacketType.Play.Server.SYSTEM_CHAT_MESSAGE -> {
                val packet = WrapperPlayServerSystemChatMessage(event)
                if (packet.isOverlay) return null
                packet.message
            }

            else -> null
        }
    }

    fun getHistory(pid: UUID): ChatHistory {
        return histories.getOrPut(pid) { ChatHistory() }
    }

    fun getHistory(player: Player): ChatHistory = getHistory(player.uniqueId)

    fun blockMessages(player: Player) {
        getHistory(player).startBlocking()
    }

    fun unblockMessages(player: Player) {
        getHistory(player).stopBlocking()
    }

    @EventHandler(priority = EventPriority.MONITOR)
    fun onQuit(event: PlayerQuitEvent) {
        histories.remove(event.player.uniqueId)
    }

    fun shutdown() {
        PacketEvents.getAPI().eventManager.unregisterListener(this)
    }
}

val Player.chatHistory: ChatHistory
    get() = get<ChatHistoryHandler>(ChatHistoryHandler::class.java).getHistory(this)

fun Player.startBlockingMessages() = chatHistory.startBlocking()
fun Player.stopBlockingMessages() = chatHistory.stopBlocking()

class ChatHistory {
    private val messages = ConcurrentLinkedQueue<OldMessage>()
    private var blocking = false
    private var blockingState: BlockingStatus = BlockingStatus.FullBlocking

    fun startBlocking() {
        if (blocking) return
        blockingState = BlockingStatus.PartialBlocking(0)
        blocking = true
    }

    fun stopBlocking() {
        blocking = false
    }

    fun isBlocking(): Boolean = blocking

    fun addMessage(message: Component) {
        if (blocking) {
            blockingState = blockingState.addMessage()
        }
        messages.add(OldMessage(message))
        while (messages.size > 100) {
            messages.poll()
        }
    }

    fun hasMessage(message: Component): Boolean {
        return messages.any { it.message == message }
    }

    fun clear() {
        messages.clear()
    }

    fun allowedMessageThrough() {
        blockingState = BlockingStatus.FullBlocking
    }

    private fun clearMessage() = "\n".repeat(100 - min(messages.size, darkenLimit))

    fun resendMessages(player: Player, clear: Boolean = true) {
        when (val status = blockingState) {
            is BlockingStatus.FullBlocking -> {
                // Start with "no-index" to prevent the server from adding the message to the history
                var msg = Component.text("no-index-resend")
                if (clear) msg = msg.append(Component.text(clearMessage()))
                messages.forEach { msg = msg.append(Component.text("\n")).append(it.message) }
                player.sendMessage(msg)
            }

            is BlockingStatus.PartialBlocking -> {
                messages.reversed().take(status.newMessages).forEach { player.sendMessage(it.message) }
            }
        }
        blockingState = BlockingStatus.PartialBlocking(0)
    }

    fun composeDarkMessage(message: Component, clear: Boolean = true): Component {
        // Start with "no-index" to prevent the server from adding the message to the history
        var msg = Component.text("no-index")
        if (clear) msg = msg.append(Component.text(clearMessage()))
        messages.take(darkenLimit).forEach {
            msg = msg.append(it.darkenMessage)
        }
        msg = msg.append(Component.text("\n".repeat(spacing)))
        return msg.append(message)
    }

    fun composeEmptyMessage(message: Component, clear: Boolean = true): Component {
        // Start with "no-index" to prevent the server from adding the message to the history
        var msg = Component.text("no-index")
        if (clear) msg = msg.append(Component.text(clearMessage()))
        return msg.append(message)
    }
}

sealed interface BlockingStatus {
    fun addMessage(): BlockingStatus

    // When it only stopped messages from being sent, but not allowed messages to be sent.
    data class PartialBlocking(val newMessages: Int) : BlockingStatus {
        override fun addMessage(): BlockingStatus = copy(newMessages = newMessages + 1)
    }

    // When a message was allowed through.
    data object FullBlocking : BlockingStatus {
        override fun addMessage(): BlockingStatus = this
    }
}

data class OldMessage(val message: Component) {
    val darkenMessage: Component by lazy(LazyThreadSafetyMode.NONE) {
        Component.text("${message.plainText()}\n").color(TextColor.color(0x7d8085))
    }
}