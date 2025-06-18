package com.typewritermc.entity.entries.data.minecraft.living.fox

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.FoxMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("fox_type_data", "The type of the fox", Colors.RED, "mdi:fox")
@Tags("fox_type_data", "fox_data")
class FoxTypeData(
    override val id: String = "",
    override val name: String = "",
    val foxType: FoxMeta.Type = FoxMeta.Type.RED,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<FoxTypeProperty> {
    override fun type(): KClass<FoxTypeProperty> = FoxTypeProperty::class

    override fun build(player: Player): FoxTypeProperty = FoxTypeProperty(foxType)
}

data class FoxTypeProperty(val foxType: FoxMeta.Type) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<FoxTypeProperty>(FoxTypeProperty::class)
}

fun applyFoxTypeData(entity: WrapperEntity, property: FoxTypeProperty) {
    entity.metas {
        meta<FoxMeta> { type = property.foxType }
        error("Could not apply FoxTypeData to ${entity.entityType} entity.")
    }
}
