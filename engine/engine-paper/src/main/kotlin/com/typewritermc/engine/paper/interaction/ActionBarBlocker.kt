package com.typewritermc.engine.paper.interaction

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.event.PacketListenerAbstract
import com.github.retrooper.packetevents.event.PacketListenerPriority
import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.protocol.packettype.PacketType.Play
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerActionBar
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSystemChatMessage
import com.github.shynixn.mccoroutine.bukkit.registerSuspendingEvents
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.server
import net.kyori.adventure.text.Component
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerQuitEvent
import org.koin.java.KoinJavaComponent.get
import java.util.*
import java.util.concurrent.ConcurrentLinkedQueue

class ActionBarBlockerHandler :
    PacketListenerAbstract(PacketListenerPriority.HIGH), Listener {
    fun initialize() {
        PacketEvents.getAPI().eventManager.registerListener(this)
        server.pluginManager.registerSuspendingEvents(this, plugin)
    }

    private val blockers = mutableMapOf<UUID, ActionBarBlocker>()

    override fun onPacketSend(event: PacketSendEvent?) {
        if (event == null) return
        val blocker = blockers[event.user.uuid] ?: return

        val component = when (event.packetType) {
            Play.Server.SYSTEM_CHAT_MESSAGE -> {
                val packet = WrapperPlayServerSystemChatMessage(event)
                if (!packet.isOverlay) return
                packet.message
            }

            Play.Server.ACTION_BAR -> {
                val packet = WrapperPlayServerActionBar(event)
                packet.actionBarText ?: return
            }

            else -> return
        }

        if (blocker.isMessageAccepted(component)) return
        event.isCancelled = true
    }

    fun acceptMessage(player: Player, message: Component) {
        val blocker = blockers[player.uniqueId] ?: return
        blocker.acceptMessage(message)
    }

    fun enable(player: Player) {
        if (player.uniqueId in blockers) return
        blockers[player.uniqueId] = ActionBarBlocker()
    }

    fun disable(player: Player) {
        blockers.remove(player.uniqueId)
    }

    @EventHandler(priority = EventPriority.MONITOR)
    fun onQuit(event: PlayerQuitEvent) {
        blockers.remove(event.player.uniqueId)
    }

    fun shutdown() {
        PacketEvents.getAPI().eventManager.unregisterListener(this)
    }
}

fun Player.startBlockingActionBar() {
    get<ActionBarBlockerHandler>(ActionBarBlockerHandler::class.java).enable(this)
}

fun Player.stopBlockingActionBar() {
    get<ActionBarBlockerHandler>(ActionBarBlockerHandler::class.java).disable(this)
}

fun Player.acceptActionBarMessage(message: Component) {
    get<ActionBarBlockerHandler>(ActionBarBlockerHandler::class.java).acceptMessage(this, message)
}

/**
 * Keep track of the last 20 accepted messages that are allowed to be sent to the player.
 */
class ActionBarBlocker {
    private val acceptedMessages = ConcurrentLinkedQueue<Component>()

    fun acceptMessage(message: Component) {
        if (isMessageAccepted(message)) return
        acceptedMessages.add(message)
        while (acceptedMessages.size > 20) {
            acceptedMessages.poll()
        }
    }

    fun isMessageAccepted(message: Component): Boolean {
        return acceptedMessages.contains(message)
    }
}