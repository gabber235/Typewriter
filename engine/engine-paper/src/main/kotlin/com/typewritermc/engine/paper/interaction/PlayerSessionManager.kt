package com.typewritermc.engine.paper.interaction

import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.isInDialogue
import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.ThreadType.DISPATCHERS_ASYNC
import kotlinx.coroutines.runBlocking
import lirand.api.extensions.server.registerEvents
import com.typewritermc.core.utils.server
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import org.koin.core.component.KoinComponent
import java.util.*
import java.util.concurrent.ConcurrentHashMap

internal const val TICK_MS = 50L

// This is the most magic value I have ever seen.
internal const val AVERAGE_SCHEDULING_DELAY_MS = 5L

class PlayerSessionManager : Listener, KoinComponent {
    private val sessions = ConcurrentHashMap<UUID, PlayerSession>()

    val Player.session: PlayerSession?
        get() = sessions[uniqueId]


    /** Some triggers start dialogue. Though we don't want to trigger the starting of dialogue multiple times,
     * we need to check if the player is already in a dialogue.
     *
     * @param player The player who interacted
     * @param initialTriggers The trigger that should be fired after the quest started
     * @param continueTrigger The trigger that should be fired if the quest is already active
     */
    fun startDialogueWithOrTriggerEvent(
        player: Player,
        context: InteractionContext,
        initialTriggers: List<EventTrigger>,
        continueTrigger: EventTrigger? = null
    ) {
        if (player.isInDialogue) {
            if (continueTrigger != null) {
                triggerEvent(Event(player, context, continueTrigger))
            }
        } else {
            triggerEvent(Event(player, context, initialTriggers))
        }
    }

    /**
     * Triggers a list of actions.
     *
     * @param player The player who interacted
     * @param triggers A list of triggers that should be fired.
     */
    fun triggerActions(player: Player, context: InteractionContext, triggers: List<EventTrigger>) {
        triggerEvent(Event(player, context, triggers))
    }

    /**
     * Forces an event to be executed.
     * This will bypass the event queue and execute the event immediately.
     * This is useful for events that need to be executed immediately.
     * **This should only be used sparingly.**
     *
     * @param player The player who interacted
     * @param triggers The trigger that should be fired.
     */
    suspend fun forceTriggerActions(player: Player, context: InteractionContext, triggers: List<EventTrigger>) {
        player.session?.forceEvent(Event(player, context, triggers))
    }


    private fun triggerEvent(event: Event) {
        // If the event is empty, we don't need to do anything
        if (event.triggers.isEmpty()) return

        DISPATCHERS_ASYNC.launch {
            try {
                event.player.session?.addToSchedule(event)
            } catch (e: Exception) {
                logger.severe("An error occurred while handling event ${event}: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    fun initialize() {
        plugin.registerEvents(this)
    }

    // When a player joins the server, we need to create a session for them.
    @EventHandler(priority = EventPriority.LOWEST)
    fun onPlayerJoin(event: PlayerJoinEvent) {
        val session = PlayerSession(event.player)
        sessions[event.player.uniqueId] = session
        session.setup()
    }

    // When a player leaves the server, we need to end the session.
    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerQuit(event: PlayerQuitEvent) {
        runBlocking {
            sessions.remove(event.player.uniqueId)?.teardown()
        }
    }

    fun load() {
        sessions.putAll(server.onlinePlayers.map { it.uniqueId to PlayerSession(it) })
        sessions.forEach { (_, session) ->
            session.setup()
        }
    }

    suspend fun unload() {
        sessions.forEach { (_, session) ->
            session.teardown()
        }
        sessions.clear()
    }

    suspend fun shutdown() {
        sessions.forEach { (_, session) ->
            session.teardown()
        }
        sessions.clear()
    }
}