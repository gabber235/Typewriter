package com.typewritermc.region.entries.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import org.bukkit.entity.Player

/** Which stretches of the ground line emit particles. */
sealed interface GroundLinePattern {
    /** Whether the point [arc] blocks along the line emits. */
    fun emitsAt(arc: Double, player: Player): Boolean
}

@AlgebraicTypeInfo("solid", Colors.GREEN, "mdi:minus")
class SolidLine : GroundLinePattern {
    override fun emitsAt(arc: Double, player: Player): Boolean = true

    override fun equals(other: Any?): Boolean = other is SolidLine
    override fun hashCode(): Int = javaClass.hashCode()
}

@AlgebraicTypeInfo("dashed", Colors.GREEN, "mdi:dots-horizontal")
data class DashedLine(
    @Help("How long a lit stretch is, in blocks.")
    @Default("4.0")
    val dash: Var<Double> = ConstVar(4.0),
    @Help("How long the dark stretch between two dashes is, in blocks.")
    @Default("3.0")
    val gap: Var<Double> = ConstVar(3.0),
) : GroundLinePattern {
    override fun emitsAt(arc: Double, player: Player): Boolean {
        val lit = dash.get(player).coerceAtLeast(0.0)
        val dark = gap.get(player).coerceAtLeast(0.0)
        val period = lit + dark
        if (period < 1e-6) return true
        return arc.mod(period) < lit
    }
}
