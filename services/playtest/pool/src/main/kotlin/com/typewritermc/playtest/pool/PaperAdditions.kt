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
 * attempt's own: one folder per module, as its `gameTest { paper { ... } }` declares it. A folder holds
 * [FILES], copied into Paper's folder at the same paths (plugin jars under `plugins/`), and [ENV], the
 * environment Paper starts with. The pool takes the union of every module's additions, as every module
 * shares its Papers; two modules that disagree on a file or a variable fail before any Paper starts.
 */
internal class PaperAdditions(
    private val dirs: List<Path>,
) {
    /** Copies every module's files into the Paper folder [paper]. */
    fun copyInto(paper: Path) {
        files().forEach { (path, source) ->
            val target = paper.resolve(path)
            target.parent.createDirectories()
            Files.copy(source, target)
        }
    }

    /** The environment every module sets for Paper. */
    val environment: Map<String, String>
        get() {
            val set = mutableMapOf<String, Pair<String, Path>>()
            dirs.map { it.resolve(ENV) }.filter { it.exists() }.forEach { file ->
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
    }
}
