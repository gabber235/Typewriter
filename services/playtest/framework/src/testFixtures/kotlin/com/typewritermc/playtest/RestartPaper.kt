package com.typewritermc.playtest

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Runs [restart], a restart of the Paper of [player]'s attempt, and ends the new Paper process at once
 * as soon as it starts, as a Paper that crashes while it boots would.
 */
suspend fun <T> RequirementScope.killPaperWhileItBoots(
    player: GamePlayer,
    restart: suspend () -> T,
): T =
    coroutineScope {
        val killed = paperProcess(player)?.pid()
        val killer =
            launch(Dispatchers.IO) {
                while (isActive) {
                    val booting = paperProcess(player)?.takeIf { it.pid() != killed }
                    if (booting != null) {
                        booting.destroyForcibly()
                        break
                    }
                    delay(KILL_POLL_MILLIS)
                }
            }
        try {
            restart()
        } finally {
            killer.cancel()
        }
    }

private const val KILL_POLL_MILLIS = 10L

/** The process of the Paper [player]'s attempt runs on, one of its own, named after its first player. */
private fun paperProcess(player: GamePlayer): ProcessHandle? =
    ProcessHandle.allProcesses().toList().firstOrNull { process ->
        process
            .info()
            .arguments()
            .orElse(arrayOf())
            .contains("-Dplaytest.paper.name=paper-${player.name}")
    }
