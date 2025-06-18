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

@Entry("pouncing_data", "If the entity is pouncing", Colors.RED, "game-icons:pounce")
@Tags("pouncing_data", "fox_data")
class PouncingData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val pouncing: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<PouncingProperty> {
    override fun type(): KClass<PouncingProperty> = PouncingProperty::class

    override fun build(player: Player): PouncingProperty = PouncingProperty(pouncing)
}

data class PouncingProperty(val pouncing: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<PouncingProperty>(PouncingProperty::class, PouncingProperty(false))
}

fun applyPouncingData(entity: WrapperEntity, property: PouncingProperty) {
    entity.metas {
        meta<FoxMeta> { isPouncing = property.pouncing }
        error("Could not apply PouncingData to ${entity.entityType} entity.")
    }
}
