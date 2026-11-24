package com.typewritermc.playtest

import com.typewritermc.playtest.wire.ofRepeat
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.CoveredClass
import skirout.harness.v1.test_run.Pacing
import java.nio.file.Files
import java.nio.file.Path

/**
 * What this test JVM's run asks of its requirements, as the `gameTest` task passes it: how their
 * attempts are made (`playtest.repeat`, read by [ofRepeat]); which the quarantine holds
 * (`playtest.quarantine`): those run once and never block; which lines the change under test added
 * (`playtest.touched`, the file xtask writes); the [paces] a touched requirement whose attempts passed
 * runs at once more each (`playtest.paces`, milliseconds between ticks, none unless named); what a window
 * held at another tick at another pace does (`playtest.pacing`, `gates` unless `reports`); and whether
 * the run is a [demo] (`playtest.demo`). Which requirements run is testBalloon's selection.
 */
internal class RunPlan private constructor(
    val policy: AttemptPolicy,
    private val quarantined: Set<String>,
    private val touched: Touched,
    val paces: List<Int>,
    val pacing: Pacing,
    /** Whether the run is a demo: each requirement runs once, its clients recording clips, after the verdict's run. */
    val demo: Boolean,
) {
    /** Whether the quarantine holds the requirement [id], whose test is [testId]. */
    fun quarantines(
        id: String,
        testId: String,
    ): Boolean = id in quarantined || testId in quarantined

    /**
     * Whether the change under test is new to a requirement or touched it: it added a line to the
     * requirement's own [code], or one the requirement's last attempt [covered].
     */
    fun touches(
        code: RequirementLines,
        covered: List<CoveredClass>,
    ): Boolean = touched.touches(code) || touched.touches(covered)

    companion object {
        /** This test JVM's plan, from its system properties. */
        val current: RunPlan by lazy {
            of(System.getProperties().stringPropertyNames().associateWith { System.getProperty(it) })
        }

        /** The plan [properties] ask for; [read] reads the touched lines' file. */
        fun of(
            properties: Map<String, String>,
            read: (Path) -> String = Files::readString,
        ): RunPlan {
            fun listed(key: String) =
                properties["playtest.$key"]
                    .orEmpty()
                    .split(',')
                    .map(String::trim)
                    .filter(String::isNotEmpty)
                    .toSet()
            val policy = AttemptPolicy.ofRepeat(properties["playtest.repeat"])
            val touched = properties["playtest.touched"]?.let { Touched.read(read(Path.of(it))) } ?: Touched.NONE
            val paces =
                listed("paces").map { pace ->
                    pace.toInt().also { require(it > 0) { "playtest.paces names $pace; a pace is at least 1 ms" } }
                }
            val pacing =
                when (val named = properties["playtest.pacing"] ?: "gates") {
                    "gates" -> Pacing.GATES
                    "reports" -> Pacing.REPORTS
                    else -> throw IllegalArgumentException("playtest.pacing is $named; it gates or reports")
                }
            return RunPlan(policy, listed("quarantine"), touched, paces, pacing, properties["playtest.demo"].toBoolean())
        }
    }
}
