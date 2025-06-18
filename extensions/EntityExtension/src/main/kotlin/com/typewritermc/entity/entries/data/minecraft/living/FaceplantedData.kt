package com.typewritermc.entity.entries.data.minecraft.living

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
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

@Entry("faceplanted_data", "If the entity is faceplanted", Colors.RED, "mdi:emoticon-dead")
@Tags("faceplanted_data", "fox_data")
class FaceplantedData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val faceplanted: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<FaceplantedProperty> {
    override fun type(): KClass<FaceplantedProperty> = FaceplantedProperty::class

    override fun build(player: Player): FaceplantedProperty = FaceplantedProperty(faceplanted)
}

data class FaceplantedProperty(val faceplanted: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<FaceplantedProperty>(FaceplantedProperty::class, FaceplantedProperty(false))
}

fun applyFaceplantedData(entity: WrapperEntity, property: FaceplantedProperty) {
    entity.metas {
        meta<FoxMeta> { isFaceplanted = property.faceplanted }
        error("Could not apply FaceplantedData to ${entity.entityType} entity.")
    }
}
