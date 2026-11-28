package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.backToBack
import com.typewritermc.playtest.block
import com.typewritermc.playtest.camera
import com.typewritermc.playtest.idle
import com.typewritermc.playtest.mark
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.standOnFloor
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import skirout.harness.v1.wire.GameMode
import skirout.harness.v1.wire.StateKind

// Scenes whose frames a reviewer looks at in the pull request. Each window checks what its scene
// claims; the frame captured beside it is evidence and decides nothing.
val FrameRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("FRAME-1", "a floor under a night sky Paper keeps for the player shows, and its frame is kept for review") {
        val floor = standOnFloor()
        probe.time(player, 18_000)

        within(10.ticks) {
            player sees block(floor).shown()
            state("Paper keeps a time of day of the player's own") { StateKind.PLAYER_TIME in attempt.query(player) }
        }
        player.capture("night")
    }

    backToBack(
        "FRAME-2",
        "after an attempt that looked through a spyglass at night in the rain, the next attempt's floor shows " +
            "without the spyglass, and both frames are kept for review",
        first = {
            standOnFloor()
            // Night falls and rain sets in while the player looks through a spyglass: the sky, the fog, the
            // rain fog and the field of view ease toward them tick by tick.
            probe.gameMode(player, GameMode.SURVIVAL)
            probe.give(player, slot = 0, item = "spyglass")
            probe.selectSlot(player, 0)
            mark(player, StateKind.PLAYER_TIME)
            player.hold(Button.RIGHT, 40.ticks)

            within(45.ticks) {
                player sees camera.scoped()
                state("Paper keeps the night and rain of the player's own") { StateKind.PLAYER_TIME in attempt.query(player) }
            }
            player.capture("in-rain")
        },
        then = {
            val floor = standOnFloor()
            probe.time(player, 6_000)

            within(10.ticks) {
                player sees block(floor).shown()
                player.never sees camera.scoped()
            }
            player.capture("after-wipe")
        },
    )

    requirement("FRAME-3", "a lamp lighting a floor at night stays shown, and its first and later frames are kept for review") {
        standOnFloor()
        // An invisible light at its full level 15: a torch would add flame particles of its own. At night
        // the sky hardly lights the floor, so every shade of the lamp's falloff shows instead of the full
        // brightness of day.
        val lamp = probe.block(BlockPos(0, 100, 4), "light")
        probe.time(player, 18_000)

        within(10.ticks) { player sees block(lamp).shown() }
        player.capture("first")

        idle(player, 10.ticks)

        within(1.ticks) { player sees block(lamp).shown() }
        player.capture("later")
    }
}
