package com.typewritermc.entity.entries.data.minecraft.living.shulker


import com.github.retrooper.packetevents.protocol.world.Direction
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.golem.ShulkerMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("attach_face_data", "The face that the shulker attaches to", Colors.RED, "fa6-solid:compass")
@Tags("attach_face_data", "shulker_data")
class AttachFaceData(
    override val id: String = "",
    override val name: String = "",
    val direction: Direction = Direction.DOWN,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<AttachFaceProperty> {
    override fun type(): KClass<AttachFaceProperty> = AttachFaceProperty::class

    override fun build(player: Player): AttachFaceProperty = AttachFaceProperty(direction)
}

data class AttachFaceProperty(val direction: Direction) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<AttachFaceProperty>(AttachFaceProperty::class)
}

fun applyAttachFaceData(entity: WrapperEntity, property: AttachFaceProperty) {
    entity.metas {
        meta<ShulkerMeta> { attachFace = property.direction }
        error("Could not apply AttachFaceData to ${entity.entityType} entity.")
    }
}