package com.typewritermc.basic.entries.bound

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.InteractionBoundEntry
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.interaction.ListenerInteractionBound
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.distanceSqrt
import org.bukkit.NamespacedKey
import org.bukkit.attribute.Attribute
import org.bukkit.attribute.AttributeModifier
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.player.PlayerMoveEvent
import org.bukkit.event.player.PlayerTeleportEvent

@Entry(
    "player_radius_interaction_bound",
    "An interaction bound around a player",
    Colors.MEDIUM_PURPLE,
    "ph:user-circle-dashed-fill"
)
/**
 * The `Player Radius Interaction Bound` entry is an interaction bound
 * that will cancel the interaction if the player goes outside of a radius.
 * If the current state is `BLOCKING`, the player won't be able to move outside of the radius.
 *
 * ## How could this be used?
 * This could be useful if the player is talking to a npc and you want to cancel the interaction if they walk away.
 */
class PlayerRadiusInteractionBoundEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Default("2.0")
    val radius: Double = 2.0,
    @Default("true")
    val zoom: Boolean = true,
) : InteractionBoundEntry {
    override fun build(player: Player): InteractionBound = PlayerRadiusInteractionBound(player, radius, zoom, priority)
}

class PlayerRadiusInteractionBound(
    private val player: Player,
    private val radius: Double,
    private val zoom: Boolean,
    override val priority: Int,
) : ListenerInteractionBound {
    private val startLocation = player.location
    private val key = NamespacedKey.fromString("zoom", plugin)!!

    override suspend fun initialize() {
        super.initialize()
        updateZoom(0.0)
    }

    private fun updateZoom(distance: Double) {
        if (!zoom) return
        val zoom = calculateZoom(distance)
        val modifier = AttributeModifier(key, zoom, AttributeModifier.Operation.MULTIPLY_SCALAR_1)

        player.getAttribute(Attribute.MOVEMENT_SPEED)?.let { attribute ->
            attribute.removeModifier(key)

            attribute.addModifier(modifier)
        }
    }

    private fun calculateZoom(distance: Double): Double {
        val minZoom = -0.6
        val maxZoom = 0.0

        val normalizedDistance = (distance / (radius * radius)).coerceIn(0.0, 1.0)
        val zoomRange = maxZoom - minZoom

        val t = 1 - normalizedDistance
        return minZoom + ((1 - (t * t * t * t)) * zoomRange)
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    private fun onMove(event: PlayerMoveEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        val location = event.to
        val distance = location.distanceSqrt(startLocation) ?: Double.MAX_VALUE

        updateZoom(distance)
        if (distance < radius * radius) return

        handleEvent(event)
    }

    @EventHandler
    private fun onTeleport(event: PlayerTeleportEvent) {
        onMove(event)
    }

    override suspend fun teardown() {
        if (zoom) {
            player.getAttribute(Attribute.MOVEMENT_SPEED)?.removeModifier(key)
        }
        super.teardown()
    }
}