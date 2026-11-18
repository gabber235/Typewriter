package com.typewritermc.playtest.pool

import skirout.harness.v1.wire.Region
import kotlin.math.abs
import kotlin.math.max

/**
 * Hands every attempt a region of the world no earlier attempt used: the cells of a grid
 * [REGION_SPACING] blocks wide, ring by ring around the spawn, whose own cell stays free for players
 * that join. The [ahead] regions the next claims get are known in advance, so Paper can load their
 * ground during earlier attempts.
 */
internal class Regions(
    private val ahead: Int,
) {
    private var ring = 0
    private var cells = emptyList<Region>().iterator()
    private val upcoming = ArrayDeque<Region>()

    init {
        require(ahead >= 1) { "the lookahead holds at least the next region, not $ahead" }
        fill()
    }

    /** The region the next claim gets; it leaves the lookahead and a new region joins its end. */
    fun next(): Region {
        val region = upcoming.removeFirst()
        fill()
        return region
    }

    /** The regions the next claims get, in the order they get them. */
    fun ahead(): List<Region> = upcoming.toList()

    private fun fill() {
        while (upcoming.size < ahead) {
            if (!cells.hasNext()) cells = cellsOf(++ring).iterator()
            upcoming.addLast(cells.next())
        }
    }

    /** Every cell [ring] cells from the spawn's cell, measured as the farther of the two axes. */
    private fun cellsOf(ring: Int): List<Region> =
        (-ring..ring).flatMap { x ->
            (-ring..ring).filter { z -> max(abs(x), abs(z)) == ring }.map { z -> Region(x = x * REGION_SPACING, z = z * REGION_SPACING) }
        }
}

/**
 * How far apart the middles of two regions lie, in blocks. A region holds the blocks within half of it
 * from its middle, so nothing one attempt places, spawns or plays reaches another.
 */
internal const val REGION_SPACING = 1024
