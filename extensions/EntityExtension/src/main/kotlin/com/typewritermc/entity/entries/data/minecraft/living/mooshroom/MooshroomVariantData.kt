package com.typewritermc.entity.entries.data.minecraft.living.mooshroom

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.passive.MooshroomMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("mooshroom_variant_data", "Mooshroom variant data", Colors.RED, "fa6-solid:mushroom")
@Tags("mooshroom_variant_data", "mooshroom_data")
class MooshroomVariantData(
    override val id: String = "",
    override val name: String = "",
    val variant: MooshroomMeta.Variant = MooshroomMeta.Variant.RED,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<MooshroomVariantProperty> {
    override fun type(): KClass<MooshroomVariantProperty> = MooshroomVariantProperty::class

    override fun build(player: Player): MooshroomVariantProperty = MooshroomVariantProperty(variant)
}

data class MooshroomVariantProperty(
    val variant: MooshroomMeta.Variant,
) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<MooshroomVariantProperty>(MooshroomVariantProperty::class)
}

fun applyMooshroomVariantData(entity: WrapperEntity, property: MooshroomVariantProperty) {
    entity.metas {
        meta<MooshroomMeta> {
            this.variant = property.variant
        }
        error("Could not apply MooshroomVariantData to ${entity.entityType} entity.")
    }
}