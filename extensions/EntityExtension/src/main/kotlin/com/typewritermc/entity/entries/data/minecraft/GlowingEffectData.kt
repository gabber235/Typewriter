package com.typewritermc.entity.entries.data.minecraft

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityData
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.Color
import me.tofaa.entitylib.meta.EntityMeta
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import me.tofaa.entitylib.wrapper.WrapperPlayer
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import net.kyori.adventure.text.format.TextColor
import org.bukkit.Bukkit
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("glowing_effect_data", "If the entity is glowing", Colors.RED, "bi:lightbulb-fill")
@Tags("glowing_effect_data")
class GlowingEffectData(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the entity is glowing.")
    @Default("true")
    val glowing: Boolean = true,
    val color: Color = Color.WHITE,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : GenericEntityData<GlowingEffectProperty> {
    override fun type(): KClass<GlowingEffectProperty> = GlowingEffectProperty::class

    override fun build(player: Player): GlowingEffectProperty = GlowingEffectProperty(glowing, color)
}

data class GlowingEffectProperty(val glowing: Boolean = false, val color: Color) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<GlowingEffectProperty>(
        GlowingEffectProperty::class,
        GlowingEffectProperty(false, Color.WHITE)
    )
}

fun applyGlowingEffectData(entity: WrapperEntity, property: GlowingEffectProperty) {
    val info = WrapperPlayServerTeams.ScoreBoardTeamInfo(
        Component.empty(),
        null,
        null,
        WrapperPlayServerTeams.NameTagVisibility.NEVER,
        WrapperPlayServerTeams.CollisionRule.NEVER,
        NamedTextColor.nearestTo(TextColor.color(property.color.color)),
        WrapperPlayServerTeams.OptionData.NONE
    )
    if (property.glowing && entity.entityMeta is AbstractDisplayMeta) {
        entity.metas {
            meta<AbstractDisplayMeta> { glowColorOverride = property.color.color }
            error("Could not apply GlowingEffectData to ${entity.entityType} entity.")
        }
    } else if (entity is WrapperPlayer) {
        entity.viewers.firstOrNull()?.let { viewerUuid ->
            Bukkit.getPlayer(viewerUuid)?.let { player ->
                WrapperPlayServerTeams(
                    "typewriter-${entity.entityId}",
                    WrapperPlayServerTeams.TeamMode.UPDATE,
                    info
                ) sendPacketTo player
            }
        }
    } else {
        entity.viewers.firstOrNull()?.let { viewerUuid ->
            Bukkit.getPlayer(viewerUuid)?.let { player ->
                WrapperPlayServerTeams(
                    "typewriter-${entity.entityId}",
                    WrapperPlayServerTeams.TeamMode.CREATE,
                    info,
                    entity.uuid.toString()
                ) sendPacketTo player
            }
        }
    }

    entity.metas {
        meta<EntityMeta> { setHasGlowingEffect(property.glowing) }
        error("Could not apply GlowingEffectData to ${entity.entityType} entity.")
    }
}