package com.typewritermc.entity.entries.entity.minecraft

import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.SimpleEntityDefinition
import com.typewritermc.engine.paper.entry.entity.SimpleEntityInstance
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.data.minecraft.display.applyDisplayEntityData
import com.typewritermc.entity.entries.data.minecraft.display.text.*
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import me.tofaa.entitylib.meta.display.TextDisplayMeta
import org.bukkit.entity.Player

@Entry("text_display_definition", "A text display entity", Colors.ORANGE, "material-symbols:text-ad-rounded")
@Tags("text_display_definition")
/**
 * The `TextDisplayDefinition` class is an entry that represents a text display entity.
 *
 * ## How could this be used?
 * This could be used to create an entity that displays text.
 */
class TextDisplayDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "display_data", "lines", "text_display_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = TextDisplayEntity(player)
}

@Entry(
    "text_display_instance",
    "An instance of a text display entity",
    Colors.YELLOW,
    "material-symbols:text-ad-rounded"
)
class TextDisplayInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<TextDisplayDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "display_data", "lines", "text_display_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

open class TextDisplayEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.TEXT_DISPLAY,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is LinesProperty -> entity.meta<TextDisplayMeta>(preventNotification = true) {
                text = property.lines.asMini()
            }

            is BackgroundColorProperty -> applyBackgroundColorData(entity, property)
            is TextOpacityProperty -> applyTextOpacityData(entity, property)
            is LineWidthProperty -> applyLineWidthData(entity, property)
            is TextShadowProperty -> applyShadowData(entity, property)
            is SeeThroughProperty -> applySeeThroughData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyDisplayEntityData(entity, property)) return
    }
}