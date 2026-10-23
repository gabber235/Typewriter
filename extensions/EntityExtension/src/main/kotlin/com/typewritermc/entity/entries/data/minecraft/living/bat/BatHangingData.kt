package com.typewritermc.entity.entries.data.minecraft.living.bat

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.BatMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("bat_hanging_data", "Whether a bat is hanging upside down", Colors.RED, "mdi:bat")
@Tags("data", "bat_hanging_data", "bat_data")
/**
 * The `BatHangingData` class is an entry that makes a bat hang upside down instead of flying.
 *
 * ## How could this be used?
 * This could be used for a bat that sleeps on a cave ceiling until the player gets close.
 * The client pulls a hanging bat up against the underside of the block above it,
 * so place the bat in the air block directly below the ceiling.
 */
class BatHangingData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val hanging: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<HangingProperty> {
    override fun type(): KClass<HangingProperty> = HangingProperty::class

    override fun build(player: Player): HangingProperty = HangingProperty(hanging)
}

data class HangingProperty(val hanging: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<HangingProperty>(HangingProperty::class, HangingProperty(false))
}

fun applyBatHangingData(entity: WrapperEntity, property: HangingProperty) {
    entity.metas {
        meta<BatMeta> { isHanging = property.hanging }
        error("Could not apply BatHangingData to ${entity.entityType} entity.")
    }
}
