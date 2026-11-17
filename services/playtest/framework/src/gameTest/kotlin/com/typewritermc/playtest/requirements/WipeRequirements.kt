package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.backToBack
import com.typewritermc.playtest.block
import com.typewritermc.playtest.camera
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.held
import com.typewritermc.playtest.mark
import com.typewritermc.playtest.marks
import com.typewritermc.playtest.ticks
import com.typewritermc.playtest.wire.entries
import com.typewritermc.playtest.wire.variantName
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import skirout.harness.v1.wire.StateKind

val WipeRequirements by testSuite(compartment = { GameCompartment }) {
    StateKind.entries.forEach { kind ->
        val name = variantName(StateKind.typeDescriptor, kind)
        backToBack(
            "WIPE-${name.uppercase()}",
            "an attempt finds no ${name.replace('_', ' ')} the attempt before it left on its player",
            first = {
                mark(player, kind)
                marks(player) shouldContain kind
            },
            then = { marks(player) shouldNotContain kind },
        )
    }

    backToBack(
        "WIPE-INVENTORY",
        "an attempt finds none of the items the attempt before it gave its players",
        players = 4,
        first = {
            players.forEach { probe.give(it, 0, "stick") }
            within(10.ticks) { players.forEach { it sees held("stick") } }
        },
        then = {
            probe.chat(players, "Fresh")
            within(10.ticks) {
                players.forEach {
                    it sees chat("Fresh")
                    it.never sees held("stick")
                }
            }
        },
    )

    backToBack(
        "WIPE-BREAK",
        "a break right after an attempt that broke a block takes as many ticks as on a fresh client",
        first = {
            probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
            probe.teleport(player, 0.5, 100.0, 0.5)
            probe.gameMode(player, GameMode.SURVIVAL)
            val leaves = probe.block(BlockPos(0, 101, 2), "oak_leaves[persistent=true]")
            player.aimAt(leaves)
            player.hold(Button.LEFT, 20.ticks)
            within(30.ticks) { player sees block(leaves).gone() }
        },
        then = {
            probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
            probe.teleport(player, 0.5, 100.0, 0.5)
            probe.gameMode(player, GameMode.SURVIVAL)
            val leaves = probe.block(BlockPos(0, 101, 2), "oak_leaves[persistent=true]")
            player.aimAt(leaves)
            player.hold(Button.LEFT, 20.ticks)
            // A bare hand breaks leaves a sixth at a time, so a fresh client breaks them on the sixth tick.
            within(6.ticks) { player sees block(leaves).gone() }
        },
    )

    backToBack(
        "WIPE-POSITION",
        "an attempt finds its player at the middle of its region, wherever the attempt before it left the player",
        first = {
            probe.teleport(player, 8.5, 100.0, 0.5)
            within(10.ticks) { player sees camera.near(8.5, 0.5, within = 0.5) }
        },
        then = {
            probe.chat(player, "Fresh")
            within(10.ticks) {
                player sees chat("Fresh")
                player sees camera.near(0.5, 0.5, within = 0.5)
            }
        },
    )
}
