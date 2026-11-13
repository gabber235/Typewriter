package com.typewritermc.playtest.pool

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.io.File
import java.net.InetAddress
import java.net.ServerSocket
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.TimeUnit
import kotlin.io.path.ExperimentalPathApi
import kotlin.io.path.createDirectories
import kotlin.io.path.deleteRecursively
import kotlin.io.path.writeText

/** One game process the pool started, and the log it writes to. */
internal class Part(
    val name: String,
    val process: Process,
    val log: Path,
)

/**
 * The game the pool runs: one stepped Paper and one client, each in a fresh folder of the pool folder,
 * on free loopback ports. [Pool] hears from both over the wire once they are up.
 */
internal class Game private constructor(
    val paperPort: Int,
    val parts: List<Part>,
) {
    /** Stops every part: asks first, then forces whatever still runs. */
    fun stop() {
        parts.forEach { it.process.destroy() }
        parts.forEach { if (!it.process.waitFor(STOP_SECONDS, TimeUnit.SECONDS)) it.process.destroyForcibly() }
    }

    companion object {
        private const val STOP_SECONDS = 10L

        fun start(
            settings: PoolSettings,
            poolPort: Int,
            player: String,
        ): Game {
            val paperPort = freePort()
            val paper = startPaper(settings, poolPort, paperPort)
            val client = runCatching { startClient(settings, poolPort, player) }.onFailure { paper.process.destroyForcibly() }.getOrThrow()
            return Game(paperPort, listOf(paper, client))
        }

        private fun startPaper(
            settings: PoolSettings,
            poolPort: Int,
            port: Int,
        ): Part {
            val dir = freshDir(settings.poolDir.resolve("paper"))
            listOf("versions", "libraries", "cache").forEach { Files.createSymbolicLink(dir.resolve(it), settings.paperDir.resolve(it)) }
            dir.resolve("plugins").createDirectories()
            Files.copy(settings.pluginJar, dir.resolve("plugins/playtest-plugin.jar"))
            dir.resolve("config").createDirectories()
            dir.resolve("config/paper-global.yml").writeText(resource("paper-global.yml"))
            // The pool runs Paper only for the framework, inside its own build folder.
            dir.resolve("eula.txt").writeText("eula=true\n")
            dir.resolve("server.properties").writeText(serverProperties(port))
            val command =
                listOf(
                    settings.java.toString(),
                    "-javaagent:${settings.agentJar}",
                    "-Dplaytest.pool.port=$poolPort",
                    "-jar",
                    settings.paperDir.resolve("paper.jar").toString(),
                    "--nogui",
                )
            return launch("Paper", command, dir, mapOf())
        }

        private fun startClient(
            settings: PoolSettings,
            poolPort: Int,
            player: String,
        ): Part {
            val dir = freshDir(settings.poolDir.resolve("client"))
            dir.resolve("options.txt").writeText(resource("options.txt"))
            val launch = Json.parseToJsonElement(Files.readString(settings.clientLaunch)).jsonObject

            fun strings(key: String) = launch.getValue(key).jsonArray.map { it.jsonPrimitive.content }
            val command =
                buildList {
                    add(settings.java.toString())
                    // Loom's argument files hold what the classpath below already carries.
                    addAll(strings("jvmArgs").filterNot { it.startsWith("@") })
                    add("-Dplaytest.pool.port=$poolPort")
                    add("-Dplaytest.player=$player")
                    add("-cp")
                    add(strings("classpath").joinToString(File.pathSeparator))
                    add(launch.getValue("main").jsonPrimitive.content)
                    addAll(strings("args"))
                    addAll(
                        listOf(
                            "--username",
                            player,
                            "--offlineDeveloperMode",
                            "--gameDir",
                            dir.toString(),
                            "--width",
                            "854",
                            "--height",
                            "480",
                        ),
                    )
                }
            // A background app on macOS: the window never takes focus from the developer.
            return launch("Client", command, dir, mapOf("SDL_MAC_BACKGROUND_APP" to "1"))
        }

        private fun launch(
            name: String,
            command: List<String>,
            dir: Path,
            environment: Map<String, String>,
        ): Part {
            val log = dir.resolve("console.log")
            val builder =
                ProcessBuilder(command)
                    .directory(dir.toFile())
                    .redirectErrorStream(true)
                    .redirectOutput(log.toFile())
                    .redirectInput(ProcessBuilder.Redirect.from(File("/dev/null")))
            builder.environment().putAll(environment)
            return Part(name, builder.start(), log)
        }

        private fun serverProperties(port: Int) =
            listOf(
                "online-mode=false",
                "server-port=$port",
                "server-ip=127.0.0.1",
                "enforce-secure-profile=false",
                "white-list=false",
                "enforce-whitelist=false",
                "spawn-protection=0",
                "difficulty=peaceful",
                "gamemode=creative",
                "pause-when-empty-seconds=-1",
                "level-type=minecraft\\:flat",
                """generator-settings={"layers":[{"block":"minecraft:air","height":1}],"biome":"minecraft:the_void"}""",
                "generate-structures=false",
            ).joinToString("\n", postfix = "\n")

        /** Empties [dir]. Links into the patched Paper are removed, never followed. */
        @OptIn(ExperimentalPathApi::class)
        private fun freshDir(dir: Path): Path {
            dir.deleteRecursively()
            return dir.createDirectories()
        }

        private fun resource(name: String): String =
            checkNotNull(Game::class.java.getResourceAsStream(name)) { "the pool jar has no $name" }.use { String(it.readAllBytes()) }

        private fun freePort(): Int = ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { it.localPort }
    }
}
