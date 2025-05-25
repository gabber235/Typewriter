package com.typewritermc.entity.entries.data.minecraft.living.raider

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.monster.raider.RaiderMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry(
    "celebrating_data",
    "Whether an entity is celebrating",
    Colors.GREEN,
    "mdi:party-popper"
)
@Tags("celebrating_data", "raider_data")
class CelebratingData(
    override val id: String = "",
    override val name: String = "",
    val celebrating: Boolean = false,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<CelebratingProperty> {
    override fun type(): KClass<CelebratingProperty> = CelebratingProperty::class

    override fun build(player: Player): CelebratingProperty = CelebratingProperty(celebrating)
}

data class CelebratingProperty(val celebrating: Boolean) : EntityProperty {
    companion object :
        SinglePropertyCollectorSupplier<CelebratingProperty>(CelebratingProperty::class, CelebratingProperty(false))
}

fun applyCelebratingData(entity: WrapperEntity, property: CelebratingProperty) {
    entity.metas {
        meta<RaiderMeta> { isCelebrating = property.celebrating }
        error("Could not apply CelebratingData to ${entity.entityType} entity.")
    }
}
