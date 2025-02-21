package com.typewritermc.entity.entries.data.minecraft.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Max
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("brightness_data", "Brightness of a Display.", Colors.RED, "mdi:lightbulb-on-outline")
@Tags("brightness_data")
class BrightnessData(
    override val id: String = "",
    override val name: String = "",
    @Min(-1)
    @Max(15)
    val blockLight: Int = -1,
    @Min(-1)
    @Max(15)
    val skyLight: Int = -1,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : DisplayEntityData<BrightnessProperty> {
    override fun type(): KClass<BrightnessProperty> = BrightnessProperty::class

    override fun build(player: Player): BrightnessProperty = BrightnessProperty(blockLight, skyLight)
}


data class BrightnessProperty(val blockLight: Int, val skyLight: Int) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<BrightnessProperty>(
        BrightnessProperty::class,
        BrightnessProperty(-1, -1)
    )
}

fun applyBrightnessData(entity: WrapperEntity, property: BrightnessProperty) {
    entity.metas {
        meta<AbstractDisplayMeta> { brightnessOverride = (property.blockLight shl 4 or property.skyLight shl 20) }
        error("Could not apply BrightnessData to ${entity.entityType} entity.")
    }
}