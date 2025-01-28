package com.typewritermc.entity.entries.data.minecraft

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityData
import org.bukkit.entity.Player
import java.util.Optional
import kotlin.reflect.KClass

@Entry("speed_data", "Change the walking speed of an entity", Colors.RED, "material-symbols:speed")
@Tags("speed_data")
class SpeedData(
    override val id: String = "",
    override val name: String = "",
    @Default("0.2085")
    val speed: Float = 0.2085f,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : GenericEntityData<SpeedProperty> {
    override fun type(): KClass<SpeedProperty> = SpeedProperty::class

    override fun build(player: Player): SpeedProperty = SpeedProperty(speed)
}

data class SpeedProperty(val speed: Float = 0.2085f) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<SpeedProperty>(SpeedProperty::class, SpeedProperty())
}
