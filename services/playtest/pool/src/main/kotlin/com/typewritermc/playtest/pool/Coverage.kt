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
 * The plugin code one submission's attempts ran, from the reads of JaCoCo's counts a Paper hands the
 * pool; the Paper decides which attempts a read counts for. The lines a class's counts stand for come
 * from the class as JaCoCo saw it, which its agent dumps into a Paper's class folder: Paper rewrites
 * plugin classes as it loads them, so the plugin jar's own classes would not match. The reads, the last
 * analysis and what both cost stay as long as the submission does.
 */
internal class Coverage {
    private val reads = ExecutionDataStore()
    private var readCount = 0
    private var readNanos = 0L
    private var analyses = 0
    private var analysisNanos = 0L
    private var lastAnalysisAt = 0L

    /** What the submission covered at its last analysis. */
    var latest = listOf<CoveredClass>()
        private set

    /** [exec], one read in JaCoCo's execution data format that held Paper's main thread [readNanos], counts for the submission. */
    fun add(
        exec: ByteArray,
        readNanos: Long = 0,
    ) {
        readCount++
        this.readNanos += readNanos
        ExecutionDataReader(ByteArrayInputStream(exec)).apply {
            setExecutionDataVisitor(reads::put)
            setSessionInfoVisitor(SessionInfoStore())
            read()
        }
    }

    /**
     * Every class the submission ran code of, by name, with the lines of its source that ran: a line ran
     * when any of its instructions did. [classes] is the folder JaCoCo's agent dumped the Paper's classes
     * into; a class not dumped there is left out. The answer stays the submission's [latest]; before any
     * read there is nothing to analyse.
     */
    fun covered(classes: Path): List<CoveredClass> {
        if (readCount == 0) return listOf()
        val start = System.nanoTime()
        val builder = CoverageBuilder()
        val analyzer = Analyzer(reads, builder)
        for (data in reads.contents) {
            if (!data.hasHits()) continue
            val dumped = classes.resolve("%s.%016x.class".format(data.name, data.id))
            if (!Files.isRegularFile(dumped)) continue
            analyzer.analyzeClass(Files.readAllBytes(dumped), data.name)
        }
        latest =
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
        analyses++
        analysisNanos += System.nanoTime() - start
        lastAnalysisAt = System.currentTimeMillis()
        return latest
    }

    /**
     * What the submission's coverage cost, as one step of its record, or null before any read: the main
     * thread time of each Paper read handed to it (a read two attempts share counts for each), and the
     * pool's analyses.
     */
    fun cost(): Step? {
        if (readCount == 0) return null
        return Step(
            atMillis = lastAnalysisAt,
            actor = null,
            says =
                "coverage: $readCount reads held Paper's main thread %.3f ms; $analyses analyses took %.1f ms"
                    .format(Locale.ROOT, readNanos / 1e6, analysisNanos / 1e6),
            durationMillis = analysisNanos / 1_000_000,
        )
    }
}
