package com.typewritermc.entity.entries.entity.custom

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.SimpleEntityDefinition
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.inAudience
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.data.minecraft.display.TranslationProperty
import com.typewritermc.entity.entries.entity.minecraft.TextDisplayEntity
import com.typewritermc.entity.entries.event.EntityInteractEventEntry
import com.typewritermc.entity.entries.quest.InteractEntityObjective
import com.typewritermc.quest.trackedQuest
import org.bukkit.entity.Player

val trackedInteractIndicator by snippet("objective.entity.indicator.tracked", "<gold><b>❗")
val interactIndicator by snippet("objective.entity.indicator.normal", "<blue><b>❓")
val dialogueIndicator by snippet("objective.entity.indicator.dialogue", "<white><b>💬")

@Entry(
    "interaction_indicator_definition",
    "Interaction Indicator",
    Colors.ORANGE,
    "material-symbols:move-selection-up-rounded"
)
/**
 * The `InteractionIndicator` class is an entry that represents an quest indicator.
 * When such an indicator is active, it will show an icon above any NPC.
 */
class InteractionIndicatorDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    val definition: Ref<EntityDefinitionEntry> = emptyRef(),
    @OnlyTags("generic_entity_data", "display_data", "text_display_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = StackedEntity(
        player, listOf(
            definition.get()?.create(player)
                ?: throw IllegalStateException("Could not find definition for $definition"),
            InteractionIndicatorEntity(player, ref()).apply {
                consumeProperties(TranslationProperty(Vector(y = namePlateOffset)))
            },
        )
    )
}

class InteractionIndicatorEntity(
    player: Player,
    private val definition: Ref<out EntityDefinitionEntry>,
) : TextDisplayEntity(player) {

    override fun tick() {
        super.tick()
        consumeProperties(LinesProperty(indicator()))
    }

    fun indicator(): String {
        val objectives = Query.findWhere<InteractEntityObjective> {
            it.entity == definition && player.inAudience(it)
        }.toList()
        if (objectives.isEmpty()) {
            if (hasInteractionEntry()) {
                return dialogueIndicator.parsePlaceholders(player)
            }
            return ""
        }
        // If one of them is for the tracked quest we want to display a different icon
        val trackedQuest = player.trackedQuest()
        val icon = if (trackedQuest != null && objectives.any { it.quest == trackedQuest }) {
            trackedInteractIndicator
        } else {
            interactIndicator
        }

        return icon.parsePlaceholders(player)
    }

    private fun hasInteractionEntry(): Boolean {
        return Query.findWhere<EntityInteractEventEntry> { it.definition == definition }
            .flatMap { it.triggers }
            .mapNotNull { it.get() }
            .any { it.criteria.matches(player) }
    }
}