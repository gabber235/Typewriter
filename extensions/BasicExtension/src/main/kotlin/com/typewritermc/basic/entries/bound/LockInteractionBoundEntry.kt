package com.typewritermc.basic.entries.bound

import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.github.retrooper.packetevents.protocol.packettype.PacketType.Play
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientInteractEntity
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientPlayerInput
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientPlayerPosition
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientPlayerPositionAndRotation
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerPositionAndLook
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.dialogue.DialogueTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.extensions.packetevents.spectateEntity
import com.typewritermc.engine.paper.extensions.packetevents.stopSpectatingEntity
import com.typewritermc.engine.paper.interaction.*
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.*
import com.typewritermc.engine.paper.utils.GenericPlayerStateProvider.*
import kotlinx.coroutines.future.await
import lirand.api.extensions.server.server
import me.tofaa.entitylib.meta.display.TextDisplayMeta
import me.tofaa.entitylib.meta.mobs.villager.VillagerMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.entity.EntityDamageByBlockEvent
import org.bukkit.event.entity.EntityDamageByEntityEvent
import org.bukkit.event.entity.EntityDamageEvent
import org.bukkit.event.entity.PlayerDeathEvent
import org.geysermc.geyser.api.connection.GeyserConnection
import java.util.*

// The max distance the entity can be from the player before it gets teleported.
private const val MAX_DISTANCE_SQUARED = 25 * 25

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
    override val interruptTriggers: List<Ref<TriggerableEntry>> = emptyList(),
    @WithRotation
    val targetPosition: Optional<Var<Position>> = Optional.empty(),
) : InteractionBoundEntry {
    override fun build(player: Player): InteractionBound {
        return LockInteractionBound(
            player,
            targetPosition.orElseGet { ConstVar(player.position) },
            priority,
            interruptTriggers.eventTriggers,
        )
    }
}

class LockInteractionBound(
    private val player: Player,
    private val targetPosition: Var<Position>,
    override val priority: Int,
    override val interruptionTriggers: List<EventTrigger>,
) : ListenerInteractionBound {
    private var handler: LockInteractionBoundHandler? = null
    private var playerState: PlayerState? = null
    private var previousPosition: Position = Position.ORIGIN
    private var interceptor: InterceptionBundle? = null

    override suspend fun initialize() {
        super.initialize()
        if (player.boundState == InteractionBoundState.IGNORING) {
            return
        }
        setup()
    }

    private suspend fun setup() {
        assert(playerState == null)
        playerState = player.state(LOCATION, FLYING, ALLOW_FLIGHT, VISIBLE_PLAYERS, SHOWING_PLAYER)
        player.allowFlight = true
        player.isFlying = true
        // For bedrock players we don't need to fake the inventory as we already hide the hotbar and item.
        if (!player.isFloodgate) {
            player.fakeClearInventory()
        }

        ThreadType.SYNC.switchContext {
            server.onlinePlayers.forEach {
                it.hidePlayer(plugin, player)
                player.hidePlayer(plugin, it)
            }
        }

        interceptor = player.interceptPackets {
            Play.Client.PLAYER_INPUT { event ->
                val packet = WrapperPlayClientPlayerInput(event)
                if (packet.isForward || packet.isBackward || packet.isLeft || packet.isRight) {
                    when (player.boundState) {
                        InteractionBoundState.BLOCKING -> event.isCancelled = true
                        InteractionBoundState.INTERRUPTING -> player.interruptInteraction()
                        InteractionBoundState.IGNORING -> {}
                    }
                    return@PLAYER_INPUT
                }

                if (!packet.isJump && !packet.isShift) return@PLAYER_INPUT
                DialogueTrigger.NEXT_OR_COMPLETE.triggerFor(player, player.interactionContext ?: context())
            }
            // We want to fake the player's location on the client because otherwise they will interact with
            // themselves crash kicking themselves off the server.
            Play.Client.INTERACT_ENTITY { event ->
                val packet = WrapperPlayClientInteractEntity(event)
                // Don't allow the player to interact with themselves.
                if (player.entityId != packet.entityId) return@INTERACT_ENTITY
                event.isCancelled = true
            }

            // We want to fake the position on the client otherwise we might see the player itself.
            Play.Server.PLAYER_POSITION_AND_LOOK { event ->
                val packet = WrapperPlayServerPlayerPositionAndLook(event)
                packet.y += 500
            }
            Play.Client.PLAYER_POSITION { event ->
                val packet = WrapperPlayClientPlayerPosition(event)
                packet.position = packet.position.withY(packet.position.y - 500)
            }
            Play.Client.PLAYER_POSITION_AND_ROTATION { event ->
                val packet = WrapperPlayClientPlayerPositionAndRotation(event)
                packet.position = packet.position.withY(packet.position.y - 500)
            }

            // If the player is a bedrock player, we don't need to fake the inventory, as we can just hide it.
            if (player.isFloodgate) return@interceptPackets
            keepFakeInventory()
        }

        val startPosition = targetPosition.get(player)
        previousPosition = startPosition
        handler =
            player.geyserConnection?.let {
                BedrockLockInteractionBoundHandler(player, it, startPosition)
            } ?: JavaLockInteractionBoundHandler(player, targetPosition is ConstVar<*>, startPosition)
        handler?.initialize()
    }

    private suspend fun dispose() {
        interceptor?.cancel()
        interceptor = null
        handler?.dispose()
        handler = null
        if (!player.isFloodgate) {
            player.restoreInventory()
        }
        ThreadType.SYNC.switchContext {
            player.restore(playerState)
            playerState = null
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerDamaged(event: EntityDamageEvent) {
        if (event.entity.uniqueId != player.uniqueId) return
        val player = event.entity as? Player ?: return
        if (player.boundState == InteractionBoundState.IGNORING) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerDamaged(event: EntityDamageByEntityEvent) = onPlayerDamaged(event as EntityDamageEvent)

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerDamaged(event: EntityDamageByBlockEvent) = onPlayerDamaged(event as EntityDamageEvent)

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerDeath(event: PlayerDeathEvent) {
        if (event.entity.uniqueId != player.uniqueId) return
        val player = event.player
        if (player.boundState == InteractionBoundState.IGNORING) return
        event.isCancelled = true
    }


    override suspend fun tick() {
        super.tick()
        if (player.boundState == InteractionBoundState.IGNORING) {
            return
        }

        if (targetPosition is ConstVar<*> || handler == null) return
        val newPosition = targetPosition.get(player)
        handler?.move(previousPosition, newPosition)
        previousPosition = newPosition
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
        dispose()
    }
}

private sealed interface LockInteractionBoundHandler {
    suspend fun initialize()
    suspend fun move(from: Position, to: Position)
    suspend fun dispose()
}

private class JavaLockInteractionBoundHandler(
    private val player: Player,
    private val canMove: Boolean,
    private val startPosition: Position,
) : LockInteractionBoundHandler {
    private var entity: WrapperEntity = createEntity()

    private val positionYCorrection: Double by lazy {
        if (!canMove) return@lazy 0.0
        player.eyeHeight
    }

    override suspend fun initialize() {
        setupEntity(startPosition)
    }

    override suspend fun move(from: Position, to: Position) {
        if (from.world != to.world) {
            teardownEntity()
            setupEntity(to)
            return
        }

        entity.teleport(to.withY { it + positionYCorrection }.toPacketLocation())

        if (player.position.distanceSquared(to) > MAX_DISTANCE_SQUARED) {
            player.teleportAsync(to.toBukkitLocation()).await()
        }
    }

    override suspend fun dispose() {
        teardownEntity()
    }


    private fun createEntity(): WrapperEntity {
        // If the position cannot change, we want to use a village instead of a text display.
        // Because it means that the players bounding box will not change, resulting in a better experience.
        if (!canMove) {
            return WrapperEntity(EntityTypes.VILLAGER).meta<VillagerMeta> {
                this.isInvisible = true
            }
        }
        return WrapperEntity(EntityTypes.TEXT_DISPLAY)
            .meta<TextDisplayMeta> {
                positionRotationInterpolationDuration = BASE_INTERPOLATION
            }
    }

    private suspend fun setupEntity(position: Position) {
        player.teleportAsync(position.toBukkitLocation()).await()
        entity.spawn(position.withY { it + positionYCorrection }.toPacketLocation())
        entity.addViewer(player.uniqueId)
        player.spectateEntity(entity)
    }


    private fun teardownEntity() {
        player.stopSpectatingEntity()
        entity.removeViewer(player.uniqueId)
        entity.remove()
    }

    companion object {
        // The default interpolation duration in frames.
        const val BASE_INTERPOLATION = 10
    }
}

private class BedrockLockInteractionBoundHandler(
    private val player: Player,
    private val geyserConnection: GeyserConnection,
    private val startPosition: Position,
) : LockInteractionBoundHandler {
    private val cameraLockId = UUID.randomUUID()


    private val positionYCorrection: Double by lazy {
        player.eyeHeight
    }

    override suspend fun initialize() {
        val position = startPosition.withY { it + positionYCorrection }
        player.teleportAsync(position.toBukkitLocation()).await()
        geyserConnection.setupCamera(cameraLockId)
        geyserConnection.forceCameraPosition(position)
    }

    override suspend fun move(from: Position, to: Position) {
        val position = to.withY { it + positionYCorrection }
        if (from.world != to.world) {
            player.teleportAsync(to.toBukkitLocation()).await()
            geyserConnection.forceCameraPosition(position)
            return
        }
        geyserConnection.interpolateCameraPosition(position)
        if (player.position.distanceSquared(to) > MAX_DISTANCE_SQUARED) {
            player.teleportAsync(to.toBukkitLocation()).await()
        }
    }

    override suspend fun dispose() {
        geyserConnection.resetCamera(cameraLockId)
    }
}