package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.Position
import com.typewritermc.playtest.carried
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import skirout.harness.v1.wire.GameMode
import skirout.harness.v1.wire.KeyboardKey

val InventoryRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("INV-1", "a click on an inventory slot picks its item up on the pointer") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, Position(0.5, 100.0, 0.5))
        probe.gameMode(player, GameMode.SURVIVAL)
        probe.give(player, slot = 9, item = "stick", count = 16)

        player.press(KeyboardKey.E)
        player.clickInventorySlot(9)

        within(10.ticks) { player sees carried("stick") }
    }
}
