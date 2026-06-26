package com.typewritermc.entity.entries.data.minecraft.display.text

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.display.TextDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("text_line_width_data", "LineWidth for a TextDisplay.", Colors.RED, "mdi:format-letter-spacing")
@Tags("text_line_width_data")
class TextLineWidthData(
    override val id: String = "",
    override val name: String = "",
    val lineWidth: Int = 0,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : TextDisplayEntityData<LineWidthProperty> {
    override fun type(): KClass<LineWidthProperty> = LineWidthProperty::class

    override fun build(player: Player): LineWidthProperty =
        LineWidthProperty(lineWidth)
}

data class LineWidthProperty(val lineWidth: Int) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<LineWidthProperty>(LineWidthProperty::class)
}

fun applyLineWidthData(entity: WrapperEntity, property: LineWidthProperty) {
    entity.metas {
        meta<TextDisplayMeta> { lineWidth = property.lineWidth }
        error("Could not apply LineWidthData to ${entity.entityType} entity.")
    }
}