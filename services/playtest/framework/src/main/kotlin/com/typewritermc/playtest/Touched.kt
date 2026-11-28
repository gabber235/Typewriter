package com.typewritermc.playtest

import skirout.harness.v1.test_run.CoveredClass
import java.util.concurrent.ConcurrentHashMap

/**
 * The lines the change under test added, by source file as JaCoCo names it (`package/path/File.kt`).
 * `cargo xtask e2e game` writes them against the merge base with the default branch, one file per line:
 * its source, then its added lines, separated by spaces.
 */
internal class Touched private constructor(
    private val lines: Map<String, Set<Int>>,
) {
    /** Whether the change added a line to [code], a requirement's own code. */
    fun touches(code: RequirementLines): Boolean = lines[code.source]?.any { it in code.lines } == true

    /** Whether [covered], the plugin code a requirement ran, holds a line the change added. */
    fun touches(covered: List<CoveredClass>): Boolean =
        covered.any { covering -> lines[covering.source]?.let { added -> covering.lines.any(added::contains) } == true }

    companion object {
        /** No change: a run outside `cargo xtask e2e game` touches nothing. */
        val NONE = Touched(mapOf())

        /** The lines [text], in the format xtask writes, names. */
        fun read(text: String): Touched =
            Touched(
                text
                    .lineSequence()
                    .map { it.trim().split(' ') }
                    .filter { it.first().isNotEmpty() }
                    .associate { fields -> fields.first() to fields.drop(1).map(String::toInt).toSet() },
            )
    }
}

/** Where a requirement's own code is written: its source file as JaCoCo names it, and the lines it spans. */
internal data class RequirementLines(
    val source: String,
    val lines: IntRange,
)

/**
 * The lines that register the requirements of this test JVM, by source file. A requirement's own code
 * spans from the line that registers it to the line before the next requirement of its file, or to the
 * file's end: its body and whatever its file defines below it until the next requirement.
 */
internal class RequirementSources {
    private val registered = ConcurrentHashMap<String, MutableSet<Int>>()

    /**
     * Notes a requirement registered at [frame], its line in the requirement's own source; returns its
     * lines, to read once every requirement registered.
     */
    fun register(frame: StackTraceElement): () -> RequirementLines {
        val packagePath = frame.className.substringBeforeLast('.', "").replace('.', '/')
        val source = if (packagePath.isEmpty()) "${frame.fileName}" else "$packagePath/${frame.fileName}"
        val line = frame.lineNumber
        registered.computeIfAbsent(source) { ConcurrentHashMap.newKeySet() } += line
        return {
            val next = registered.getValue(source).filter { it > line }.minOrNull()
            RequirementLines(source, line..(next?.minus(1) ?: Int.MAX_VALUE))
        }
    }

    companion object {
        /** This test JVM's requirements. */
        val current = RequirementSources()
    }
}
