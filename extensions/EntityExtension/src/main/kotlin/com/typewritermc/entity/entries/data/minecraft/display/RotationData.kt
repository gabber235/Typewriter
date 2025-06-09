package com.typewritermc.entity.entries.data.minecraft.display

import com.github.retrooper.packetevents.util.Quaternion4f
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.math.cos
import kotlin.math.sin
import kotlin.reflect.KClass

@Entry(
    "pre_rotation_data",
    "Rotation applied before other transformations",
    Colors.RED,
    "icon-park-outline:rotation-one"
)
@Tags("pre_rotation_data")
class PreRotationData(
    override val id: String = "",
    override val name: String = "",
    val rotation: Var<Vector> = ConstVar(Vector.ZERO),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : DisplayEntityData<PreRotationProperty> {
    override fun type(): KClass<PreRotationProperty> = PreRotationProperty::class

    override fun build(player: Player): PreRotationProperty =
        PreRotationProperty(rotation.get(player).toQuaternion())
}


data class PreRotationProperty(val quaternion: Quaternion4f) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<PreRotationProperty>(
        PreRotationProperty::class,
        PreRotationProperty(Quaternion4f(0.0f, 0.0f, 0.0f, 1.0f))
    )
}

@Entry(
    "post_rotation_data",
    "Rotation applied after other transformations",
    Colors.RED,
    "icon-park-outline:rotation-one"
)
@Tags("post_rotation_data")
class PostRotationData(
    override val id: String = "",
    override val name: String = "",
    val rotation: Var<Vector> = ConstVar(Vector.ZERO),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : DisplayEntityData<PostRotationProperty> {
    override fun type(): KClass<PostRotationProperty> = PostRotationProperty::class

    override fun build(player: Player): PostRotationProperty =
        PostRotationProperty(rotation.get(player).toQuaternion())
}

data class PostRotationProperty(val quaternion: Quaternion4f) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<PostRotationProperty>(
        PostRotationProperty::class,
        PostRotationProperty(Quaternion4f(0.0f, 0.0f, 0.0f, 1.0f))
    )
}

/**
 * Converts the XYZ rotation to a Quaternion.
 * @return Quaternionf representing the rotation
 */
fun Vector.toQuaternion(): Quaternion4f {
    // Convert to radians
    val xRad = Math.toRadians(x).toFloat()
    val yRad = Math.toRadians(y).toFloat()
    val zRad = Math.toRadians(z).toFloat()

    // Calculate half angles
    val cx = cos(xRad * 0.5f)
    val sx = sin(xRad * 0.5f)
    val cy = cos(yRad * 0.5f)
    val sy = sin(yRad * 0.5f)
    val cz = cos(zRad * 0.5f)
    val sz = sin(zRad * 0.5f)

    // Calculate quaternion components
    return Quaternion4f(
        sx * cy * cz - cx * sy * sz,
        cx * sy * cz + sx * cy * sz,
        cx * cy * sz - sx * sy * cz,
        cx * cy * cz + sx * sy * sz,
    )
}

fun applyPreRotationData(entity: WrapperEntity, rotation: PreRotationProperty) {
    entity.metas {
        meta<AbstractDisplayMeta> { leftRotation = rotation.quaternion }
        error("Could not apply TranslationData to ${entity.entityType} entity.")
    }
}

fun applyPostRotationData(entity: WrapperEntity, rotation: PostRotationProperty) {
    entity.metas {
        meta<AbstractDisplayMeta> { rightRotation = rotation.quaternion }
        error("Could not apply TranslationData to ${entity.entityType} entity.")
    }
}