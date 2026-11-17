package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.block
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import skirout.harness.v1.test_run.Demonstrates

val ProbeRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("PROBE-1", "a chat line the probe sends reaches the player") {
        probe.chat(player, "Hello")

        within(10.ticks) { player sees chat("Hello") }
    }

    requirement(
        "PROBE-2",
        "the first input after a far teleport acts on the world around the new spot",
        demonstrates = Demonstrates.EDGE_CASE,
    ) {
        // Far from the middle of the region, where the claim put the player, so no chunk around it was
        // loaded or sent before this teleport.
        probe.fill(BlockPos(298, 99, 1), BlockPos(302, 99, 9), "stone")
        probe.teleport(player, 300.5, 100.0, 2.5)
        probe.gameMode(player, GameMode.CREATIVE)
        val target = probe.block(BlockPos(300, 101, 5), "stone")

        player.aimAt(target)
        player.click(Button.LEFT)

        within(10.ticks) { player sees block(target).gone() }
    }

    requirement(
        "PROBE-3",
        "a block at the edge of what the client draws shows right after a far teleport",
        demonstrates = Demonstrates.EDGE_CASE,
    ) {
        // The client draws the 5 by 5 chunks around its own (render distance 2, which the custom graphics
        // preset keeps) and meshes a chunk only once its 8 neighbours arrived, so the corner chunk 2 chunks
        // away on both axes shows only once the chunk 3 away on both axes arrived, the farthest one a
        // teleport waits for, so the corner shows on the first tick after the teleport is done.
        probe.fill(BlockPos(298, 99, 6), BlockPos(302, 99, 10), "stone")
        val corner = probe.block(BlockPos(330, 101, 40), "stone")
        probe.teleport(player, 300.5, 100.0, 8.5, yaw = -42.5f)
        // The teleport is done once the client holds what it needs, which may take it several ticks; this
        // probe changes nothing and marks the tick it is done in.
        probe.gameMode(player, GameMode.CREATIVE)

        within(1.ticks) { player sees block(corner).shown() }
    }
}
