package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.Demonstrates
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.PaperLost
import com.typewritermc.playtest.held
import com.typewritermc.playtest.killPaperWhileItBoots
import com.typewritermc.playtest.offhand
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.string.shouldContain

val RestartRequirements by testSuite(compartment = { GameCompartment }) {
    requirement(
        "RESTART-1",
        "an item saved before Paper is killed is still held once Paper boots again",
        restartsPaper = true,
    ) {
        probe.give(player, slot = 0, item = "diamond")
        probe.selectSlot(player, 0)
        probe.save(player)

        restartPaper()

        within(20.ticks) { player sees held("diamond") }
    }

    requirement(
        "RESTART-2",
        "an item given after the last save is gone once Paper is killed, as a crash loses it",
        demonstrates = Demonstrates.EDGE_CASE,
        restartsPaper = true,
    ) {
        probe.give(player, slot = 0, item = "stick")
        probe.selectSlot(player, 0)
        probe.save(player)
        probe.give(player, slot = 40, item = "diamond")
        within(5.ticks) { player sees offhand("diamond") }

        restartPaper()

        within(20.ticks) {
            player sees held("stick")
            player.never sees offhand("diamond")
        }
    }

    requirement(
        "RESTART-3",
        "a Paper that dies while it boots again fails only its own attempt, naming the cause and its log",
        demonstrates = Demonstrates.FAILURE,
        restartsPaper = true,
    ) {
        val lost = shouldThrow<PaperLost> { killPaperWhileItBoots { restartPaper() } }

        lost.report shouldContain "exited with code 137 while it booted"
        lost.report shouldContain "console.log"
    }
}
