package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message.Region
import kotlin.math.abs
import kotlin.math.max

/**
 * Hands every attempt a region of the world no earlier attempt used: the cells of a grid
 * [Region.SPACING] blocks wide, ring by ring around the spawn, whose own cell stays free for players
 * that join.
 */
internal class Regions {
    private var ring = 1
    private var cells = cellsOf(ring).iterator()

    fun next(): Region {
        if (!cells.hasNext()) cells = cellsOf(++ring).iterator()
        return cells.next()
    }

    /** Every cell [ring] cells from the spawn's cell, measured as the farther of the two axes. */
    private fun cellsOf(ring: Int): List<Region> =
        (-ring..ring).flatMap { x ->
            (-ring..ring).filter { z -> max(abs(x), abs(z)) == ring }.map { z -> Region(x * Region.SPACING, z * Region.SPACING) }
        }
}
