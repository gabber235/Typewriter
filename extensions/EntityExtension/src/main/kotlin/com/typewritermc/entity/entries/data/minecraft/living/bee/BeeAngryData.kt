package com.typewritermc.entity.entries.data.minecraft.living.bee

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.BeeMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry(
    "bee_angry_data",
    "Whether a bee is angry",
    Colors.RED,
    "carbon:bee"
)
@Tags("data", "bee_angry_data", "bee_data")
class BeeAngryData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val angry: Boolean = false,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<AngryProperty> {
    override fun type(): KClass<AngryProperty> = AngryProperty::class

    override fun build(player: Player): AngryProperty = AngryProperty(angry)
}

data class AngryProperty(val angry: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<AngryProperty>(AngryProperty::class, AngryProperty(false))
}

fun applyBeeAngryData(entity: WrapperEntity, property: AngryProperty) {
    entity.metas {
        meta<BeeMeta> { isAngry = property.angry }
        error("Could not apply BeeAngryData to ${entity.entityType} entity.")
    }
}