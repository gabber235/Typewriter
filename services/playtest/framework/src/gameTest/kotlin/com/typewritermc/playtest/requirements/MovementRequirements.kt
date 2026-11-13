package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.Key
import com.typewritermc.playtest.camera
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val MovementRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("MOVE-1", "holding the sneak key lowers the view") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)

        player.hold(Key.LEFT_SHIFT, 6.ticks)

        within(10.ticks) { player sees camera.sank() }
    }

    requirement("MOVE-2", "the jump key lifts the view") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)

        player.hold(Key.SPACE, 3.ticks)

        within(10.ticks) { player sees camera.rose() }
    }

    requirement("MOVE-3", "the jump key flies a spectator up") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SPECTATOR)

        player.hold(Key.SPACE, 3.ticks)

        within(10.ticks) { player sees camera.rose() }
    }

    requirement("MOVE-4", "walking toward a point four blocks away brings the player there") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)

        player.walkTo(0.5, 4.5)

        within(100.ticks) { player sees camera.near(0.5, 4.5, within = 0.5) }
    }
}
