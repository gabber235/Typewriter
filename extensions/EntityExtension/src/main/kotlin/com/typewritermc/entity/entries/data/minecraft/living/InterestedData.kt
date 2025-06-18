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

@Entry("interested_data", "If the entity is interested", Colors.RED, "mdi:eye")
@Tags("interested_data", "fox_data")
class InterestedData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val interested: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<InterestedProperty> {
    override fun type(): KClass<InterestedProperty> = InterestedProperty::class

    override fun build(player: Player): InterestedProperty = InterestedProperty(interested)
}

data class InterestedProperty(val interested: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<InterestedProperty>(InterestedProperty::class, InterestedProperty(false))
}

fun applyInterestedData(entity: WrapperEntity, property: InterestedProperty) {
    entity.metas {
        meta<FoxMeta> { isInterested = property.interested }
        error("Could not apply InterestedData to ${entity.entityType} entity.")
    }
}
