package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message.CoveredClass
import org.jacoco.core.analysis.Analyzer
import org.jacoco.core.analysis.CoverageBuilder
import org.jacoco.core.data.ExecutionDataReader
import org.jacoco.core.data.ExecutionDataStore
import org.jacoco.core.data.SessionInfoStore
import java.io.ByteArrayInputStream
import java.nio.file.Files
import java.nio.file.Path

/**
 * The plugin code each attempt ran, kept under [K], from the reads of JaCoCo's counts a Paper hands
 * the pool; the Paper decides which attempts a read counts for. The lines a class's counts stand for
 * come from the class as JaCoCo saw it, which its agent dumps into a Paper's class folder: Paper
 * rewrites plugin classes as it loads them, so the plugin jar's own classes would not match.
 */
internal class Coverage<K> {
    private val ran = mutableMapOf<K, ExecutionDataStore>()

    /** [exec], one read in JaCoCo's execution data format, counts for the attempt [key]. */
    fun add(
        key: K,
        exec: ByteArray,
    ) {
        val store = ran.getOrPut(key, ::ExecutionDataStore)
        ExecutionDataReader(ByteArrayInputStream(exec)).apply {
            setExecutionDataVisitor(store::put)
            setSessionInfoVisitor(SessionInfoStore())
            read()
        }
    }

    /**
     * Every class the attempt [key] ran code of, by name, with the lines of its source that ran: a line
     * ran when any of its instructions did. [classes] is the folder JaCoCo's agent dumped the Paper's
     * classes into; a class not dumped there is left out.
     */
    fun covered(
        key: K,
        classes: Path,
    ): List<CoveredClass> {
        val store = ran[key] ?: return listOf()
        val builder = CoverageBuilder()
        val analyzer = Analyzer(store, builder)
        for (data in store.contents) {
            if (!data.hasHits()) continue
            val dumped = classes.resolve("%s.%016x.class".format(data.name, data.id))
            if (!Files.isRegularFile(dumped)) continue
            analyzer.analyzeClass(Files.readAllBytes(dumped), data.name)
        }
        return builder.classes
            .filter { it.sourceFileName != null }
            .map { covered ->
                val lines =
                    (covered.firstLine..covered.lastLine).filter { line ->
                        covered.firstLine > 0 && covered.getLine(line).instructionCounter.coveredCount > 0
                    }
                CoveredClass(covered.name, "${covered.packageName}/${covered.sourceFileName}".removePrefix("/"), lines)
            }.filter { it.lines().isNotEmpty() }
            .sortedBy { it.name() }
    }

    /** The attempt [key] ended; its reads go. */
    fun forget(key: K) {
        ran -= key
    }
}
