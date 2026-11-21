package com.typewritermc.engine.paper

import com.destroystokyo.paper.event.server.ServerTickEndEvent
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.events.ChainWorker
import com.typewritermc.events.HasChat
import com.typewritermc.events.LiveResolver
import com.typewritermc.events.Origin
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import net.kyori.adventure.text.Component
import org.bukkit.entity.Player
import org.bukkit.event.Event
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.plugin.Plugin
import java.util.UUID
import kotlin.reflect.KClass

/**
 * What a Paper source needs to turn Bukkit events into Typewriter events: [listen] registers one handler for one
 * Bukkit event class and returns the handle that unregisters it. Registration always happens on the main thread, since
 * the runtime opens sources when content is published, from the delivery worker.
 */
class PaperEvents(
    private val plugin: Plugin,
) {
    fun <B : Event> listen(
        type: KClass<B>,
        priority: EventPriority = EventPriority.NORMAL,
        handle: (B) -> Unit,
    ): AutoCloseable {
        val listener = object : Listener {}
        onMain {
            plugin.server.pluginManager.registerEvent(
                type.java,
                listener,
                priority,
                { _, event -> if (type.isInstance(event)) handle(type.java.cast(event)) },
                plugin,
                // A source decides cancelled events too, so a lower rule's cancel never hides the occurrence.
                false,
            )
        }
        return AutoCloseable { onMain { HandlerList.unregisterAll(listener) } }
    }

    private fun onMain(block: () -> Unit) {
        if (plugin.server.isPrimaryThread) block() else plugin.server.scheduler.runTask(plugin, Runnable(block))
    }
}

/** The live object of an online protagonist on this Paper: a player that can be messaged. */
class PaperProtagonist(
    val player: Player,
) : HasChat {
    override fun send(message: String) = player.sendMessage(Component.text(message))
}

/** Finds the online player of a Minecraft protagonist; any other protagonist has no live object here. */
class PaperProtagonists(
    private val plugin: Plugin,
) : LiveResolver<Protagonist> {
    override val identity = Protagonist::class

    override fun live(identity: Protagonist): PaperProtagonist? {
        if (identity.principal.kind != PrincipalId.MINECRAFT) return null
        val uuid = runCatching { UUID.fromString(identity.principal.id) }.getOrNull() ?: return null
        return plugin.server.getPlayer(uuid)?.let(::PaperProtagonist)
    }
}

/** A player's protagonist: the Minecraft principal of its UUID. */
val Player.protagonist: Protagonist get() = Protagonist(PrincipalId(PrincipalId.MINECRAFT, uniqueId.toString()))

/** A Minecraft player has one session at a time, named by its UUID, so a rejoin continues it. */
val Player.session: SessionId get() = SessionId(uniqueId.toString())

/** What a player caused: its session and its principal. */
val Player.eventOrigin: Origin get() = protagonist.let { Origin(Session(it, session), it.principal) }

/** Hands the chain queue to a worker at the end of every server tick, so chains a tick queued start right after it. */
class PaperChainPickup(
    private val plugin: Plugin,
    private val worker: ChainWorker,
) : Listener,
    RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        plugin.server.scheduler.runTask(plugin, Runnable { plugin.server.pluginManager.registerEvents(this, plugin) })
        scope.own { HandlerList.unregisterAll(this) }
    }

    @EventHandler(priority = EventPriority.MONITOR)
    fun onTickEnd(
        @Suppress("UNUSED_PARAMETER") event: ServerTickEndEvent,
    ) = worker.pickup()
}
