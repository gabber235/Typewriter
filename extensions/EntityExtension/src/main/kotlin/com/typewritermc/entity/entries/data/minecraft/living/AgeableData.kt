package com.typewritermc.entity.entries.data.minecraft.living

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.monster.ZoglinMeta
import me.tofaa.entitylib.meta.mobs.monster.piglin.PiglinMeta
import me.tofaa.entitylib.meta.mobs.monster.zombie.ZombieMeta
import me.tofaa.entitylib.meta.types.AgeableMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("ageable_data", "An ageable data", Colors.RED, "material-symbols:child-care")
@Tags("ageable_data", "zoglin_data", "zombie_data")
class AgeableData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val baby: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<AgeableProperty> {
    override fun type(): KClass<AgeableProperty> = AgeableProperty::class

    override fun build(player: Player): AgeableProperty = AgeableProperty(baby)
}

data class AgeableProperty(val baby: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<AgeableProperty>(AgeableProperty::class, AgeableProperty(false))
}

fun applyAgeableData(entity: WrapperEntity, property: AgeableProperty) {
    entity.metas {
        meta<AgeableMeta> { isBaby = property.baby }
        meta<ZoglinMeta> { isBaby = property.baby }
        meta<ZombieMeta> { isBaby = property.baby }
        meta<PiglinMeta> { isBaby = property.baby }
        error("Could not apply AgeableData to ${entity.entityType} entity.")
    }
}