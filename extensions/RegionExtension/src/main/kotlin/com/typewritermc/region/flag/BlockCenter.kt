package com.typewritermc.region.flag

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import org.bukkit.block.Block

/**
 * The center of the block, where every block scoped flag decides region membership.
 *
 * A block's location is its lowest corner, and a region boundary crossing the block can
 * leave that corner outside while most of the block sits inside. Deciding at the corner
 * makes visibly covered floor blocks read as unprotected; the center matches what a
 * builder sees covered.
 */
internal fun Block.centerPosition(): Position =
    Position(World(world.uid.toString()), x + 0.5, y + 0.5, z + 0.5)
