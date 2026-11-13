package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.block
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val BlockRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("BREAK-1", "leaves the player keeps hitting break") {
        probe.fill(BlockPos(102, 99, -2), BlockPos(106, 99, 8), "stone")
        probe.teleport(player, 104.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)
        val leaves = probe.block(BlockPos(104, 101, 2), "oak_leaves[persistent=true]")

        player.aimAt(leaves)
        player.hold(Button.LEFT, 20.ticks)

        within(30.ticks) { player sees block(leaves).gone() }
    }

    requirement("BREAK-2", "leaves whose break is cancelled come back") {
        probe.fill(BlockPos(110, 99, -2), BlockPos(114, 99, 8), "stone")
        probe.teleport(player, 112.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)
        val leaves = probe.block(BlockPos(112, 101, 2), "oak_leaves[persistent=true]")
        probe.cancelBreaking(leaves)

        player.aimAt(leaves)
        player.hold(Button.LEFT, 20.ticks)

        within(30.ticks) { player sees block(leaves).becomes("oak_leaves") }
    }
}
