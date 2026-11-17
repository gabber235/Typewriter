package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.HeapShare
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.io.File
import java.nio.file.Files
import java.nio.file.Path

/**
 * The command line of each game part the pool starts. Each JVM's heap is capped at its kind's share of
 * the machine ([HeapShare]), so the parts that can run at once fit in half of it.
 */
internal object Launches {
    /** The shared Paper in [folder], counting coverage with the JaCoCo agent's [coverage] options. */
    fun sharedPaper(
        settings: PoolSettings,
        poolPort: Int,
        folder: PaperFolder,
        server: PaperServer,
        coverage: String,
    ): List<String> = paper(settings, poolPort, folder, server, coverage, HeapShare.PAPER, listOf())

    /** A restart attempt's own Paper in [folder], with [flags] before the rest. */
    fun ownPaper(
        settings: PoolSettings,
        poolPort: Int,
        folder: PaperFolder,
        server: PaperServer,
        coverage: String,
        flags: List<String>,
    ): List<String> = paper(settings, poolPort, folder, server, coverage, HeapShare.OWN_PAPER, flags)

    /**
     * [player]'s client in [dir], from the launch Loom wrote, its input arriving by [input].
     */
    fun client(
        settings: PoolSettings,
        poolPort: Int,
        player: String,
        input: InputPath,
        dir: Path,
    ): List<String> {
        val launch = Json.parseToJsonElement(Files.readString(settings.clientLaunch)).jsonObject

        fun strings(key: String) = launch.getValue(key).jsonArray.map { it.jsonPrimitive.content }
        return buildList {
            add(settings.java.toString())
            // Loom's argument files hold what the classpath below already carries.
            addAll(strings("jvmArgs").filterNot { it.startsWith("@") })
            add(HeapShare.CLIENT.flag())
            add("-Dplaytest.pool.port=$poolPort")
            add("-Dplaytest.player=$player")
            add("-Dplaytest.input=${input.property}")
            add("-cp")
            add(strings("classpath").joinToString(File.pathSeparator))
            add(launch.getValue("main").jsonPrimitive.content)
            addAll(strings("args"))
            addAll(listOf("--username", player, "--offlineDeveloperMode", "--gameDir", dir.toString(), "--width", "854", "--height", "480"))
        }
    }

    /**
     * A Paper in [folder] with its heap capped at [share]. It starts the patched server on its class
     * path directly, as Paperclip would after its patch check: Java's ahead of time cache holds only
     * classes the JVM's own loaders load, never those of Paperclip's loader.
     */
    private fun paper(
        settings: PoolSettings,
        poolPort: Int,
        folder: PaperFolder,
        server: PaperServer,
        coverage: String,
        share: HeapShare,
        flags: List<String>,
    ): List<String> =
        buildList {
            add(settings.java.toString())
            add(share.flag())
            addAll(flags)
            add("-javaagent:${settings.agentJar}")
            add("-javaagent:${settings.coverageAgentJar}=$coverage")
            add("-Dplaytest.pool.port=$poolPort")
            add("-Dplaytest.paper.name=${folder.name}")
            add("-cp")
            add(server.classPath.joinToString(File.pathSeparator))
            add(server.mainClass)
            add("--nogui")
        }
}
