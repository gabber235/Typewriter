package com.typewritermc.basic.entries.action

import com.github.retrooper.packetevents.protocol.advancements.*
import com.github.retrooper.packetevents.resources.ResourceLocation
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerUpdateAdvancements
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.extensions.packetevents.toPacketItem
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.item.Item
import net.kyori.adventure.text.Component
import java.util.*
import kotlin.jvm.optionals.getOrNull

private val resourceLocation = ResourceLocation("typewriter", "notification")
private const val criteriaIdentifier = "typewriter:some_criteria"

@Entry(
    "send_toast",
    "Show an advancement toast to the player",
    Colors.RED,
    "material-symbols:notifications-unread-rounded"
)
/**
 * The `Send Toast Action` is intended to display an advancement-style toast to the player.
 *
 * ## How could this be used?
 * This can be use to show a nice toast in the top right corner of the screen.
 * Like when the player has completed a quest or objective.
 */
class SendToastActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Colored
    @Placeholder
    val title: Var<String> = ConstVar(""),
    val icon: Var<Item> = ConstVar(Item.Empty),
    val advancementType: Var<AdvancementType> = ConstVar(AdvancementType.TASK),
    val background: Optional<String> = Optional.empty(),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val displayData = AdvancementDisplay(
            title.get(player, context).parsePlaceholders(player).asMini(),
            Component.text("Gabber235 was here! #typewriter"),
            icon.get(player, context).build(player, context).toPacketItem(),
            advancementType.get(player, context),
            background.map { ResourceLocation(it) }.getOrNull(),
            true,
            true,
            0f, 0f
        )

        val progress = AdvancementProgress(
            mapOf(
                criteriaIdentifier to AdvancementProgress.CriterionProgress(
                    System.currentTimeMillis()
                )
            )
        )
        val advancement = Advancement(null, displayData, listOf(listOf(criteriaIdentifier)), false)
        val advancementHolder = AdvancementHolder(resourceLocation, advancement)

        WrapperPlayServerUpdateAdvancements(
            false,
            listOf(advancementHolder),
            setOf(),
            mapOf(resourceLocation to progress),
            true
        ).sendPacketTo(player)

        WrapperPlayServerUpdateAdvancements(
            false,
            listOf(),
            setOf(resourceLocation),
            mapOf(),
            true
        ).sendPacketTo(player)
    }
}
