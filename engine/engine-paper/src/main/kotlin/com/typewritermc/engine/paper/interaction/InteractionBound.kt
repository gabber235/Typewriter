package com.typewritermc.engine.paper.interaction

import com.github.shynixn.mccoroutine.bukkit.registerSuspendingEvents
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.InteractionBoundStateOverrideSubscription
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.plugin
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.server
import org.bukkit.entity.Player
import org.bukkit.event.Cancellable
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerEvent
import java.util.*

val Player.boundState: InteractionBoundState
    get() = interactionScope?.boundState ?: InteractionBoundState.IGNORING

suspend fun Player.overrideBoundState(
    state: InteractionBoundState,
    priority: Int = 0
): InteractionBoundStateOverrideSubscription {
    val id = interactionScope?.addBoundStateOverride(state = state, priority = priority) ?: UUID.randomUUID()
    return InteractionBoundStateOverrideSubscription(id, uniqueId)
}

suspend fun InteractionBoundStateOverrideSubscription.cancel() {
    server.getPlayer(playerUUID)?.interactionScope?.removeBoundStateOverride(id)
}

interface ListenerInteractionBound : InteractionBound, Listener {
    val interruptionTriggers: List<EventTrigger>

    override suspend fun initialize() {
        super.initialize()
        server.pluginManager.registerSuspendingEvents(this, plugin)
    }

    override suspend fun teardown() {
        super.teardown()
        unregister()
    }

    fun <T> handleEvent(event: T) where T : PlayerEvent, T : Cancellable {
        when (event.player.boundState) {
            InteractionBoundState.BLOCKING -> event.isCancelled = true
            InteractionBoundState.INTERRUPTING -> event.player.interruptInteraction()
            InteractionBoundState.IGNORING -> {}
        }
    }

    fun Player.interruptInteraction() {
        (interruptionTriggers + InteractionEndTrigger + InteractionBoundEndTrigger).triggerFor(this, context())
    }
}