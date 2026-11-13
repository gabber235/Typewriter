package com.typewritermc.playtest.pool

import java.nio.file.Path

/**
 * Where the pool lives and what it launches. The first test JVM starts the pool with every
 * `-Dplaytest.*` property its game test task set.
 */
internal class PoolSettings(
    val poolDir: Path,
    val java: Path,
    val paperDir: Path,
    val agentJar: Path,
    val pluginJar: Path,
    val clientLaunch: Path,
) {
    companion object {
        fun fromSystemProperties() =
            PoolSettings(
                poolDir = path("playtest.poolDir"),
                java = path("playtest.java"),
                paperDir = path("playtest.paper"),
                agentJar = path("playtest.agent"),
                pluginJar = path("playtest.plugin"),
                clientLaunch = path("playtest.clientLaunch"),
            )

        private fun path(name: String): Path =
            Path.of(checkNotNull(System.getProperty(name)) { "$name is not set: the game test task sets it" })
    }
}
