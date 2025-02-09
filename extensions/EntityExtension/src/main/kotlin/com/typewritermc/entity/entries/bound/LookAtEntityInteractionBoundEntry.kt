package com.typewritermc.entity.entries.bound

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.core.utils.point.toVector
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entity.ActivityEntityDisplay
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.interaction.ListenerInteractionBound
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.distanceSqrt
import com.typewritermc.engine.paper.utils.toPosition
import com.typewritermc.entity.entries.activity.*
import com.typewritermc.entity.entries.event.InteractingEntityInstance
import org.bukkit.NamespacedKey
import org.bukkit.attribute.Attribute
import org.bukkit.attribute.AttributeModifier
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.player.PlayerMoveEvent
import org.bukkit.event.player.PlayerTeleportEvent
import org.koin.java.KoinJavaComponent.get
import java.time.Duration
import java.time.Instant
import kotlin.math.abs


private val lookBackDelay: Int by snippet("look_at_entity_interaction_bound.look_back_delay", 500, "The duration in Milliseconds the player can move their head before the bound forces them to look at teh entity.")

@Entry(
    "look_at_entity_interaction_bound",
    "An interaction which forces the player to look at an entity",
    Colors.MEDIUM_PURPLE,
    "mingcute:look-up-fill"
)
class LookAtEntityInteractionBoundEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val interruptTriggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Default("2.0")
    val radius: Double = 2.0,
    @Help("If left empty, the entity where they interacted with will be used.")
    val npc: Ref<EntityInstanceEntry> = emptyRef(),
) : InteractionBoundEntry {
    override fun build(player: Player): InteractionBound = LookAtNpcInteractionBound(player, radius, npc, priority, interruptTriggers.eventTriggers)
}

class LookAtNpcInteractionBound(
    private val player: Player,
    private val radius: Double,
    private val instanceEntryRef: Ref<out EntityInstanceEntry>,
    override val priority: Int,
    override val interruptionTriggers: List<EventTrigger>,
) : ListenerInteractionBound {
    private val startLocation = player.location
    private val key = NamespacedKey.fromString("zoom", plugin)!!

    override suspend fun initialize() {
        super.initialize()
        updateZoom(0.0)
    }

    private fun updateZoom(distance: Double) {
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

    private val yawVelocity = Velocity(0f)
    private val pitchVelocity = Velocity(0f)

    private var state: AnimationState = AnimationState.Animating
    private val animationThreshold = 0.5f

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    private fun onLook(event: PlayerMoveEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        if (!event.hasChangedOrientation() && !event.hasExplicitlyChangedPosition()) return
        if (state.isAnimating()) return

        state = AnimationState.Moved(Instant.now())
    }

    override suspend fun tick() {
        super.tick()
        state = state.transition()
        if (!state.isAnimating()) return

        val context = player.interactionContext ?: return
        val ref =
            if (instanceEntryRef.isSet) instanceEntryRef
            else context[InteractingEntityInstance] as? Ref<out EntityInstanceEntry>
                ?: return

        val display = get<AudienceManager>(AudienceManager::class.java)[ref] as? ActivityEntityDisplay ?: return

        if (!display.isSpawnedIn(player.uniqueId)) {
            state = AnimationState.Idle
            yawVelocity.value = 0f
            pitchVelocity.value = 0f
            return
        }

        val entityState = display.entityState(player.uniqueId)
        val position = display.position(player.uniqueId)
        val target = position?.add(0.0, entityState.eyeHeight, 0.0) ?: return

        val playerEyePosition = player.eyeLocation.toPosition()
        val direction = target.toVector()
            .minus(playerEyePosition)
            .normalize()

        val targetYaw = getLookYaw(direction.x, direction.z)
        val targetPitch = getLookPitch(direction.x, direction.y, direction.z)

        val (newYaw, newPitch) = updateLookDirection(
            LookDirection(playerEyePosition.yaw, playerEyePosition.pitch),
            LookDirection(targetYaw, targetPitch),
            yawVelocity,
            pitchVelocity,
            smoothTime = 0.20f
        )

        player.teleportAsync(player.location.clone().apply {
            yaw = newYaw
            pitch = newPitch
        })
        val yawDiff = abs(normalizeYaw(targetYaw - newYaw))
        val pitchDiff = abs(targetPitch - newPitch)

        if (yawDiff < animationThreshold && pitchDiff < animationThreshold) {
            state = AnimationState.Idle
            yawVelocity.value = 0f
            pitchVelocity.value = 0f
        }
    }

    override suspend fun teardown() {
        player.getAttribute(Attribute.MOVEMENT_SPEED)?.removeModifier(key)
        super.teardown()
    }
}

private sealed interface AnimationState {
    fun isAnimating(): Boolean = this is Animating

    fun transition(): AnimationState

    data object Idle : AnimationState {
        override fun transition(): AnimationState = this
    }

    data class Moved(val lastMove: Instant) : AnimationState {
        fun canAnimate(): Boolean = Duration.between(lastMove, Instant.now()).toMillis() > lookBackDelay
        override fun transition(): AnimationState = if (canAnimate()) Animating else this
    }

    data object Animating : AnimationState {
        override fun transition(): AnimationState = this
    }
}