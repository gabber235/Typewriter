package com.typewritermc.entity.entries.data.minecraft

import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityData
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.EntityMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import org.bukkit.entity.Pose
import java.util.*
import kotlin.reflect.KClass

@Entry("pose_data", "The pose of the entity", Colors.RED, "bi:person-arms-up")
class PoseData(
    override val id: String = "",
    override val name: String = "",
    @Help("The pose of the entity.")
    val pose: EntityPose = EntityPose.STANDING,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : GenericEntityData<PoseProperty> {
    override fun type(): KClass<PoseProperty> = PoseProperty::class

    override fun build(player: Player): PoseProperty = PoseProperty(pose)
}

data class PoseProperty(val pose: EntityPose) : EntityProperty {
    companion object :
        SinglePropertyCollectorSupplier<PoseProperty>(PoseProperty::class, PoseProperty(EntityPose.STANDING))
}

fun Pose.toEntityPose() = when (this) {
    Pose.SNEAKING -> EntityPose.CROUCHING
    else -> EntityPose.valueOf(this.name)
}

fun EntityPose.toBukkitPose() = when (this) {
    EntityPose.CROUCHING -> Pose.SNEAKING
    else -> Pose.valueOf(this.name)
}

fun EntityPose.toProperty() = PoseProperty(this)

fun applyPoseData(entity: WrapperEntity, property: PoseProperty) {
    entity.metas {
        meta<EntityMeta> {
            pose = property.pose
            isSneaking = property.pose == EntityPose.CROUCHING
            isSwimming = property.pose == EntityPose.SWIMMING
            isFlyingWithElytra = property.pose == EntityPose.FALL_FLYING
        }
        error("Could not apply PoseData to ${entity.entityType} entity.")
    }
}