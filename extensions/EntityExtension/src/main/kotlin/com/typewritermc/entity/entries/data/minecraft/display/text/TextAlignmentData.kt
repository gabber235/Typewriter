package com.typewritermc.entity.entries.data.minecraft.display.text

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
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

@Entry("text_alignment_data", "Align the text in a TextDisplay", Colors.RED, "ci:text-align-center")
@Tags("text_alignment_data")
class TextAlignmentData(
    override val id: String = "",
    override val name: String = "",
    @Default("\"CENTER\"")
    val alignment: TextAlignment = TextAlignment.CENTER,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : TextDisplayEntityData<TextAlignmentProperty> {
    override fun type(): KClass<TextAlignmentProperty> = TextAlignmentProperty::class

    override fun build(player: Player): TextAlignmentProperty = TextAlignmentProperty(alignment)
}

enum class TextAlignment {
    LEFT, CENTER, RIGHT
}

data class TextAlignmentProperty(val alignment: TextAlignment) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<TextAlignmentProperty>(
        TextAlignmentProperty::class,
        TextAlignmentProperty(TextAlignment.CENTER)
    )
}

fun applyTextAlignmentData(entity: WrapperEntity, property: TextAlignmentProperty) {
    entity.metas {
        meta<TextDisplayMeta> {
            isAlignLeft = property.alignment == TextAlignment.LEFT
            isAlignRight = property.alignment == TextAlignment.RIGHT
        }
        error("Could not apply TextAlignmentData to ${entity.entityType} entity.")
    }
}