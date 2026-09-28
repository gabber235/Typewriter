package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityEquipment
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityMetadata
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoUpdate
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetPassengers
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerUpdateAttributes
import java.util.EnumSet

/**
 * Rewrites or observes the packets a viewer receives about one specific entity.
 *
 * Hooks are registered with the [VisibilityPacketBridge] for a viewer and entity id pair. Rewrite
 * callbacks mutate the wrapper in place and the bridge re encodes the packet afterwards.
 *
 * All callbacks run on netty threads. Implementations must be thread safe, must not block, and must
 * not touch the Bukkit api. Precompute state on registration and read it from volatile fields inside
 * the callbacks.
 */
interface EntityPacketHook {
    fun onMetadata(packet: WrapperPlayServerEntityMetadata) {}

    fun onEquipment(packet: WrapperPlayServerEntityEquipment) {}

    fun onAttributes(packet: WrapperPlayServerUpdateAttributes) {}

    fun onPassengers(packet: WrapperPlayServerSetPassengers) {}

    /**
     * The viewer's client is spawning the entity.
     * Use [PacketSendEvent.getTasksAfterSend] for follow up packets that must arrive after it.
     */
    fun onSpawn(event: PacketSendEvent, packet: WrapperPlayServerSpawnInfo) {}

    /**
     * The viewer's client is destroying the entity.
     * Use [PacketSendEvent.getTasksAfterSend] for follow up packets that must arrive after it.
     */
    fun onDestroy(event: PacketSendEvent) {}
}

/**
 * The location an entity is spawned at, captured from the spawn packet so hooks never read live
 * Bukkit state from a netty thread.
 */
data class WrapperPlayServerSpawnInfo(
    val x: Double,
    val y: Double,
    val z: Double,
    val yaw: Float,
    val pitch: Float,
)

/**
 * Rewrites the player info entries a viewer receives about one specific player profile.
 *
 * Only the packets that add the player or change their display name reach a hook; the rest carry
 * nothing a hook rewrites. Runs on netty threads, under the same constraints as [EntityPacketHook].
 */
interface ProfilePacketHook {
    /** Rewrites a single player info entry in place. */
    fun onPlayerInfo(
        actions: EnumSet<WrapperPlayServerPlayerInfoUpdate.Action>,
        entry: WrapperPlayServerPlayerInfoUpdate.PlayerInfo,
    )
}
