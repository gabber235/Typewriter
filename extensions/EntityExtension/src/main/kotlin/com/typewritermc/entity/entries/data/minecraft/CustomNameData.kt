package com.typewritermc.entity.entries.data.minecraft

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityData
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.utils.asMini
import me.tofaa.entitylib.meta.EntityMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("custom_name_data", "The custom name of the entity", Colors.RED, "cbi:abc")

class CustomNameData(
    override val id: String = "",
    override val name: String = "",
    @Help("The custom name of the entity.")
    val customName: Var<String> = ConstVar(""),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : GenericEntityData<CustomNameProperty> {
    override fun type(): KClass<CustomNameProperty> = CustomNameProperty::class

    override fun build(player: Player): CustomNameProperty = CustomNameProperty(customName.get(player))
}

/**
 * The name an entity carries, as the custom name data set it.
 *
 * A blank name means the entity was not given one and falls back to the name on its definition.
 */
data class CustomNameProperty(val customName: String) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<CustomNameProperty>(CustomNameProperty::class)
}

fun applyCustomNameData(entity: WrapperEntity, property: CustomNameProperty) {
    entity.metas {
        meta<EntityMeta> {
            if (property.customName.isEmpty()) {
                isCustomNameVisible = false
                customName = null
                return@meta
            }
            isCustomNameVisible = true
            customName = property.customName.asMini()
        }
        error("Could not apply CustomNameData to ${entity.entityType} entity.")
    }
}