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
    /**
 * Returns the KClass representing [AngryProperty].
 *
 * This function is used to retrieve the runtime type of the angry property,
 * which is essential for constructing and associating bee angry state data.
 *
 * @return the [KClass] corresponding to [AngryProperty].
 */
override fun type(): KClass<AngryProperty> = AngryProperty::class

    /**
 * Constructs an AngryProperty reflecting the bee's angry state.
 *
 * Although a Player is provided, it is not utilized in this implementation.
 * The method returns an AngryProperty initialized with the current bee anger flag.
 */
override fun build(player: Player): AngryProperty = AngryProperty(angry)
}

data class AngryProperty(val angry: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<AngryProperty>(AngryProperty::class, AngryProperty(false))
}

/**
 * Applies the angry state to a bee entity's metadata.
 *
 * This function updates the bee's metadata by setting its angry status based on the provided property.
 * If the metadata update fails, it throws an exception indicating the inability to apply the angry state
 * to the specified entity type.
 *
 * @param entity the bee entity whose metadata is to be updated.
 * @param property the property holding the angry state to apply.
 * @throws IllegalStateException if the angry state cannot be applied to the entity's metadata.
 */
fun applyBeeAngryData(entity: WrapperEntity, property: AngryProperty) {
    entity.metas {
        meta<BeeMeta> { isAngry = property.angry }
        error("Could not apply BeeAngryData to ${entity.entityType} entity.")
    }
}