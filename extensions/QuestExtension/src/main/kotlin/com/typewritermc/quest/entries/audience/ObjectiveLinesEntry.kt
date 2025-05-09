package com.typewritermc.quest.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.engine.paper.entry.entries.LinesEntry
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.quest.trackedShowingObjectives
import org.bukkit.entity.Player
import java.util.*

@Entry(
    "objective_lines",
    "Display all the current objectives",
    Colors.ORANGE_RED,
    "fluent:clipboard-task-list-ltr-24-filled"
)
/**
 * The `ObjectiveLinesEntry` is a display that shows all the current objectives.
 *
 * ## How could this be used?
 * This could be used to show a list of tracked objectives
 */
class ObjectiveLinesEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The format for the line. Use &lt;objective&gt; to replace with the objective name.")
    @Colored
    @Placeholder
    @MultiLine
    val format: String = "<objective>",
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LinesEntry {
    override fun lines(player: Player): String {
        return player.trackedShowingObjectives().sortedByDescending { it.priority }.joinToString("\n") {
            format.parsePlaceholders(player).asMiniWithResolvers(
                net.kyori.adventure.text.minimessage.tag.resolver.Placeholder.parsed(
                    "objective",
                    it.display(player)
                )
            ).asMini()
        }
    }
}