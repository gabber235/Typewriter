package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.backToBack
import com.typewritermc.playtest.camera
import com.typewritermc.playtest.idle
import com.typewritermc.playtest.mark
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import skirout.harness.v1.wire.GameMode
import skirout.harness.v1.wire.StateKind

// Scenes whose frames a reviewer looks at in the pull request: each captures them as evidence, which
// decides nothing, and passes or fails on what its window perceives.
val FrameRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("FRAME-1", "a still scene with a quest sidebar settles its camera, and its frame is kept for review") {
        // Stone turns its texture by its world position, which moves with the attempt's region; smooth
        // stone looks the same everywhere.
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
        // A spectator holds no hand: its skin would differ with the pool player that runs the requirement.
        probe.gameMode(player, GameMode.SPECTATOR)
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.time(player, 6_000)
        probe.sidebar(player, "Quest", listOf("Find the key", "Gold: 3"))

        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        player.capture("sidebar")
    }

    backToBack(
        "FRAME-2",
        "after an attempt that looked through a spyglass at night in the rain, the next attempt's scene settles " +
            "without the spyglass, and both frames are kept for review",
        first = {
            probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
            probe.gameMode(player, GameMode.SPECTATOR)
            probe.teleport(player, 0.5, 100.0, 0.5)
            probe.time(player, 6_000)
            within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
            player.capture("before-rain")

            // Night falls and rain sets in while the player looks through a spyglass: the sky, the fog, the
            // rain fog and the field of view ease toward them tick by tick.
            probe.gameMode(player, GameMode.SURVIVAL)
            probe.give(player, slot = 0, item = "spyglass")
            probe.selectSlot(player, 0)
            mark(player, StateKind.PLAYER_TIME)
            player.hold(Button.RIGHT, 40.ticks)
            within(45.ticks) { player sees camera.scoped() }
            player.capture("in-rain")
        },
        then = {
            probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
            probe.gameMode(player, GameMode.SPECTATOR)
            probe.teleport(player, 0.5, 100.0, 0.5)
            probe.time(player, 6_000)
            within(10.ticks) {
                player sees camera.near(0.5, 0.5, within = 0.5)
                player.never sees camera.scoped()
            }

            player.capture("after-wipe")
        },
    )

    requirement("FRAME-3", "a still scene keeps its camera where it settled, and its first and later frames are kept for review") {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
        probe.gameMode(player, GameMode.SPECTATOR)
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.time(player, 6_000)
        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        player.capture("first")

        idle(player, 10.ticks)

        within(1.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        player.capture("later")
    }

    requirement("FRAME-4", "a floor by day and under the night sky settles its camera, and both frames are kept for review") {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
        probe.gameMode(player, GameMode.SPECTATOR)
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.time(player, 6_000)
        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        player.capture("day")

        probe.time(player, 18_000)
        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        player.capture("night")
    }

    requirement("FRAME-5", "a floor lit by a lamp at night settles its camera, and its first and later frames are kept for review") {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
        // An invisible light: a torch would add flame particles of its own. At night the sky hardly lights
        // the floor, so every shade of the lamp's falloff shows instead of the full brightness of day.
        probe.fill(BlockPos(0, 100, 4), BlockPos(0, 100, 4), "light[level=15]")
        probe.gameMode(player, GameMode.SPECTATOR)
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.time(player, 18_000)
        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        player.capture("first")

        idle(player, 10.ticks)

        within(1.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        player.capture("later")
    }
}
