package com.typewritermc.entity.entries.entity.custom

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.data.minecraft.display.BillboardConstraintProperty
import com.typewritermc.entity.entries.data.minecraft.display.text.*
import com.typewritermc.entity.entries.entity.minecraft.TextDisplayEntity
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta.BillboardConstraints
import org.bukkit.entity.Player

@Entry("hologram", "Simplified text display entity", Colors.YELLOW, "material-symbols:text-ad-rounded")
/**
 * The `Hologram` entry is a one-entry hologram entity.
 *
 * It wraps a TextDisplay entity and pre-fills common hologram settings,
 * while still allowing advanced data overrides.
 */
class Hologram(
    override val id: String = "",
    override val name: String = "",
    @Help("Text shown in hologram. Supports placeholders and MiniMessage.")
    @MultiLine
    @Colored
    @Placeholder
    val text: Var<String> = ConstVar(""),
    @Help("Where hologram spawns.")
    override val spawnLocation: Position = Position.ORIGIN,
    @Default("\"CENTER\"")
    val billboardConstraint: BillboardConstraints = BillboardConstraints.CENTER,
    val shadow: Boolean = false,
    val seeThrough: Boolean = false,
    @WithAlpha
    @Default("1073741824") // 0x40000000
    val backgroundColor: Color = Color.BLACK_BACKGROUND,
    @Min(-1)
    @Max(127)
    val opacity: Int = -1,
    val lineWidth: Int = 200,
    @Default("\"CENTER\"")
    val textAlignment: TextAlignment = TextAlignment.CENTER,
    @OnlyTags("generic_entity_data", "display_data", "text_display_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityInstance, SimpleEntityDefinition {

    override val definition: Ref<out SimpleEntityDefinition>
        get() = ref()

    override val displayName: Var<String>
        get() = ConstVar("")

    override val sound: Var<Sound>
        get() = ConstVar(Sound.EMPTY)

    override val activity: Ref<out EntityActivityEntry>
        get() = emptyRef()

    override suspend fun display(): AudienceFilter {
        val baseSuppliers = data.withPriority().map { it.first as PropertySupplier<*> to it.second }

        return SharedAudienceEntityDisplay(
            ref(),
            this,
            IdleActivity,
            baseSuppliers,
            spawnLocation,
            ConstVar(entityShowRange),
        )
    }

    override fun create(player: Player): FakeEntity {
        return HologramEntity(
            player,
            text,
            billboardConstraint,
            shadow,
            seeThrough,
            backgroundColor,
            opacity,
            lineWidth,
            textAlignment,
        )
    }
}

private class HologramEntity(
    player: Player,
    val text: Var<String>,
    billboardConstraint: BillboardConstraints,
    shadow: Boolean,
    seeThrough: Boolean,
    backgroundColor: Color,
    opacity: Int,
    lineWidth: Int,
    textAlignment: TextAlignment,
) : TextDisplayEntity(player) {
    init {
        consumeProperties(
            BillboardConstraintProperty(billboardConstraint),
            TextShadowProperty(shadow),
            SeeThroughProperty(seeThrough),
            BackgroundColorProperty(backgroundColor),
            TextOpacityProperty(opacity.toByte()),
            LineWidthProperty(lineWidth),
            TextAlignmentProperty(textAlignment),
            LinesProperty(text.get(player).parsePlaceholders(player)),
        )
    }

    override fun tick() {
        super.tick()
        consumeProperties(LinesProperty(text.get(player).parsePlaceholders(player)))
    }
}