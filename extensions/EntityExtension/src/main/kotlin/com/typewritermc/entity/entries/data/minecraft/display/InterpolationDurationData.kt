package com.typewritermc.entity.entries.data.minecraft.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.utils.toTicks
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.time.Duration
import java.util.*
import kotlin.reflect.KClass

@Entry("interpolation_duration_data", "Interpolation duration of a Display.", Colors.RED, "mdi:timeline-clock")
@Tags("interpolation_duration_data")
class InterpolationDurationData(
    override val id: String = "",
    override val name: String = "",
    val duration: Duration = Duration.ZERO,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : DisplayEntityData<InterpolationDurationProperty> {
    override fun type(): KClass<InterpolationDurationProperty> = InterpolationDurationProperty::class

    override fun build(player: Player): InterpolationDurationProperty =
        InterpolationDurationProperty(duration)
}

data class InterpolationDurationProperty(val duration: Duration) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<InterpolationDurationProperty>(
        InterpolationDurationProperty::class,
        InterpolationDurationProperty(Duration.ZERO)
    )
}

fun applyInterpolationDurationData(entity: WrapperEntity, property: InterpolationDurationProperty) {
    entity.metas {
        meta<AbstractDisplayMeta> { positionRotationInterpolationDuration = property.duration.toTicks().toInt() }
        error("Could not apply InterpolationDurationData to ${'$'}{entity.entityType} entity.")
    }
}
