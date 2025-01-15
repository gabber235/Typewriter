package com.typewritermc.basic.entries.bound

import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.github.retrooper.packetevents.protocol.packettype.PacketType.Play
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientPlayerInput
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.dialogue.DialogueTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.extensions.packetevents.spectateEntity
import com.typewritermc.engine.paper.extensions.packetevents.stopSpectatingEntity
import com.typewritermc.engine.paper.interaction.InterceptionBundle
import com.typewritermc.engine.paper.interaction.boundState
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.interaction.interceptPackets
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.engine.paper.utils.toPacketLocation
import kotlinx.coroutines.future.await
import me.tofaa.entitylib.meta.display.TextDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*

@Entry(
    "lock_interaction_bound",
    "An interaction bound that locks the camera for the player",
    Colors.MEDIUM_PURPLE,
    "ic:round-video-camera-front"
)
/**
 * The `Lock Interaction Bound` entry is an interaction bound that locks the camera for the player.
 * Sometimes you want the camera to be at a fixed location but don't want to use a Temporal Sequence.
 *
 * If the state is `INTERRUPTING`, the player will be able to leave the interaction by pressing shift.
 * If the state is `BLOCKING`, the player won't be able to leave the interaction.
 *
 * ## How could this be used?
 * This could be used for a setup screen where the player's camera is locked to a specific location.
 */
class LockInteractionBoundEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val targetPosition: Optional<Var<Position>> = Optional.empty(),
) : InteractionBoundEntry {
    override fun build(player: Player): InteractionBound {
        return LockInteractionBound(
            player,
            targetPosition.orElseGet { ConstVar(player.position) },
            priority
        )
    }
}

class LockInteractionBound(
    private val player: Player,
    private val targetPosition: Var<Position>,
    override val priority: Int,
) : InteractionBound {
    private val originalPosition = player.position
    private var entity: WrapperEntity = createEntity()
    private var interceptor: InterceptionBundle? = null

    override suspend fun initialize() {
        super.initialize()
        if (player.boundState == InteractionBoundState.IGNORING) {
            return
        }
        setup()
    }

    private suspend fun setup() {
        val startPosition = targetPosition.get(player)
        setupEntity(startPosition)

        // If the player is a bedrock player, we don't want to modify the location.
        interceptor = player.interceptPackets {
            Play.Client.PLAYER_INPUT { event ->
                val packet = WrapperPlayClientPlayerInput(event)
                if (packet.isForward || packet.isBackward || packet.isLeft || packet.isRight) {
                    when (player.boundState) {
                        InteractionBoundState.BLOCKING -> event.isCancelled = true
                        InteractionBoundState.INTERRUPTING -> InteractionEndTrigger.triggerFor(
                            player,
                            player.interactionContext ?: context()
                        )

                        InteractionBoundState.IGNORING -> {}
                    }
                    return@PLAYER_INPUT
                }

                if (!packet.isJump && !packet.isShift) return@PLAYER_INPUT
                DialogueTrigger.NEXT_OR_COMPLETE.triggerFor(player, player.interactionContext ?: context())
            }
        }
    }

    private suspend fun dispose() {
        interceptor?.cancel()
        interceptor = null
        teardownEntity()
        player.teleportAsync(originalPosition.toBukkitLocation()).await()
    }

    private fun createEntity(): WrapperEntity {
        return WrapperEntity(EntityTypes.TEXT_DISPLAY)
            .meta<TextDisplayMeta> {
                positionRotationInterpolationDuration = BASE_INTERPOLATION
            }
    }

    private suspend fun setupEntity(position: Position) {
        player.teleportAsync(position.toBukkitLocation()).await()
        entity.spawn(position.withY { it + PLAYER_EYE_HEIGHT }.toPacketLocation())
        entity.addViewer(player.uniqueId)
        player.spectateEntity(entity)
    }

    private fun teardownEntity() {
        player.stopSpectatingEntity()
        entity.removeViewer(player.uniqueId)
        entity.remove()
    }

    override suspend fun tick() {
        if (player.boundState == InteractionBoundState.IGNORING) {
            return
        }

        val newPosition = targetPosition.get(player)
        if (newPosition == originalPosition) return

        if (newPosition.world != originalPosition.world) {
            teardownEntity()
            setupEntity(newPosition)
            return
        }

        entity.teleport(newPosition.withY { it + PLAYER_EYE_HEIGHT }.toPacketLocation())

        if (player.position.distanceSquared(newPosition) > MAX_DISTANCE_SQUARED) {
            player.teleportAsync(newPosition.toBukkitLocation()).await()
        }

        super.tick()
    }

    override suspend fun boundStateChange(
        previousBoundState: InteractionBoundState,
        newBoundState: InteractionBoundState
    ) {
        if (newBoundState == InteractionBoundState.IGNORING) {
            dispose()
            return
        }
        if (previousBoundState == InteractionBoundState.IGNORING) {
            setup()
            return
        }
    }

    override suspend fun teardown() {
        teardownEntity()
        dispose()
    }

    companion object {
        // The default interpolation duration in frames.
        const val BASE_INTERPOLATION = 10

        // The max distance the entity can be from the player before it gets teleported.
        private const val MAX_DISTANCE_SQUARED = 25 * 25

        // The assumed eye height of the player during configuration.
        private const val PLAYER_EYE_HEIGHT = 1.62
    }
}