package com.typewritermc.entity.entries.data.minecraft.living.wolf

import com.github.retrooper.packetevents.protocol.entity.wolfvariant.WolfVariant
import com.github.retrooper.packetevents.protocol.entity.wolfvariant.WolfVariants
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.tameable.WolfMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("wolf_variant_data", "The variant of a wolf.", Colors.RED, "game-icons:sitting-dog")
@Tags("wolf_data", "wolf_variant_data")
class WolfVariantData (
    override val id: String = "",
    override val name: String = "",
    val wolfVariant: WolfVariantEnum = WolfVariantEnum.PALE,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<WolfVariantProperty> {
    override fun type(): KClass<WolfVariantProperty> = WolfVariantProperty::class

    override fun build(player: Player): WolfVariantProperty = WolfVariantProperty(wolfVariant)
}

data class WolfVariantProperty(val wolfVariant: WolfVariantEnum) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<WolfVariantProperty>(WolfVariantProperty::class)
}

fun applyWolfVariantData(entity: WrapperEntity, property: WolfVariantProperty) {
    entity.metas {
        meta<WolfMeta> { variant = property.wolfVariant.variant }
        error("Could not apply WolfVariantData to ${entity.entityType} entity.")
    }
}

enum class WolfVariantEnum(val variant: WolfVariant) {
    PALE(WolfVariants.PALE),
    SPOTTED(WolfVariants.SPOTTED),
    SNOWY(WolfVariants.SNOWY),
    BLACK(WolfVariants.BLACK),
    ASHEN(WolfVariants.ASHEN),
    RUSTY(WolfVariants.RUSTY),
    WOODS(WolfVariants.WOODS),
    CHESTNUT(WolfVariants.CHESTNUT),
    STRIPED(WolfVariants.STRIPED);
}
