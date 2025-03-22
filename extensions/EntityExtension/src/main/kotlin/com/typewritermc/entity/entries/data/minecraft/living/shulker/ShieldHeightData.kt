package com.typewritermc.entity.entries.data.minecraft.living.shulker

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.golem.ShulkerMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("shield_height_data", "The height of the shulker's shield", Colors.RED, "fa6-solid:shield")
@Tags("shield_height_data", "shulker_data")
class ShieldHeightData(
    override val id: String = "",
    override val name: String = "",
    @Help("The height of the shulker's shield (0-100)")
    @Min(0)
    @Max(100)
    val height: Int = 0,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<ShieldHeightProperty> {
    override fun type(): KClass<ShieldHeightProperty> = ShieldHeightProperty::class

    override fun build(player: Player): ShieldHeightProperty = ShieldHeightProperty(height)
}

data class ShieldHeightProperty(val height: Int) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<ShieldHeightProperty>(ShieldHeightProperty::class)
}

fun applyShieldHeightData(entity: WrapperEntity, property: ShieldHeightProperty) {
    entity.metas {
        meta<ShulkerMeta> { shieldHeight = property.height.toByte() }
        error("Could not apply ShulkerShieldHeightData to ${entity.entityType} entity.")
    }
}