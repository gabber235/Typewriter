package com.typewritermc.playtest.pool

import org.jacoco.core.analysis.Analyzer
import org.jacoco.core.analysis.CoverageBuilder
import org.jacoco.core.data.ExecutionDataReader
import org.jacoco.core.data.ExecutionDataStore
import org.jacoco.core.data.SessionInfoStore
import skirout.harness.v1.test_run.CoveredClass
import skirout.harness.v1.test_run.Step
import java.io.ByteArrayInputStream
import java.nio.file.Files
import java.nio.file.Path
import java.util.Locale

/**
 * The plugin code each attempt ran, kept under [K], from the reads of JaCoCo's counts a Paper hands
 * the pool; the Paper decides which attempts a read counts for. The lines a class's counts stand for
 * come from the class as JaCoCo saw it, which its agent dumps into a Paper's class folder: Paper
 * rewrites plugin classes as it loads them, so the plugin jar's own classes would not match. Each
 * attempt's reads, its last analysis and what both cost stay until the attempt is forgotten.
 */
internal class Coverage<K> {
    /** One attempt's reads, the lines they came to at its last analysis, and what reading and analysing cost. */
    private class Ran {
        val reads = ExecutionDataStore()
        var latest = listOf<CoveredClass>()
        var readCount = 0
        var readNanos = 0L
        var analyses = 0
        var analysisNanos = 0L
        var lastAnalysisAt = 0L
    }

    private val ran = mutableMapOf<K, Ran>()

    /** [exec], one read in JaCoCo's execution data format that held Paper's main thread [readNanos], counts for the attempt [key]. */
    fun add(
        key: K,
        exec: ByteArray,
        readNanos: Long = 0,
    ) {
        val attempt = ran.getOrPut(key, ::Ran)
        attempt.readCount++
        attempt.readNanos += readNanos
        ExecutionDataReader(ByteArrayInputStream(exec)).apply {
            setExecutionDataVisitor(attempt.reads::put)
            setSessionInfoVisitor(SessionInfoStore())
            read()
        }
    }

    /**
     * Every class the attempt [key] ran code of, by name, with the lines of its source that ran: a line
     * ran when any of its instructions did. [classes] is the folder JaCoCo's agent dumped the Paper's
     * classes into; a class not dumped there is left out. The answer stays the attempt's [latest].
     */
    fun covered(
        key: K,
        classes: Path,
    ): List<CoveredClass> {
        val attempt = ran[key] ?: return listOf()
        val start = System.nanoTime()
        val builder = CoverageBuilder()
        val analyzer = Analyzer(attempt.reads, builder)
        for (data in attempt.reads.contents) {
            if (!data.hasHits()) continue
            val dumped = classes.resolve("%s.%016x.class".format(data.name, data.id))
            if (!Files.isRegularFile(dumped)) continue
            analyzer.analyzeClass(Files.readAllBytes(dumped), data.name)
        }
        attempt.latest =
            builder.classes
                .filter { it.sourceFileName != null }
                .map { covered ->
                    val lines =
                        (covered.firstLine..covered.lastLine).filter { line ->
                            covered.firstLine > 0 && covered.getLine(line).instructionCounter.coveredCount > 0
                        }
                    CoveredClass(
                        name = covered.name,
                        source = "${covered.packageName}/${covered.sourceFileName}".removePrefix("/"),
                        lines = lines,
                    )
                }.filter { it.lines.isNotEmpty() }
                .sortedBy { it.name }
        attempt.analyses++
        attempt.analysisNanos += System.nanoTime() - start
        attempt.lastAnalysisAt = System.currentTimeMillis()
        return attempt.latest
    }

    /** What the attempt [key] covered at its last analysis. */
    fun latest(key: K): List<CoveredClass> = ran[key]?.latest.orEmpty()

    /**
     * What the attempt [key]'s coverage cost, as one step of its record: the main thread time of each
     * Paper read handed to it (a read two attempts share counts for each), and the pool's analyses.
     */
    fun cost(key: K): Step? {
        val attempt = ran[key] ?: return null
        return Step(
            atMillis = attempt.lastAnalysisAt,
            actor = null,
            says =
                "coverage: ${attempt.readCount} reads held Paper's main thread %.3f ms; ${attempt.analyses} analyses took %.1f ms"
                    .format(Locale.ROOT, attempt.readNanos / 1e6, attempt.analysisNanos / 1e6),
            durationMillis = attempt.analysisNanos / 1_000_000,
        )
    }

    /** The attempt [key] ended; its reads go. */
    fun forget(key: K) {
        ran -= key
    }

    /** Every attempt whose key matches [where] ended without its result, as a session that left: their reads go. */
    fun forget(where: (K) -> Boolean) {
        ran.keys.removeIf(where)
    }
}
