package com.typewritermc.basic.entries.cinematic

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.Segment
import com.typewritermc.engine.paper.entry.temporal.SimpleCinematicAction
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Sync
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player

interface CinematicCommandEntry : CinematicEntry {
    val segments: List<CommandSegment>
}

@Entry(
    "cinematic_console_command",
    "Runs command as the console at a specific frame.",
    Colors.YELLOW,
    "mingcute:terminal-fill"
)
/**
 * The `Cinematic Console Command` entry runs a command as the console at a specific frame.
 *
 * ## How could this be used?
 *
 * You can use a different plugin to animate blocks, hide a scoreboard, or trigger something in another plugin.
 */
class CinematicConsoleCommandEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Segments(Colors.YELLOW, "mingcute:terminal-fill")
    @InnerMax(Max(1))
    // Run commands on different segments
    override val segments: List<CommandSegment> = emptyList(),
) : CinematicCommandEntry {
    override fun create(player: Player): CinematicAction {
        return CommandAction(
            player,
            this
        ) { command ->
            player.server.dispatchCommand(player.server.consoleSender, command)
        }
    }
}

@Entry(
    "cinematic_player_command",
    "Runs command as the player at a specific frame.",
    Colors.YELLOW,
    "mingcute:terminal-fill"
)
/**
 * The `Cinematic Player Command` entry runs a command as the player at a specific frame.
 *
 * ## How could this be used?
 *
 * You can use a different plugin to animate blocks, hide a scoreboard, or trigger something in another plugin.
 */
class CinematicPlayerCommandEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Segments(Colors.YELLOW, "mingcute:terminal-fill")
    @InnerMax(Max(1))
    // Run commands on different segments
    override val segments: List<CommandSegment> = emptyList(),
) : CinematicCommandEntry {
    override fun create(player: Player): CinematicAction {
        return CommandAction(
            player,
            this
        ) { command ->
            player.performCommand(command)
        }
    }
}

data class CommandSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
    @Help("Each line is a different command. Commands should not be prefixed with <code>/</code>.")
    @Placeholder
    @MultiLine
    val command: String = "",
    val sudo: Boolean = false,
) : Segment

class CommandAction(
    private val player: Player,
    entry: CinematicCommandEntry,
    private val run: (String) -> Unit,
) : SimpleCinematicAction<CommandSegment>() {
    override val segments: List<CommandSegment> = entry.segments

    override suspend fun startSegment(segment: CommandSegment) {
        super.startSegment(segment)
        if (segment.command.isBlank()) return
        Dispatchers.Sync.switchContext {
            val attachment = if (segment.sudo) {
                player.addAttachment(plugin)
            } else null
            attachment?.setPermission("*", true)
            segment.command.parsePlaceholders(player)
                .lines()
                .filter { it.isNotBlank() }
                .forEach(run)

            attachment?.remove()
        }
    }
}