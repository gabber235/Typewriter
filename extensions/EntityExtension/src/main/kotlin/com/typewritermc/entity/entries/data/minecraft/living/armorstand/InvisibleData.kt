package com.typewritermc.entity.entries.data.minecraft.living.armorstand

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.other.ArmorStandMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("invisible_data", "Whether the armor stand itself is invisible", Colors.RED, "mdi:mirror-variant")
@Tags("invisible_data", "armor_stand_data")
class InvisibleData(
    override val id: String = "",
    override val name: String = "",
    val invisible: Boolean = false,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<InvisibleProperty> {
    override fun type(): KClass<InvisibleProperty> = InvisibleProperty::class

    override fun build(player: Player): InvisibleProperty = InvisibleProperty(invisible)
}

data class InvisibleProperty(val invisible: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<InvisibleProperty>(InvisibleProperty::class, InvisibleProperty(false))
}

fun applyInvisibleData(entity: WrapperEntity, property: InvisibleProperty) {
    entity.metas {
        meta<ArmorStandMeta> { isInvisible = property.invisible }
        error("Could not apply InvisibleData to ${entity.entityType} entity.")
    }
}