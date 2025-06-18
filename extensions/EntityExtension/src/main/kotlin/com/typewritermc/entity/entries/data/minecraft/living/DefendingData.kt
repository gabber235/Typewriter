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

@Entry("defending_data", "If the entity is defending", Colors.RED, "game-icons:shield")
@Tags("defending_data", "fox_data")
class DefendingData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val defending: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<DefendingProperty> {
    override fun type(): KClass<DefendingProperty> = DefendingProperty::class

    override fun build(player: Player): DefendingProperty = DefendingProperty(defending)
}

data class DefendingProperty(val defending: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<DefendingProperty>(DefendingProperty::class, DefendingProperty(false))
}

fun applyDefendingData(entity: WrapperEntity, property: DefendingProperty) {
    entity.metas {
        meta<FoxMeta> { isDefending = property.defending }
        error("Could not apply DefendingData to ${entity.entityType} entity.")
    }
}
