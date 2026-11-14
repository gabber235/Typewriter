package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.TestSuiteScope
import de.infix.testBalloon.framework.shared.TestElementName
import de.infix.testBalloon.framework.shared.TestRegistering
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.string.shouldContain
import java.nio.file.Path

/**
 * Registers a requirement of the framework's own test kit in which [lose] makes one attempt lose its
 * client while the attempt beside it waits in a window. That attempt keeps its exact verdicts, and an
 * attempt on the whole pool afterward, which runs only once the lost client's replacement is ready,
 * proves every client serves again.
 */
@TestRegistering
fun TestSuiteScope.clientLostAlongside(
    @TestElementName id: String,
    sentence: String,
    lose: suspend RequirementScope.() -> Unit,
) = alongside(
    id,
    sentence,
    busy = { otherWaits ->
        probe.chat(player, "Hello")
        otherWaits.await()
        lose()
    },
    other = { waiting ->
        val hello = probe.chat(player, "Hello")

        val missed = cueOnceOpen(waiting) { shouldThrow<WindowMissed> { within(20.ticks) { player sees chat("Goodbye") } } }

        missed.report shouldContain
            "${player.name} did not see chat \"Goodbye\" within 20 ticks (ticks ${hello.tick + 1} to ${hello.tick + 20})"
        within(10.ticks) { player sees chat("Hello") }
    },
    afterwardPlayers = 4,
    afterward = {
        probe.chat(players, "Fresh")

        within(10.ticks) { players.forEach { it sees chat("Fresh") } }
    },
)

/** Ends [player]'s client process at once, as a crash would; the pool notices and replaces the client. */
fun RequirementScope.crashClient(player: GamePlayer) {
    clientProcess(player).destroyForcibly()
}

/**
 * Freezes [player]'s client process, as a hung game would, and runs [frozen]. The pool replaces the
 * client; whatever happens, the frozen process is gone once [frozen] returns.
 */
suspend fun <T> RequirementScope.freezeClient(
    player: GamePlayer,
    frozen: suspend () -> T,
): T {
    val client = clientProcess(player)
    val stop = ProcessBuilder("kill", "-STOP", client.pid().toString()).start()
    check(stop.waitFor() == 0) { "could not freeze the client process of ${player.name}" }
    try {
        return frozen()
    } finally {
        client.destroyForcibly()
    }
}

/** The process of [player]'s client: the one whose game folder is the player's folder in the pool. */
private fun clientProcess(player: GamePlayer): ProcessHandle {
    val gameDir = PlaytestSettings.fromSystemProperties().poolDir.resolve("client-${player.name}")
    val client =
        ProcessHandle.allProcesses().toList().firstOrNull { process ->
            val arguments =
                process
                    .info()
                    .arguments()
                    .orElse(arrayOf())
                    .toList()
            arguments.zipWithNext().any { (flag, value) -> flag == "--gameDir" && Path.of(value) == gameDir }
        }
    return checkNotNull(client) { "no client process plays ${player.name} in $gameDir" }
}
