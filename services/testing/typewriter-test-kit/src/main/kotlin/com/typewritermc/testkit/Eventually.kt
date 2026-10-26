package com.typewritermc.testkit

import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Polls [probe] until it returns a value and returns that value; for outcomes another coroutine or thread produces.
 * Fails with [expectation] and the last state [describe] gives when [within] passes first.
 */
suspend fun <T : Any> eventually(
    expectation: String,
    within: Duration = 2.seconds,
    describe: () -> Any? = { null },
    probe: suspend () -> T?,
): T =
    withTimeoutOrNull(within) {
        var found = probe()
        while (found == null) {
            delay(POLL_INTERVAL)
            found = probe()
        }
        found
    }
        ?: throw AssertionError(
            listOfNotNull("Expected $expectation within $within.", describe()?.let { "Last state: $it" }).joinToString(" "),
        )

private val POLL_INTERVAL = 10.milliseconds
