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
    "bee_nectar_data",
    "Whether a bee is nectar",
    Colors.RED,
    "carbon:bee"
)
@Tags("data", "bee_nectar_data", "bee_data")
class BeeNectarData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val nectar: Boolean = false,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<NectarProperty> {
    /**
 * Returns the Kotlin class reference for the nectar property.
 *
 * This method specifies the associated property type for bees' nectar data.
 *
 * @return the KClass instance corresponding to NectarProperty.
 */
override fun type(): KClass<NectarProperty> = NectarProperty::class

    /**
 * Constructs a NectarProperty for this bee.
 *
 * Creates a new NectarProperty initialized with the current nectar status.
 * The player parameter is provided for interface compliance and is not utilized.
 *
 * @param player the player associated with the bee (unused).
 * @return a new NectarProperty reflecting the bee's nectar state.
 */
override fun build(player: Player): NectarProperty = NectarProperty(nectar)
}

data class NectarProperty(val nectar: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<NectarProperty>(NectarProperty::class, NectarProperty(false))
}

/**
 * Applies the nectar status from the given [property] to the metadata of the [entity].
 *
 * This function updates the bee's metadata by setting its nectar state based on [property.nectar]. If the update
 * fails, an error is logged with the entity's type.
 *
 * @param entity The bee entity whose metadata will be updated.
 * @param property The nectar property containing the status to be applied.
 */
fun applyBeeAngryData(entity: WrapperEntity, property: NectarProperty) {
    entity.metas {
        meta<BeeMeta> { setHasNectar(property.nectar) }
        error("Could not apply BeeAngryData to ${entity.entityType} entity.")
    }
}