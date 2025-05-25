package com.typewritermc.entity.entries.data.minecraft.living.scheep

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.passive.SheepMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("sheared_data", "If the entity is sheared.", Colors.RED, "fa6-solid:scissors")
@Tags("sheared_data", "sheep_data")
class ShearedData(
    override val id: String = "",
    override val name: String = "",
    val sheared: Boolean = false,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<ShearedProperty> {
    override fun type(): KClass<ShearedProperty> = ShearedProperty::class

    override fun build(player: Player): ShearedProperty = ShearedProperty(sheared)
}

data class ShearedProperty(val sheared: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<ShearedProperty>(ShearedProperty::class, ShearedProperty(false))
}

fun applySheepShearedData(entity: WrapperEntity, property: ShearedProperty) {
    entity.metas {
        meta<SheepMeta> { isSheared = property.sheared }
        error("Could not apply ShearedData to ${entity.entityType} entity.")
    }
}