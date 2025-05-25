package com.typewritermc.quest.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.formatted
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.quest.LocatableObjective
import com.typewritermc.quest.QuestEntry
import org.bukkit.entity.Player
import java.util.*

@Entry("location_objective", "A location objective definition", Colors.BLUE_VIOLET, "streamline:target-solid")
/**
 * The `LocationObjective` entry is a task that the player can complete by reaching a specific location.
 * It is mainly for displaying the progress to a player.
 *
 * It is **not** necessary to use this entry for objectives.
 * It is just a visual novelty.
 *
 * The entry filters the audience based on if the objective is active.
 * It will show the objective to the player if the criteria are met.
 *
 * It allows path streams to be displayed to the target location.
 *
 * ## How could this be used?
 * This could be used to guide the players to a specific location.
 * Showing the players where they need to go with a path stream.
 */
class LocationObjectiveEntry(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    override val display: Var<String> = ConstVar(""),
    val targetLocation: Var<Position> = ConstVar(Position.ORIGIN),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LocatableObjective {
    override fun parser(): PlaceholderParser = placeholderParser {
        include(super.parser())

        literal("location") {
            string("format") { format ->
                supply {
                    targetLocation.get(it)?.formatted(format())
                }
            }

            supply { targetLocation.get(it)?.formatted() }
        }
    }

    override fun positions(player: Player?): List<Position> {
        val position = targetLocation.get(player) ?: return emptyList()
        return listOf(position)
    }
}