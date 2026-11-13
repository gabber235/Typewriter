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

val ProbeRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("PROBE-1", "a chat line the probe sends reaches the player") {
        probe.chat(player, "Hello")

        within(10.ticks) { player sees chat("Hello") }
    }

    requirement("PROBE-2", "the first input after a far teleport acts on the world around the new spot") {
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
}
