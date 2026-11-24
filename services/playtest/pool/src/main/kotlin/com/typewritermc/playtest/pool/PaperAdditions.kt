package com.typewritermc.playtest.pool

import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties
import kotlin.io.path.createDirectories
import kotlin.io.path.exists
import kotlin.io.path.isRegularFile
import kotlin.io.path.reader
import kotlin.io.path.relativeTo

/**
 * What the build's game modules add to every Paper the pool boots, the shared one and each restart
 * attempt's own: one folder per module, as its `gamePaper { ... }` declares it. A folder holds [FILES],
 * copied into Paper's folder at the same paths (plugin jars under `plugins/`), [ENV], the environment
 * every Paper starts with, `slots/<n>/`[ENV], what only the Paper of slot n adds to it, and [KEPT], the
 * paths in a Paper's folder its slot keeps for the slot's next Paper ([SlotKeep]). The pool takes the
 * union of every module's additions, as every module shares its Papers; two modules that disagree on a
 * file or a variable fail before any Paper starts.
 *
 * A value may take a variable of [run], the environment the game suite runs in, as `${NAME}`: the build
 * writes the additions whatever runs around it, and each Paper's boot fills them in, so a value only the
 * running stack knows never holds back the build.
 */
internal class PaperAdditions(
    private val dirs: List<Path>,
    private val run: Map<String, String> = System.getenv(),
) {
    /** Copies every module's files into the Paper folder [paper]. */
    fun copyInto(paper: Path) {
        files().forEach { (path, source) ->
            val target = paper.resolve(path)
            target.parent.createDirectories()
            Files.copy(source, target)
        }
    }

    /**
     * The environment of the Paper in slot [slot]: what every module sets for every Paper and for that
     * slot, each `${NAME}` filled in from [run], and [SLOT_VARIABLE], the slot itself. A variable [run]
     * does not set fails naming it.
     */
    fun environment(slot: Int): Map<String, String> {
        val files = dirs.flatMap { listOf(it.resolve(ENV), it.resolve(SLOTS).resolve(slot.toString()).resolve(ENV)) }
        return union(files).mapValues { (name, value) -> filledIn(name, value) } + (SLOT_VARIABLE to slot.toString())
    }

    private fun filledIn(
        name: String,
        value: String,
    ): String =
        RUN_VARIABLE.replace(value) { reference ->
            val variable = reference.groupValues[1]
            checkNotNull(run[variable]) {
                "Paper's environment variable $name takes $variable from the environment the game suite runs in, which does not set it"
            }
        }

    /** The paths every module keeps per slot, each once, in the order the modules name them. */
    val kept: List<String>
        get() =
            dirs
                .map { it.resolve(KEPT) }
                .filter { it.exists() }
                .flatMap { Files.readAllLines(it) }
                .map(String::trim)
                .filter(String::isNotEmpty)
                .distinct()

    /** Every variable the properties [files] set; a name two files set to different values fails naming both. */
    private fun union(files: List<Path>): Map<String, String> {
        val set = mutableMapOf<String, Pair<String, Path>>()
        files.filter { it.exists() }.forEach { file ->
            val properties = Properties().apply { file.reader().use(::load) }
            properties.stringPropertyNames().forEach { name ->
                val value = properties.getProperty(name)
                val earlier = set.putIfAbsent(name, value to file)
                check(earlier == null || earlier.first == value) {
                    "Paper's environment variable $name is set to \"${earlier!!.first}\" by ${earlier.second} and to \"$value\" by $file"
                }
            }
        }
        return set.mapValues { it.value.first }
    }

    /** Every module's file by its path in Paper's folder, once each; a path two modules fill differently fails. */
    private fun files(): Map<String, Path> {
        val files = mutableMapOf<String, Path>()
        dirs.map { it.resolve(FILES) }.filter { it.exists() }.forEach { root ->
            Files.walk(root).use { walk -> walk.filter { it.isRegularFile() }.toList() }.forEach { source ->
                val path = source.relativeTo(root).joinToString("/")
                val earlier = files.putIfAbsent(path, source)
                check(earlier == null || Files.mismatch(earlier, source) == -1L) {
                    "$path goes into Paper's folder from two game modules with different content: $earlier and $source"
                }
            }
        }
        return files
    }

    companion object {
        /** The folder of an addition whose files go into Paper's folder. */
        const val FILES = "files"

        /** The properties file of an addition that names Paper's environment. */
        const val ENV = "env.properties"

        /** The folder of an addition with one folder per slot, each with what only that slot's Paper adds. */
        const val SLOTS = "slots"

        /** The file of an addition that lists, one per line, the paths a slot keeps for its next Paper. */
        const val KEPT = "kept.txt"

        /** The variable every Paper finds its slot in: 0 for the shared Paper, 1 and up for own Papers. */
        const val SLOT_VARIABLE = "PLAYTEST_PAPER_SLOT"

        /** A variable of the run's environment in a value, as `gamePaper.fromRun` writes it. */
        private val RUN_VARIABLE = Regex("""\$\{([A-Za-z_][A-Za-z0-9_]*)}""")
    }
}
