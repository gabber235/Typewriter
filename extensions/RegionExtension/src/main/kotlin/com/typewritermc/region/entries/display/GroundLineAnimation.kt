package com.typewritermc.region.entries.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import org.bukkit.entity.Player
import java.time.Duration

/**
 * How the ground line flows around the region.
 *
 * A flowing line is drawn from the same points as a still one; it is the points that march along
 * the loop, at [blocksPerSecond], in the [direction] the case picked.
 */
sealed interface GroundLineAnimation {
    fun blocksPerSecond(player: Player): Double

    /** `1` to flow along the path's point order, `-1` to flow against it. */
    fun direction(path: GroundLinePath): Int
}

@AlgebraicTypeInfo("static", Colors.GREEN, "mdi:minus")
class StaticGroundLine : GroundLineAnimation {
    override fun blocksPerSecond(player: Player): Double = 0.0
    override fun direction(path: GroundLinePath): Int = 1

    override fun equals(other: Any?): Boolean = other is StaticGroundLine
    override fun hashCode(): Int = javaClass.hashCode()
}

@AlgebraicTypeInfo("clockwise", Colors.GREEN, "mdi:rotate-right")
data class ClockwiseGroundLine(
    @Help("How fast the line flows, in blocks per second.")
    @Default("2.0")
    val speed: Var<Double> = ConstVar(2.0),
) : GroundLineAnimation {
    override fun blocksPerSecond(player: Player): Double = speed.get(player)
    override fun direction(path: GroundLinePath): Int = path.clockwiseDirection
}

@AlgebraicTypeInfo("counter_clockwise", Colors.GREEN, "mdi:rotate-left")
data class CounterClockwiseGroundLine(
    @Help("How fast the line flows, in blocks per second.")
    @Default("2.0")
    val speed: Var<Double> = ConstVar(2.0),
) : GroundLineAnimation {
    override fun blocksPerSecond(player: Player): Double = speed.get(player)
    override fun direction(path: GroundLinePath): Int = -path.clockwiseDirection
}

/** How far along the loop the line has flowed after [elapsed], signed by the flow direction. */
internal fun groundLinePhase(
    animation: GroundLineAnimation,
    path: GroundLinePath,
    player: Player,
    elapsed: Duration,
): Double {
    val speed = animation.blocksPerSecond(player)
    if (speed == 0.0) return 0.0
    return animation.direction(path) * speed * (elapsed.toMillis() / 1000.0)
}
