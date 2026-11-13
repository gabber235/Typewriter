package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.Key
import com.typewritermc.playtest.camera
import com.typewritermc.playtest.held
import com.typewritermc.playtest.offhand
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val HotbarRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("HOTBAR-1", "scrolling the wheel down selects the next hotbar slot") {
        probe.fill(BlockPos(6, 99, -2), BlockPos(10, 99, 8), "stone")
        probe.teleport(player, 8.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        probe.give(player, slot = 0, item = "spyglass")
        probe.give(player, slot = 1, item = "stick")
        probe.selectSlot(player, 0)

        player.scroll(-1)

        within(5.ticks) { player sees held("stick") }
    }

    requirement("HOTBAR-2", "a number key selects its hotbar slot") {
        probe.fill(BlockPos(14, 99, -2), BlockPos(18, 99, 8), "stone")
        probe.teleport(player, 16.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        probe.give(player, slot = 0, item = "spyglass")
        probe.give(player, slot = 2, item = "compass")
        probe.selectSlot(player, 0)

        player.press(Key.DIGIT_3)

        within(5.ticks) { player sees held("compass") }
    }

    requirement("HAND-1", "the swap key moves the held item to the off hand") {
        probe.fill(BlockPos(22, 99, -2), BlockPos(26, 99, 8), "stone")
        probe.teleport(player, 24.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        probe.give(player, slot = 0, item = "spyglass")
        probe.give(player, slot = 40, item = "air")
        probe.selectSlot(player, 0)

        player.press(Key.F)

        within(5.ticks) { player sees offhand("spyglass") }
    }

    requirement("USE-1", "holding use with a spyglass looks through it") {
        probe.fill(BlockPos(30, 99, -2), BlockPos(34, 99, 8), "stone")
        probe.teleport(player, 32.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)
        probe.give(player, slot = 0, item = "spyglass")
        probe.selectSlot(player, 0)

        player.hold(Button.RIGHT, 10.ticks)

        within(15.ticks) { player sees camera.scoped() }
    }
}
