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

/** A virtual X display and the Xvfb process that serves it. */
internal class Display(
    val name: String,
    val part: Part,
)

/**
 * How the client's input enters its window: on Linux XTest on a virtual display of its own, elsewhere SDL
 * events pushed into the client's own queue, since the developer's desktop must never receive input.
 */
internal enum class InputPath(
    val property: String,
) {
    SDL("sdl"),
    XTEST("xtest"),
    ;

    companion object {
        fun here(): InputPath = if (System.getProperty("os.name").startsWith("Linux")) XTEST else SDL
    }
}

/**
 * The game the pool runs: one stepped Paper and a client per player (on Linux each with a virtual display
 * of its own), each in a fresh folder of the pool folder, on free loopback ports. [Pool] hears from all of
 * them over the wire once they are up.
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
            players: List<String>,
        ): Game {
            val paperPort = freePort()
            val paper = startPaper(settings, poolPort, paperPort)
            val started = mutableListOf(paper)
            runCatching {
                val input = InputPath.here()
                for (player in players) {
                    val display = if (input == InputPath.XTEST) startDisplay(settings, player).also { started += it.part } else null
                    started += startClient(settings, poolPort, player, input, display)
                }
            }.onFailure { started.forEach { it.process.destroyForcibly() } }.getOrThrow()
            return Game(paperPort, started)
        }

        /**
         * A virtual X display of the client's own, so the input XTest sends there reaches no other window.
         * Xvfb picks a free display number and writes it to its standard output.
         */
        private fun startDisplay(
            settings: PoolSettings,
            player: String,
        ): Display {
            val dir = freshDir(settings.poolDir.resolve("display-$player"))
            val log = dir.resolve("console.log")
            val process =
                ProcessBuilder("Xvfb", "-displayfd", "1", "-screen", "0", "1280x720x24", "-nolisten", "tcp")
                    .directory(dir.toFile())
                    .redirectError(log.toFile())
                    .redirectInput(ProcessBuilder.Redirect.from(File("/dev/null")))
                    .start()
            val number =
                process.inputStream
                    .bufferedReader()
                    .readLine()
                    ?.trim()
            if (number.isNullOrEmpty() || number.toIntOrNull() == null) {
                process.destroyForcibly()
                error("Xvfb started no display; see $log")
            }
            return Display(":$number", Part("Display of $player", process, log))
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
            input: InputPath,
            display: Display?,
        ): Part {
            val dir = freshDir(settings.poolDir.resolve("client-$player"))
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
                    add("-Dplaytest.input=${input.property}")
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
            val environment =
                when (input) {
                    // A background app on macOS: the window never takes focus from the developer.
                    InputPath.SDL -> mapOf("SDL_MAC_BACKGROUND_APP" to "1")

                    InputPath.XTEST -> mapOf("DISPLAY" to checkNotNull(display).name)
                }
            return launch("Client $player", command, dir, environment)
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

        // An empty world over one bedrock layer: a player waits on the ground while probes step Paper. Paper
        // sends chunks only as far as the clients draw them.
        private fun serverProperties(port: Int) =
            listOf(
                "view-distance=${clientRenderDistance()}",
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
                """generator-settings={"layers":[{"block":"minecraft:bedrock","height":1}],"biome":"minecraft:the_void"}""",
                "generate-structures=false",
            ).joinToString("\n", postfix = "\n")

        /** The render distance every client's options set, so Paper sends no chunk a client never draws. */
        private fun clientRenderDistance(): Int =
            resource("options.txt")
                .lines()
                .first { it.startsWith("renderDistance:") }
                .substringAfter(':')
                .trim()
                .toInt()

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
