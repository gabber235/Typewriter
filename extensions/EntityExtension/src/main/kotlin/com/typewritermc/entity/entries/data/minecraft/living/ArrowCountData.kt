package com.typewritermc.entity.entries.data.minecraft.living

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.LivingEntityData
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.types.LivingEntityMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("arrow_count_data", "The amount of arrows in a entity", Colors.RED, "mdi:arrow-projectile")
class ArrowCountData(
    override val id: String = "",
    override val name: String = "",
    val arrowCount: Int = 0,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LivingEntityData<ArrowCountProperty> {
    override fun type(): KClass<ArrowCountProperty> = ArrowCountProperty::class

    override fun build(player: Player): ArrowCountProperty = ArrowCountProperty(arrowCount)
}

data class ArrowCountProperty(val arrowCount: Int) : EntityProperty {
    companion object :
        SinglePropertyCollectorSupplier<ArrowCountProperty>(ArrowCountProperty::class, ArrowCountProperty(0))
}

fun applyArrowCountData(entity: WrapperEntity, property: ArrowCountProperty) {
    entity.metas {
        meta<LivingEntityMeta> { arrowCount = property.arrowCount }
        error("Could not apply ArrowCountData to ${entity.entityType} entity.")
    }
}