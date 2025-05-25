package com.typewritermc.entity.entries.quest

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entity.AudienceEntityDisplay
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.findDisplay
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.quest.LocatableObjective
import com.typewritermc.quest.QuestEntry
import org.bukkit.entity.Player
import java.util.*

private val displayTemplate by snippet("quest.objective.interact_entity", "Interact with <entity>")

@Entry("interact_entity_objective", "Interact with an entity", Colors.BLUE_VIOLET, "ph:hand-tap-fill")
/**
 * The `InteractEntityObjective` class is an entry that represents an objective to interact with an entity.
 * When such an objective is active, it will show an icon above any NPC.
 */
class InteractEntityObjective(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("The entity that the player needs to interact with.")
    val entity: Ref<out EntityDefinitionEntry> = emptyRef(),
    @Help("The objective display that will be shown to the player. Use &lt;entity&gt; to replace the entity name.")
    val overrideDisplay: Optional<Var<String>> = Optional.empty(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LocatableObjective {
    override val display: Var<String>
        get() = overrideDisplay.orElseGet { ConstVar(displayTemplate) }
            .map { player, value -> value.replace("<entity>", entity.get()?.displayName?.get(player) ?: "") }

    private val displays by lazy(LazyThreadSafetyMode.NONE) {
        // As displays and references can't change (except between reloads) we can just cache all relevant ones here for quick access.
        Query.findWhere<EntityInstanceEntry> { it.definition == entity }
            .mapNotNull { it.ref().findDisplay<AudienceEntityDisplay>() }
            .toList()
    }

    override fun positions(player: Player?): List<Position> {
        if (player == null) return emptyList()
        return displays.filter { it.canView(player.uniqueId) }
            .mapNotNull { it.position(player.uniqueId) }
    }
}