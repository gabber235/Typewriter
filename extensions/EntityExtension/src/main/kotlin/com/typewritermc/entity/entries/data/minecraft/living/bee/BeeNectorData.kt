package com.typewritermc.entity.entries.data.minecraft.living.bee

import com.typewritermc.core.books.pages.Colors
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
    "bee_nectar_data",
    "Whether a bee is nectar",
    Colors.RED,
    "carbon:bee"
)
@Tags("data", "bee_nectar_data", "bee_data")
class BeeNectarData(
    override val id: String = "",
    override val name: String = "",
    val nectar: Boolean = false,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<NectarProperty> {
    override fun type(): KClass<NectarProperty> = NectarProperty::class

    override fun build(player: Player): NectarProperty = NectarProperty(nectar)
}

data class NectarProperty(val nectar: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<NectarProperty>(NectarProperty::class, NectarProperty(false))
}

fun applyBeeAngryData(entity: WrapperEntity, property: NectarProperty) {
    entity.metas {
        meta<BeeMeta> { setHasNectar(property.nectar) }
        error("Could not apply BeeAngryData to ${entity.entityType} entity.")
    }
}