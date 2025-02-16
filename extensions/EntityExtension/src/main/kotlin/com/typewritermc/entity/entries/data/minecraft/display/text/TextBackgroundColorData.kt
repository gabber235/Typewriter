package com.typewritermc.entity.entries.data.minecraft.display.text

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.extension.annotations.WithAlpha
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.utils.Color
import me.tofaa.entitylib.meta.display.TextDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry(
    "background_color_data",
    "Background color for a TextDisplay.",
    Colors.RED,
    "fluent:video-background-effect-32-filled"
)
@Tags("background_color_data")
class TextBackgroundColorData(
    override val id: String = "",
    override val name: String = "",
    @WithAlpha
    val color: Color = Color.BLACK_BACKGROUND,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : TextDisplayEntityData<BackgroundColorProperty> {
    override fun type(): KClass<BackgroundColorProperty> = BackgroundColorProperty::class

    override fun build(player: Player): BackgroundColorProperty =
        BackgroundColorProperty(color)
}

data class BackgroundColorProperty(val color: Color) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<BackgroundColorProperty>(BackgroundColorProperty::class)
}

fun applyBackgroundColorData(entity: WrapperEntity, property: BackgroundColorProperty) {
    entity.metas {
        meta<TextDisplayMeta> { backgroundColor = property.color.color }
        error("Could not apply BackgroundColorData to ${entity.entityType} entity.")
    }
}
