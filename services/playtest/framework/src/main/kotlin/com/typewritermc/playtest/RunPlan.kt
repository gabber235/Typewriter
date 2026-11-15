package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.AttemptPolicy

/**
 * What this test JVM's run asks of its requirements, as the `gameTest` task passes it: how their
 * attempts are made (`playtest.repeat` runs each exactly that often, else failed attempts run again up
 * to [RETRIES] in total), and which the quarantine holds (`playtest.quarantine`): those run once and
 * never block. Which requirements run is testBalloon's selection.
 */
internal class RunPlan private constructor(
    val policy: AttemptPolicy,
    private val quarantined: Set<String>,
) {
    /** Whether the quarantine holds the requirement [id], whose test is [testId]. */
    fun quarantines(
        id: String,
        testId: String,
    ): Boolean = id in quarantined || testId in quarantined

    companion object {
        /** Attempts a failed requirement gets in total: the first and up to 3 retries. */
        const val RETRIES = 4

        /** This test JVM's plan, from its system properties. */
        val current: RunPlan by lazy {
            of(System.getProperties().stringPropertyNames().associateWith { System.getProperty(it) })
        }

        fun of(properties: Map<String, String>): RunPlan {
            fun ids(key: String) =
                properties["playtest.$key"]
                    .orEmpty()
                    .split(',')
                    .map(String::trim)
                    .filter(String::isNotEmpty)
                    .toSet()
            val repeat = properties["playtest.repeat"]?.toInt() ?: 1
            require(repeat >= 1) { "playtest.repeat is $repeat; a run makes at least 1 attempt of each requirement" }
            val policy =
                if (repeat ==
                    1
                ) {
                    AttemptPolicy(AttemptPolicy.Kind.RERUN_FAILURES, RETRIES)
                } else {
                    AttemptPolicy(AttemptPolicy.Kind.EXACTLY, repeat)
                }
            return RunPlan(policy, ids("quarantine"))
        }
    }
}
