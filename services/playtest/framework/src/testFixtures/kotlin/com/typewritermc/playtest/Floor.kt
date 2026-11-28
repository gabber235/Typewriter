package com.typewritermc.playtest

import skirout.harness.v1.wire.GameMode

/**
 * The attempt's player stands as a spectator on a smooth stone floor, facing along it, and watches the
 * floor block 4 blocks ahead; returns that block, so `block(floor).shown()` proves the floor is drawn.
 * Stone turns its texture by its world position, which moves with the attempt's region; smooth stone
 * looks the same everywhere. A spectator holds no hand, whose skin would differ with the pool player
 * that runs the requirement.
 */
suspend fun RequirementScope.standOnFloor(): BlockRef {
    probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
    probe.gameMode(player, GameMode.SPECTATOR)
    probe.teleport(player, 0.5, 100.0, 0.5)
    return probe.block(BlockPos(0, 99, 4), "smooth_stone")
}
