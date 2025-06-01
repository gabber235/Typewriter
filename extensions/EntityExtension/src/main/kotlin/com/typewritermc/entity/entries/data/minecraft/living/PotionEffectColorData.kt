package com.typewritermc.entity.entries.data.minecraft.living

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.WithAlpha
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.LivingEntityData
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.utils.Color
import me.tofaa.entitylib.meta.types.LivingEntityMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("potion_effect_color_data", "The color of the potion effect particles", Colors.RED, "bi:droplet-fill")
class PotionEffectColorData(
    override val id: String = "",
    override val name: String = "",
    @WithAlpha
    val color: Color = Color(0),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LivingEntityData<PotionEffectColorProperty> {
    override fun type(): KClass<PotionEffectColorProperty> = PotionEffectColorProperty::class

    override fun build(player: Player): PotionEffectColorProperty = PotionEffectColorProperty(color)
}

data class PotionEffectColorProperty(val color: Color) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<PotionEffectColorProperty>(PotionEffectColorProperty::class)
}

fun applyPotionEffectColorData(entity: WrapperEntity, property: PotionEffectColorProperty) {
    entity.metas {
        meta<LivingEntityMeta> { potionEffectColor = property.color.color }
        error("Could not apply PotionEffectColorData to ${entity.entityType} entity.")
    }
}