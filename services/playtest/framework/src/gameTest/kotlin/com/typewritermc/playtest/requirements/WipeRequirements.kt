package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.backToBack
import com.typewritermc.playtest.camera
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.held
import com.typewritermc.playtest.mark
import com.typewritermc.playtest.marks
import com.typewritermc.playtest.ticks
import com.typewritermc.playtest.wire.Message.Kind
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain

val WipeRequirements by testSuite(compartment = { GameCompartment }) {
    Kind.entries.forEach { kind ->
        backToBack(
            "WIPE-${kind.name}",
            "an attempt finds no ${kind.name.lowercase().replace('_', ' ')} the attempt before it left on its player",
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
