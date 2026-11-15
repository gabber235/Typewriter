package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.Frame
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.backToBack
import com.typewritermc.playtest.brightnessAt
import com.typewritermc.playtest.camera
import com.typewritermc.playtest.frameOf
import com.typewritermc.playtest.idle
import com.typewritermc.playtest.mark
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import com.typewritermc.playtest.wire.Message.Kind
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.ints.shouldBeLessThan
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val GoldenRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("GOLDEN-1", "a quest sidebar looks exactly like its approved golden") {
        // Stone turns its texture by its world position, which moves with the attempt's region; smooth
        // stone looks the same everywhere.
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
        // A spectator holds no hand: its skin would differ with the pool player that runs the requirement.
        probe.gameMode(player, GameMode.SPECTATOR)
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.time(player, 6_000)
        probe.sidebar(player, "Quest", listOf("Find the key", "Gold: 3"))

        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        player.looksLike("sidebar")
    }

    lateinit var beforeRain: Frame
    backToBack(
        "GOLDEN-2",
        "a scene draws the same frame after a wipe whatever the attempt before it showed, rain and night included",
        first = {
            probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
            probe.gameMode(player, GameMode.SPECTATOR)
            probe.teleport(player, 0.5, 100.0, 0.5)
            probe.time(player, 6_000)
            within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
            beforeRain = frameOf(player, "before-rain")

            // Night falls and rain sets in while the player looks through a spyglass: the sky, the fog, the
            // rain fog and the field of view ease toward them tick by tick.
            probe.gameMode(player, GameMode.SURVIVAL)
            probe.give(player, slot = 0, item = "spyglass")
            probe.selectSlot(player, 0)
            mark(player, Kind.PLAYER_TIME)
            player.hold(Button.RIGHT, 40.ticks)
            frameOf(player, "in-rain").sha256 shouldNotBe beforeRain.sha256
        },
        then = {
            probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
            probe.gameMode(player, GameMode.SPECTATOR)
            probe.teleport(player, 0.5, 100.0, 0.5)
            probe.time(player, 6_000)
            within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }

            frameOf(player, "after-wipe").sha256 shouldBe beforeRain.sha256
        },
    )

    requirement("GOLDEN-3", "a still scene draws the same frame from the first tick it shows on") {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
        probe.gameMode(player, GameMode.SPECTATOR)
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.time(player, 6_000)
        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        val first = frameOf(player, "first")

        idle(player, 10.ticks)

        frameOf(player, "later").sha256 shouldBe first.sha256
    }

    requirement("GOLDEN-4", "a floor under the night sky draws far darker than by day") {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "smooth_stone")
        probe.gameMode(player, GameMode.SPECTATOR)
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.time(player, 6_000)
        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        val day = frameOf(player, "day")

        probe.time(player, 18_000)
        within(10.ticks) { player sees camera.near(0.5, 0.5, within = 0.5) }
        val night = frameOf(player, "night")

        // The floor right below the camera, at the bottom of the frame, where the fog hardly reaches.
        night.brightnessAt(night.width / 2, night.height - 20) shouldBeLessThan day.brightnessAt(day.width / 2, day.height - 20) / 2
    }
}
