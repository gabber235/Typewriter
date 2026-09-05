package com.typewritermc.visibility.entry.effect

import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityMetadata
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.EntityOverlay
import com.typewritermc.visibility.packet.EntityPacketHook
import com.typewritermc.visibility.packet.WrapperPlayServerSpawnInfo
import com.typewritermc.visibility.packet.entityPosePacket
import com.typewritermc.visibility.packet.rewriteEntityPose
import com.typewritermc.visibility.packet.toEntityPose
import com.typewritermc.visibility.rule.VisibilityRule
import org.bukkit.entity.Player

/**
 * The poses a player model actually renders in.
 * The protocol has more poses, but the rest belong to other entity types and leave a player
 * standing.
 */
enum class VisibilityPose(val pose: EntityPose) {
    STANDING(EntityPose.STANDING),
    SNEAKING(EntityPose.CROUCHING),
    SWIMMING(EntityPose.SWIMMING),
    GLIDING(EntityPose.FALL_FLYING),
    RIPTIDE(EntityPose.SPIN_ATTACK),
    SLEEPING(EntityPose.SLEEPING),
    DYING(EntityPose.DYING),
}

@Entry(
    "pose_visibility_effect",
    "Changes the pose the viewer sees the target in",
    Colors.BLUE_VIOLET,
    "bi:person-arms-up"
)
/**
 * The `Pose Visibility Effect` locks the pose the viewer sees the target in, regardless of what
 * the target is actually doing.
 *
 * ## How could this be used?
 * Show a knocked out player as sleeping to everyone else, or make a player appear to be swimming
 * through the air during a dream sequence.
 */
class PoseVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The pose the viewer sees the target in.")
    val pose: VisibilityPose = VisibilityPose.SLEEPING,
    @Help("Also apply this effect to the target's own view of themselves.")
    val self: Var<Boolean> = ConstVar(false),
) : VisibilityEffectEntry {
    override val supportsSelf: Boolean get() = true

    override fun appliesToSelf(viewer: Player): Boolean = self.get(viewer)

    override fun constantSelf(): Boolean? = (self as? ConstVar)?.value

    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        PoseVisibilityEffector(rule, pose.pose)
}

private class PoseVisibilityEffector(
    rule: VisibilityRule,
    private val pose: EntityPose,
) : VisibilityEffector, EntityPacketHook {
    private val overlay = EntityOverlay(rule)

    override suspend fun initialize() = overlay.attach(this) { viewer, target ->
        entityPosePacket(target.entityId, pose) sendPacketTo viewer
    }

    override fun onMetadata(packet: WrapperPlayServerEntityMetadata) {
        rewriteEntityPose(packet.entityMetadata, pose)
    }

    /**
     * A standing target's pose is the default one, which the metadata packet accompanying a spawn
     * omits entirely. Sending the pose again after the spawn is what preserves the effect across a
     * re add.
     */
    override fun onSpawn(event: PacketSendEvent, packet: WrapperPlayServerSpawnInfo) =
        overlay.resendAfterSpawn(event) { entityId -> entityPosePacket(entityId, pose) }

    override suspend fun dispose() = overlay.detach(this) { viewer, target, entityId ->
        entityPosePacket(entityId, target.pose.toEntityPose()) sendPacketTo viewer
    }
}
