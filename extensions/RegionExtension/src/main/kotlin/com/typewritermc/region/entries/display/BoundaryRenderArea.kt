package com.typewritermc.region.entries.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import org.bukkit.entity.Player

/**
 * How much of the boundary a display renders.
 *
 * [FullBoundary] renders every boundary sample. [NearBoundary] renders only the samples
 * within its radius of the player, a spherical window that follows them.
 */
sealed interface BoundaryRenderArea {
    /**
     * The window to filter samples with for [player], or `null` when the display renders
     * the full boundary.
     */
    fun window(player: Player): NearWindow?
}

@AlgebraicTypeInfo("full_boundary", Colors.GREEN, "mdi:globe-model")
class FullBoundary : BoundaryRenderArea {
    override fun window(player: Player): NearWindow? = null

    override fun equals(other: Any?): Boolean = other is FullBoundary
    override fun hashCode(): Int = javaClass.hashCode()
}

@AlgebraicTypeInfo("near_boundary", Colors.GREEN, "mdi:map-marker-radius")
data class NearBoundary(
    @Default("6.0")
    val radius: Var<Double> = ConstVar(6.0),
) : BoundaryRenderArea {
    override fun window(player: Player): NearWindow {
        val location = player.location
        return NearWindow(
            location.blockX,
            location.blockY,
            location.blockZ,
            radius.get(player).coerceAtLeast(0.0),
        )
    }
}

/**
 * The near mode window, anchored to the block the player stands in. Anchoring to the block
 * instead of the exact position keeps the window stable while the player moves within one
 * block, so cached displays only recompute on block crossings.
 */
data class NearWindow(
    val anchorX: Int,
    val anchorY: Int,
    val anchorZ: Int,
    val radius: Double,
) {
    private val radiusSquared: Double = radius * radius

    fun contains(x: Double, y: Double, z: Double): Boolean {
        val dx = x - (anchorX + 0.5)
        val dy = y - (anchorY + 0.5)
        val dz = z - (anchorZ + 0.5)
        return dx * dx + dy * dy + dz * dz <= radiusSquared
    }
}
