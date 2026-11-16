package com.typewritermc.playtest

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.nio.file.Path

/**
 * Runs [restart], a restart of the attempt's own Paper, and ends the new Paper process at once as soon
 * as it starts, as a Paper that crashes while it boots would.
 */
suspend fun <T> RequirementScope.killPaperWhileItBoots(restart: suspend () -> T): T =
    coroutineScope {
        val killed = partProcess(attempt.paper)?.pid()
        val killer =
            launch(Dispatchers.IO) {
                while (isActive) {
                    val booting = partProcess(attempt.paper)?.takeIf { it.pid() != killed }
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

/** The folder the pool, every Paper and every client of this run log into. */
val runLogs: Path get() = PlaytestSettings.fromSystemProperties().logs
