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
import java.util.zip.ZipFile
import kotlin.io.path.ExperimentalPathApi
import kotlin.io.path.createDirectories
import kotlin.io.path.deleteRecursively
import kotlin.io.path.writeText

/** One game process the pool started, and the log it writes to; [player] for a client. */
internal class Part(
    val name: String,
    val process: Process,
    val log: Path,
    val player: String? = null,
)

/**
 * The folder, port and log of a Paper the pool runs; every boot of a restart attempt's own Paper reuses
 * them, its log adding to the one before.
 */
internal class PaperFolder(
    val name: String,
    val dir: Path,
    val port: Int,
    val log: Path,
) {
    /** Where the JaCoCo agent dumps each plugin class as Paper defined it, which its counts refer to. */
    val classes: Path get() = classesIn(dir)
}

/** The folder in the Paper folder [dir] that the JaCoCo agent dumps the plugin classes into. */
private fun classesIn(dir: Path): Path = dir.resolve("coverage-classes")

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
 * of its own), each in a fresh folder of the pool folder, on free loopback ports, and each logging into the
 * run's logs folder as `<part>.log`. [Pool] hears from all of them over the wire once they are up.
 */
internal class Game private constructor(
    private val settings: PoolSettings,
    private val poolPort: Int,
    val paper: PaperFolder,
    val paperPart: Part,
    private val input: InputPath,
    private val displays: Map<String, Display>,
    started: List<Part>,
) {
    private val running = started.toMutableList()
    private var lost = 0

    /** Every part that runs now, a replaced client's new process in place of its old one. */
    val parts: List<Part> @Synchronized get() = running.toList()

    /** A lost client's [replacement], and where the lost client's log is kept. */
    class Replaced(
        val replacement: Part,
        val lostLog: Path,
    )

    /**
     * Ends [player]'s client process, whatever state it is in, keeps its log as `client-<player>-lost-<n>.log`,
     * and starts a new client in a fresh folder, which joins as the same player.
     */
    @Synchronized
    fun replaceClient(player: String): Replaced {
        running.filter { it.player == player }.forEach {
            it.process.destroyForcibly()
            it.process.waitFor(STOP_SECONDS, TimeUnit.SECONDS)
            running -= it
        }
        val kept = settings.logs.resolve("client-$player-lost-${++lost}.log")
        Files.move(logOf(settings, "client-$player"), kept)
        val replacement = startClient(settings, poolPort, player, input, displays[player])
        running += replacement
        return Replaced(replacement, kept)
    }

    /**
     * A fresh folder and free port for [name], a restart attempt's own Paper, set up as the shared
     * Paper's folder is. A folder of that name an earlier pool run left goes.
     */
    fun ownFolder(name: String): PaperFolder {
        val folder = PaperFolder(name, settings.poolDir.resolve(name), freePort(), logOf(settings, name))
        preparePaper(settings, folder.dir, folder.port)
        return folder
    }

    /** Boots [folder]'s Paper with [flags] added; a boot after the first adds to the same log. */
    @Synchronized
    fun bootOwn(
        folder: PaperFolder,
        flags: List<String>,
        again: Boolean,
    ): Part = startPaper(settings, poolPort, folder, flags, append = again).also { running += it }

    /** [part] ended and is no longer a part of the game. */
    @Synchronized
    fun forget(part: Part) {
        running -= part
    }

    /** Removes the folder of an own Paper whose attempt ended. */
    fun removeOwn(folder: PaperFolder) = remove(folder.dir)

    /** Stops every part: asks first, then forces whatever still runs. */
    fun stop() {
        val all = parts
        all.forEach { it.process.destroy() }
        all.forEach { if (!it.process.waitFor(STOP_SECONDS, TimeUnit.SECONDS)) it.process.destroyForcibly() }
    }

    companion object {
        private const val STOP_SECONDS = 10L

        fun start(
            settings: PoolSettings,
            poolPort: Int,
            players: List<String>,
        ): Game {
            // The restart Papers of a pool that ended without removing them, and the logs of an earlier run
            // in the same logs folder, are not this run's; the pool's own log is, and it emptied it.
            Files
                .list(settings.poolDir)
                .use { dirs ->
                    dirs.filter { it.fileName.toString().startsWith(OWN_PAPER) }.toList()
                }.forEach { remove(it) }
            Files.list(settings.logs).use { logs -> logs.filter { it != settings.poolLog }.toList() }.forEach { remove(it) }
            val paper = PaperFolder("paper", settings.poolDir.resolve("paper"), freePort(), logOf(settings, "paper"))
            preparePaper(settings, paper.dir, paper.port)
            val paperPart = startPaper(settings, poolPort, paper, listOf(), append = false)
            val started = mutableListOf(paperPart)
            val input = InputPath.here()
            val displays = mutableMapOf<String, Display>()
            runCatching {
                for (player in players) {
                    val display =
                        if (input == InputPath.XTEST) {
                            startDisplay(settings, player).also {
                                started += it.part
                                displays[player] = it
                            }
                        } else {
                            null
                        }
                    started += startClient(settings, poolPort, player, input, display)
                }
            }.onFailure { started.forEach { it.process.destroyForcibly() } }.getOrThrow()
            return Game(settings, poolPort, paper, paperPart, input, displays, started)
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
            val log = logOf(settings, "display-$player")
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

        /** The name every restart attempt's own Paper starts with, followed by its attempt: `paper-a23`. */
        const val OWN_PAPER = "paper-a"

        /** A fresh Paper folder in [dir] that serves on [port]. */
        private fun preparePaper(
            settings: PoolSettings,
            dir: Path,
            port: Int,
        ) {
            freshDir(dir)
            listOf("versions", "libraries", "cache").forEach { Files.createSymbolicLink(dir.resolve(it), settings.paperDir.resolve(it)) }
            dir.resolve("plugins").createDirectories()
            Files.copy(settings.pluginJar, dir.resolve("plugins/playtest-plugin.jar"))
            dir.resolve("config").createDirectories()
            dir.resolve("config/paper-global.yml").writeText(resource("paper-global.yml"))
            // The pool runs Paper only for the framework, inside its own build folder.
            dir.resolve("eula.txt").writeText("eula=true\n")
            dir.resolve("server.properties").writeText(serverProperties(port))
        }

        /**
         * Starts the Paper in [folder], with [flags] before the rest. It starts the patched server on its
         * class path directly, as Paperclip would after its patch check: Java's ahead of time cache holds
         * only classes the JVM's own loaders load, never those of Paperclip's loader.
         */
        private fun startPaper(
            settings: PoolSettings,
            poolPort: Int,
            folder: PaperFolder,
            flags: List<String>,
            append: Boolean,
        ): Part {
            val (name, dir) = folder.name to folder.dir
            val server = PaperServer.of(settings.paperDir)
            val command =
                buildList {
                    add(settings.java.toString())
                    addAll(flags)
                    add("-javaagent:${settings.agentJar}")
                    add("-javaagent:${settings.coverageAgentJar}=${coverageOptions(settings, dir)}")
                    add("-Dplaytest.pool.port=$poolPort")
                    add("-Dplaytest.paper.name=$name")
                    add("-cp")
                    add(server.classPath.joinToString(File.pathSeparator))
                    add(server.mainClass)
                    add("--nogui")
                }
            return launch(if (name == "paper") "Paper" else "Paper $name", command, dir, folder.log, mapOf(), append = append)
        }

        /**
         * The JaCoCo agent counts only the classes of the plugins Paper loads, never Paper's or
         * Minecraft's, so its counts cost nothing measurable; it writes no file, as the plugin reads the
         * counts in process, and dumps each plugin class into the Paper folder [dir] as Paper defined it.
         */
        private fun coverageOptions(
            settings: PoolSettings,
            dir: Path,
        ): String {
            val packages =
                ZipFile(settings.pluginJar.toFile()).use { jar ->
                    jar
                        .entries()
                        .asSequence()
                        .map { it.name }
                        .filter { it.endsWith(".class") && '/' in it }
                        .map { it.substringBeforeLast('/').replace('/', '.') }
                        .toSortedSet()
                }
            return listOf(
                "output=none",
                "dumponexit=false",
                "jmx=false",
                "includes=${packages.joinToString(":") { "$it.*" }}",
                "classdumpdir=${classesIn(dir)}",
            ).joinToString(",")
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
            return launch("Client $player", command, dir, logOf(settings, "client-$player"), environment, player)
        }

        private fun launch(
            name: String,
            command: List<String>,
            dir: Path,
            log: Path,
            environment: Map<String, String>,
            player: String? = null,
            append: Boolean = false,
        ): Part {
            val builder =
                ProcessBuilder(command)
                    .directory(dir.toFile())
                    .redirectErrorStream(true)
                    .redirectOutput(
                        if (append) ProcessBuilder.Redirect.appendTo(log.toFile()) else ProcessBuilder.Redirect.to(log.toFile()),
                    ).redirectInput(ProcessBuilder.Redirect.from(File("/dev/null")))
            builder.environment().putAll(environment)
            return Part(name, builder.start(), log, player)
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

        /** Where the part [name] logs: `<name>.log` in the run's logs folder. */
        private fun logOf(
            settings: PoolSettings,
            name: String,
        ): Path = settings.logs.resolve("$name.log")

        /** Removes [dir] and all in it. */
        @OptIn(ExperimentalPathApi::class)
        private fun remove(dir: Path) = dir.deleteRecursively()

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

/** How the patched Paper starts without Paperclip: its class path, in the order Paperclip loads it, and its main class. */
internal class PaperServer(
    val classPath: List<Path>,
    val mainClass: String,
) {
    companion object {
        /** The launch of the patched Paper in [paperDir], from the lists its Paperclip jar carries. */
        fun of(paperDir: Path): PaperServer =
            ZipFile(paperDir.resolve("paper.jar").toFile()).use { jar ->
                fun lines(entry: String) =
                    jar
                        .getInputStream(checkNotNull(jar.getEntry(entry)) { "the Paperclip jar in $paperDir has no $entry" })
                        .bufferedReader()
                        .readLines()
                        .filter(String::isNotBlank)

                // Each line is a hash, an id and the jar's path below its folder, apart by tabs.
                fun jars(
                    entry: String,
                    folder: String,
                ) = lines(entry).map { paperDir.resolve(folder).resolve(it.split('\t')[2]) }
                PaperServer(
                    jars("META-INF/versions.list", "versions") + jars("META-INF/libraries.list", "libraries"),
                    lines("META-INF/main-class").single().trim(),
                )
            }
    }
}
