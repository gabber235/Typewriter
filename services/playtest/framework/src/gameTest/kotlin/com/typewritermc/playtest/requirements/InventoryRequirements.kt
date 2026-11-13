package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.Key
import com.typewritermc.playtest.carried
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val InventoryRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("INV-1", "a click on an inventory slot picks its item up on the pointer") {
        probe.fill(BlockPos(118, 99, -2), BlockPos(122, 99, 8), "stone")
        probe.teleport(player, 120.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)
        probe.give(player, slot = 9, item = "stick", count = 16)

        player.press(Key.E)
        player.clickInventorySlot(9)

        within(10.ticks) { player sees carried("stick") }
    }
}
