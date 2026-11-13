package com.typewritermc.playtest

import java.nio.file.Path
import kotlin.io.path.Path

/**
 * Where the game pool lives and what it runs, as the `gameTest` task passes it in `playtest.*`
 * system properties. The pool reads the same properties, so the session forwards every one of them.
 */
internal data class PlaytestSettings(
    /** The worktree's pool folder: its lock, its port and its log. */
    val poolDir: Path,
    /** The pool process's own classpath. */
    val poolClasspath: String,
    /** The Java that runs the pool, Paper and the client. */
    val java: Path,
    /** One run of every gameTest task of a build; cases of one run land in one run file. */
    val run: String,
    /** Where the pool writes the run's `TestRun`. */
    val testRun: Path,
    /** Every `playtest.*` property, for the pool. */
    val forwarded: Map<String, String>,
) {
    val poolLog: Path get() = poolDir.resolve("pool.log")

    companion object {
        fun fromSystemProperties(): PlaytestSettings {
            val forwarded =
                System
                    .getProperties()
                    .stringPropertyNames()
                    .filter { it.startsWith("playtest.") }
                    .associateWith { System.getProperty(it) }

            fun required(key: String) =
                checkNotNull(forwarded["playtest.$key"]) {
                    "playtest.$key is not set: run requirements through a gameTest task, which passes every playtest property"
                }
            return PlaytestSettings(
                poolDir = Path(required("poolDir")),
                poolClasspath = required("poolClasspath"),
                java = Path(required("java")),
                run = required("run"),
                testRun = Path(required("testRun")),
                forwarded = forwarded,
            )
        }
    }
}
