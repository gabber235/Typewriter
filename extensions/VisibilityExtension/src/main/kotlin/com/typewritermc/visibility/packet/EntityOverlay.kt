package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.wrapper.PacketWrapper
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityMetadata
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

/**
 * What every effect that rewrites one entity's packets for one viewer shares: the hook registration,
 * the packet sent again behind a spawn, and the teardown that sends the server's own state back.
 *
 * The effector keeps the rewriting itself and hands its hook in. [attach] and [detach] hop to the
 * main thread; [resendAfterSpawn] runs on the connection's thread.
 */
internal class EntityOverlay(private val rule: VisibilityRule) : KoinComponent {
    private val bridge: VisibilityPacketBridge by inject()

    @Volatile
    private var targetEntityId = -1

    @Volatile
    private var disposed = false

    /**
     * Registers [hook] for the pair and runs [apply] with the live players, or does nothing when
     * either of them is offline.
     */
    suspend fun attach(hook: EntityPacketHook, apply: (viewer: Player, target: Player) -> Unit) {
        Dispatchers.Sync.switchContext {
            val viewer = rule.viewerPlayer ?: return@switchContext
            val target = rule.targetPlayer ?: return@switchContext
            targetEntityId = target.entityId
            bridge.addEntityHook(viewer.uniqueId, target.entityId, hook)
            apply(viewer, target)
        }
    }

    /**
     * Queues the packet [build] makes behind the spawn [event] belongs to.
     *
     * The task runs once the whole bundle around the spawn is written, so [build] reads state the
     * bundle's own packets already carried through the hook. Nothing is sent when the effect was
     * disposed by then, since it would overwrite the restore the disposal sent.
     */
    fun resendAfterSpawn(event: PacketSendEvent, build: (entityId: Int) -> PacketWrapper<*>?) {
        val user = event.user
        event.tasksAfterSend.add {
            if (disposed) return@add
            val entityId = targetEntityId
            if (entityId == -1) return@add
            val packet = build(entityId) ?: return@add
            user.sendPacket(packet)
        }
    }

    /**
     * Unregisters [hook] and runs [restore] with the live players, so the server's own state reaches
     * the viewer again. [release] runs first with the entity id, whether or not either player is
     * still online, for state that is keyed by the id alone.
     */
    suspend fun detach(
        hook: EntityPacketHook,
        release: (entityId: Int) -> Unit = {},
        restore: (viewer: Player, target: Player, entityId: Int) -> Unit,
    ) {
        // Set before anything is released, so a spawn task still queued on the connection returns
        // early instead of reapplying the effect after the restore below.
        disposed = true
        Dispatchers.Sync.switchContext {
            val entityId = targetEntityId
            if (entityId == -1) return@switchContext
            bridge.removeEntityHook(rule.viewer, entityId, hook)
            release(entityId)
            val viewer = rule.viewerPlayer ?: return@switchContext
            val target = rule.targetPlayer ?: return@switchContext
            restore(viewer, target, entityId)
        }
    }
}

/**
 * An [EntityOverlay] that sets one bit of the shared entity flags byte for the viewer.
 *
 * The bit is set on every metadata packet that carries the byte, and sent on its own behind a spawn,
 * because the metadata accompanying a spawn omits every flag still at its default and a target that
 * walked back into range would otherwise carry none of the effect's.
 */
internal class EntityFlagOverlay(rule: VisibilityRule, private val flag: Int) : EntityPacketHook {
    private val overlay = EntityOverlay(rule)

    @Volatile
    private var lastServerFlags = 0

    /** Hooks the pair and sends the flag, running [apply] with the live players in between. */
    suspend fun attach(apply: (viewer: Player, target: Player) -> Unit = { _, _ -> }) {
        overlay.attach(this) { viewer, target ->
            lastServerFlags = serverSideEntityFlags(target)
            apply(viewer, target)
            entityFlagsPacket(target.entityId, lastServerFlags or flag) sendPacketTo viewer
        }
    }

    /** Unhooks the pair and sends the target's server side flags again, running [release] first. */
    suspend fun detach(release: (entityId: Int) -> Unit = {}) {
        overlay.detach(this, release) { viewer, target, entityId ->
            entityFlagsPacket(entityId, serverSideEntityFlags(target)) sendPacketTo viewer
        }
    }

    override fun onMetadata(packet: WrapperPlayServerEntityMetadata) {
        // The bit this effect owns is masked out of the remembered flags. Our own packets come back
        // through this hook, so keeping it would record the effect as part of the target's server
        // side state and it would survive its own removal.
        readEntityFlags(packet.entityMetadata)?.let { lastServerFlags = it and flag.inv() }
        rewriteEntityFlags(packet.entityMetadata, setMask = flag)
    }

    override fun onSpawn(event: PacketSendEvent, packet: WrapperPlayServerSpawnInfo) {
        // A fresh add resets the client's copy to defaults, and the metadata packet following this
        // one in the same bundle carries only what is not default. Clearing here and letting that
        // packet refill it is what stops a flag the target no longer has from returning.
        lastServerFlags = 0
        overlay.resendAfterSpawn(event) { entityId -> entityFlagsPacket(entityId, lastServerFlags or flag) }
    }
}
