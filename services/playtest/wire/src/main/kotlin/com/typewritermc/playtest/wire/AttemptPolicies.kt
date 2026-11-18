@file:JvmName("AttemptPolicies")

package com.typewritermc.playtest.wire

import skirout.harness.v1.test_run.AttemptPolicy

/** Attempts a failed requirement gets in total when its run repeats nothing: the first and up to 3 retries. */
const val RETRIES = 4

/**
 * How a run makes the attempts of each requirement, as its `playtest.repeat` property says ([repeat],
 * null when unset): that many attempts exactly, or failed attempts again up to [RETRIES] in total. The
 * test JVM makes the attempts and the pool writes them into the run file, so both read the policy here.
 */
fun AttemptPolicy.Companion.ofRepeat(repeat: String?): AttemptPolicy {
    val times = repeat?.toInt() ?: 1
    require(times >= 1) { "playtest.repeat is $times; a run makes at least 1 attempt of each requirement" }
    return if (times == 1) AttemptPolicy.RerunFailuresWrapper(RETRIES) else AttemptPolicy.ExactlyWrapper(times)
}
