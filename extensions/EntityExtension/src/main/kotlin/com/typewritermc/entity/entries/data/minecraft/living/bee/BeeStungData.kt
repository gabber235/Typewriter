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
    "bee_stung_data",
    "Whether a bee is stung",
    Colors.RED,
    "carbon:bee"
)
@Tags("data", "bee_stung_data", "bee_data")
class BeeStungData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val stung: Boolean = false,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<StungProperty> {
    /**
 * Returns the Kotlin class reference for the bee stung property.
 *
 * This method provides the type information required for associating the proper
 * metadata with bee entities.
 *
 * @return The KClass reference for StungProperty.
 */
override fun type(): KClass<StungProperty> = StungProperty::class

    /**
 * Builds a new [StungProperty] instance reflecting the bee's stung state.
 *
 * Note that the provided [Player] parameter is not used in this implementation.
 *
 * @return a new [StungProperty] with its stung value set according to the current data.
 */
override fun build(player: Player): StungProperty = StungProperty(stung)
}

data class StungProperty(val stung: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<StungProperty>(StungProperty::class, StungProperty(false))
}

/**
 * Applies the bee stung state to the entity's metadata.
 *
 * Updates the [BeeMeta] metadata of the given entity by setting its stung flag according to the provided [StungProperty].
 * If the metadata update fails, an error is thrown that includes the entity's type.
 *
 * @param entity The target entity to which the stung data will be applied.
 * @param property The stung property containing the stung state to set on the entity.
 */
fun applyBeeStungData(entity: WrapperEntity, property: StungProperty) {
    entity.metas {
        meta<BeeMeta> { setHasStung(property.stung) }
        error("Could not apply BeeAngryData to ${entity.entityType} entity.")
    }
}