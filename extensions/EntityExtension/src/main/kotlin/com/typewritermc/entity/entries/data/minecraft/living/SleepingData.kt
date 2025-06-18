package com.typewritermc.entity.entries.data.minecraft.living

import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.EntityMeta
import me.tofaa.entitylib.meta.mobs.FoxMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("sleeping_data", "If the entity is sleeping", Colors.RED, "mdi:bed")
@Tags("sleeping_data", "fox_data")
class SleepingData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val sleeping: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<SleepingProperty> {
    override fun type(): KClass<SleepingProperty> = SleepingProperty::class

    override fun build(player: Player): SleepingProperty = SleepingProperty(sleeping)
}

data class SleepingProperty(val sleeping: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<SleepingProperty>(SleepingProperty::class, SleepingProperty(false))
}

fun applySleepingData(entity: WrapperEntity, property: SleepingProperty) {
    entity.metas {
        meta<EntityMeta> { pose = if (property.sleeping) EntityPose.SLEEPING else EntityPose.STANDING }
        meta<FoxMeta> { isSleeping = property.sleeping }
        error("Could not apply SleepingData to ${entity.entityType} entity.")
    }
}

