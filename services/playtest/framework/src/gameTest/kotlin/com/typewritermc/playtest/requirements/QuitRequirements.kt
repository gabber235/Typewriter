package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.ClientLost
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.Players
import com.typewritermc.playtest.backToBack
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.crashClient
import com.typewritermc.playtest.held
import com.typewritermc.playtest.listed
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import com.typewritermc.playtest.unlisted
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldBeIn
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.test_run.LossCause

val QuitRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("QUIT-1", "a player who quits leaves the other player's player list", players = Players.count(2)) {
        val (leaver, stayer) = players
        probe.chat(stayer, "Ready")
        within(10.ticks) { stayer sees listed(leaver) }

        leaver.quit()

        within(10.ticks) { stayer sees unlisted(leaver) }
    }

    requirement(
        "QUIT-2",
        "a player who quits and rejoins is listed again and holds the item Paper kept for it",
        players = Players.count(2),
    ) {
        val (leaver, stayer) = players
        probe.give(leaver, slot = 0, item = "diamond")
        probe.selectSlot(leaver, 0)
        within(5.ticks) { leaver sees held("diamond") }
        leaver.quit()
        within(10.ticks) { stayer sees unlisted(leaver) }

        leaver.rejoin()

        // Paper lists a joining player to the others in the tick it joins, however long its own client takes to load.
        within(1.ticks) { stayer sees listed(leaver) }
        within(20.ticks) { leaver sees held("diamond") }
    }

    requirement(
        "QUIT-3",
        "while a player is away, a window on the player still on Paper decides as usual",
        players = Players.count(2),
        demonstrates = Demonstrates.EDGE_CASE,
    ) {
        val (leaver, stayer) = players
        leaver.quit()

        probe.chat(stayer, "Still here")

        within(10.ticks) { stayer sees chat("Still here") }
    }

    requirement(
        "QUIT-4",
        "a client that crashes while its player is away fails the attempt as lost",
        demonstrates = Demonstrates.FAILURE,
    ) {
        player.quit()
        crashClient(player)

        val lost = shouldThrow<ClientLost> { player.rejoin() }

        // The crash shows first as the process's exit or as the pool connection closing; Paper no longer sees the player.
        lost.loss.kind shouldBeIn listOf(LossCause.Kind.EXITED_WRAPPER, LossCause.Kind.LEFT_WRAPPER)
    }

    backToBack(
        "QUIT-5",
        "a player whose attempt ends while it is away joins again and serves the next attempt",
        players = Players.count(2),
        demonstrates = Demonstrates.EDGE_CASE,
        first = {
            val (leaver, stayer) = players
            leaver.quit()
            within(10.ticks) { stayer sees unlisted(leaver) }
        },
        then = {
            val (leaver, stayer) = players
            probe.chat(players, "Back")

            within(10.ticks) {
                leaver sees chat("Back")
                stayer sees listed(leaver)
            }
        },
    )

    requirement(
        "QUIT-6",
        "a player who quits a Paper of its own and rejoins holds the item Paper kept for it",
        restartsPaper = true,
    ) {
        probe.give(player, slot = 0, item = "diamond")
        probe.selectSlot(player, 0)
        player.quit()

        player.rejoin()

        within(20.ticks) { player sees held("diamond") }
    }
}
