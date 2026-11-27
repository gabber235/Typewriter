package com.typewritermc.playtest

import java.nio.file.Path
import kotlin.io.path.Path

/**
 * Where the game pool lives and what the session checks against, as the `gameTest` task passes it in
 * `playtest.*` system properties; the build starts the pool with the same properties.
 */
internal data class PlaytestSettings(
    /** The worktree's pool folder, where the pool file names the running pool. */
    val poolDir: Path,
    /** The run's logs folder: the pool's own log, and one for every Paper, client and display. */
    val logs: Path,
    /** One run of every gameTest task of a build; cases of one run land in one run file. */
    val run: String,
    /** Where the pool writes the run's `TestRun`; each attempt's evidence lies in a folder beside it. */
    val testRun: Path,
) {
    val poolLog: Path get() = logs.resolve("pool.log")

    companion object {
        fun fromSystemProperties(): PlaytestSettings {
            fun required(key: String) =
                checkNotNull(System.getProperty("playtest.$key")) {
                    "playtest.$key is not set: run requirements through a gameTest task, which passes every playtest property"
                }
            return PlaytestSettings(
                poolDir = Path(required("poolDir")),
                logs = Path(required("logs")),
                run = required("run"),
                testRun = Path(required("testRun")),
            )
        }
    }
}
