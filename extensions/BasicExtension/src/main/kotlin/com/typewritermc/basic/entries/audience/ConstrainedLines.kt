package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.LinesEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.limitLineLength
import org.bukkit.entity.Player
import java.util.*

@Entry("constrained_lines", "A lines entry that can be constrained", Colors.ORANGE_RED, "eos-icons:constraint")
/**
 * The `ConstrainedLines` constraints the child lines to a certain width.
 * This is useful for displaying long lines of text.
 */
class ConstrainedLines(
    override val id: String = "",
    override val name: String = "",
    val lines: List<Ref<LinesEntry>> = emptyList(),
    @Default("30")
    val maxWidth: Var<Int> = ConstVar(30),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LinesEntry {
    override fun lines(player: Player): String {
        val lines = lines.mapNotNull { it.get()?.lines(player) }.joinToString("\n")
        return lines.limitLineLength(maxWidth.get(player))
    }
}