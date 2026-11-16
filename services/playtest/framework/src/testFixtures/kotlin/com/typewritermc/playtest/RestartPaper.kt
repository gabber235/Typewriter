package com.typewritermc.playtest

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Runs [restart], a restart of the attempt's own Paper, and ends the new Paper process at once as soon
 * as it starts, as a Paper that crashes while it boots would.
 */
suspend fun <T> RequirementScope.killPaperWhileItBoots(restart: suspend () -> T): T =
    coroutineScope {
        val killed = paperProcess(attempt.paper)?.pid()
        val killer =
            launch(Dispatchers.IO) {
                while (isActive) {
                    val booting = paperProcess(attempt.paper)?.takeIf { it.pid() != killed }
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

/** The process of the Paper named [paper]. */
private fun paperProcess(paper: String): ProcessHandle? =
    ProcessHandle.allProcesses().toList().firstOrNull { process ->
        process
            .info()
            .arguments()
            .orElse(arrayOf())
            .contains("-Dplaytest.paper.name=$paper")
    }
