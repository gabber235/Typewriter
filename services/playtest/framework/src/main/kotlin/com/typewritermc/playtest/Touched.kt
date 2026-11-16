package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.CoveredClass

/**
 * The lines the change under test added, by source file as JaCoCo names it (`package/path/File.kt`).
 * `cargo xtask e2e game` writes them against the merge base with the default branch, one file per line:
 * its source, then its added lines, separated by spaces.
 */
internal class Touched private constructor(
    private val lines: Map<String, Set<Int>>,
) {
    /** Whether [covered], the plugin code a requirement ran, holds a line the change added. */
    fun touches(covered: List<CoveredClass>): Boolean =
        covered.any { covering -> lines[covering.source()]?.let { added -> covering.lines().any(added::contains) } == true }

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
