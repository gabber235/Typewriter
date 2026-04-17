package com.typewritermc.quest.entries.audience.objectives.concrete

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.formatted
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.replaceTagPlaceholders
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.entries.inactiveObjectiveDisplay
import com.typewritermc.quest.entries.interfaces.LocatableObjective
import com.typewritermc.quest.entries.showingObjectiveDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.StreamProducer
import org.bukkit.entity.Player
import java.util.Optional

private val completedObjectiveDisplay by snippet(
    "quest.objectives.completable.completed",
    "<green>✔</green> <gray><display></gray>"
)

@Entry(
    "completable_location_objective",
    "A location objective that can show a completed stage",
    Colors.BLUE_VIOLET,
    "fluent:clipboard-location-16-filled"
)
class CompletableLocationObjectiveEntry(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    @Help("The criteria need to be met for the objective to be able to be shown.")
    val showCriteria: List<Criteria> = emptyList(),
    @Help("The criteria to display the objective as completed.")
    val completedCriteria: List<Criteria> = emptyList(),
    override val display: Var<String> = ConstVar(""),
    val targetLocation: Var<Position> = ConstVar(Position.ORIGIN),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LocatableObjective {
    override val criteria: List<Criteria>
        get() = showCriteria

    override fun display(player: Player?): String {
        val text = when {
            player == null -> inactiveObjectiveDisplay
            completedCriteria.matches(player) -> completedObjectiveDisplay
            showCriteria.matches(player) -> showingObjectiveDisplay
            else -> inactiveObjectiveDisplay
        }
        return text.replaceTagPlaceholders("display", display.get(player) ?: "").parsePlaceholders(player)
    }

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

    override fun streamProducers(player: Player, pathStreamDisplay: Ref<PathStreamDisplayEntry>): List<StreamProducer> {
        if (completedCriteria.matches(player)) return emptyList()
        return listOf(
            StreamProducer(
                id,
                pathStreamDisplay,
                endPosition = targetLocation::get
            )
        )
    }
}
