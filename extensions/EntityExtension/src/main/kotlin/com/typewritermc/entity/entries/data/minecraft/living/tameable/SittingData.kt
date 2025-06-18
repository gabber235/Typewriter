package com.typewritermc.entity.entries.data.minecraft.living.tameable

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.FoxMeta
import me.tofaa.entitylib.meta.types.TameableMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("sitting_data", "Have a tameable entity sit", Colors.RED, "pepicons-pop:folding-stool")
@Tags("sitting_data", "fox_data")
class SittingData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val sitting: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : TameableData<SittingProperty> {
    override fun type(): KClass<SittingProperty> = SittingProperty::class
    override fun build(player: Player): SittingProperty = SittingProperty(sitting)
}

data class SittingProperty(val sitting: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<SittingProperty>(SittingProperty::class, SittingProperty(false))
}

fun applySittingData(entity: WrapperEntity, property: SittingProperty) {
    entity.metas {
        meta<TameableMeta> { isSitting = property.sitting }
        meta<FoxMeta> { isSitting = property.sitting }
        error("Could not apply SittingData to ${entity.entityType} entity.")
    }
}

