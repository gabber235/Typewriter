package com.typewritermc.playtest

import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.CoveredClass
import java.nio.file.Files
import java.nio.file.Path

/**
 * What this test JVM's run asks of its requirements, as the `gameTest` task passes it: how their
 * attempts are made (`playtest.repeat` runs each exactly that often, else failed attempts run again up
 * to [RETRIES] in total), and which the quarantine holds (`playtest.quarantine`): those run once and
 * never block, and which lines the change under test added (`playtest.touched`, the file xtask writes):
 * a requirement that covered one of them, or failed, runs once more in demo mode. Which requirements
 * run is testBalloon's selection.
 */
internal class RunPlan private constructor(
    val policy: AttemptPolicy,
    private val quarantined: Set<String>,
    private val touched: Touched,
) {
    /** Whether the quarantine holds the requirement [id], whose test is [testId]. */
    fun quarantines(
        id: String,
        testId: String,
    ): Boolean = id in quarantined || testId in quarantined

    /**
     * Whether a requirement whose attempts proved [verdict], the last of which [covered] this plugin
     * code, runs once more in demo mode: when it failed, or the change touched code it covered. A
     * refused requirement or a broken game would end its demo the same way, so neither runs one.
     */
    fun demos(
        verdict: Verdict,
        covered: List<CoveredClass>,
    ): Boolean =
        when (verdict) {
            Verdict.Passed -> touched.touches(covered)
            is Verdict.Failed -> verdict.failures.none { it is RequirementRefused || it is GameUnavailable }
            is Verdict.Flaky, is Verdict.Quarantined -> true
        }

    companion object {
        /** Attempts a failed requirement gets in total: the first and up to 3 retries. */
        const val RETRIES = 4

        /** This test JVM's plan, from its system properties. */
        val current: RunPlan by lazy {
            of(System.getProperties().stringPropertyNames().associateWith { System.getProperty(it) })
        }

        /** The plan [properties] ask for; [read] reads the touched lines' file. */
        fun of(
            properties: Map<String, String>,
            read: (Path) -> String = Files::readString,
        ): RunPlan {
            fun ids(key: String) =
                properties["playtest.$key"]
                    .orEmpty()
                    .split(',')
                    .map(String::trim)
                    .filter(String::isNotEmpty)
                    .toSet()
            val repeat = properties["playtest.repeat"]?.toInt() ?: 1
            require(repeat >= 1) { "playtest.repeat is $repeat; a run makes at least 1 attempt of each requirement" }
            val policy = if (repeat == 1) AttemptPolicy.RerunFailuresWrapper(RETRIES) else AttemptPolicy.ExactlyWrapper(repeat)
            val touched = properties["playtest.touched"]?.let { Touched.read(read(Path.of(it))) } ?: Touched.NONE
            return RunPlan(policy, ids("quarantine"), touched)
        }
    }
}
