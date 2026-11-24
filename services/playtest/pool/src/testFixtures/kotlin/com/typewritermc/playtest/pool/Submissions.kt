package com.typewritermc.playtest.pool

import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.wire.Submit

/**
 * Submission [submission] of a one player requirement whose test id is [testId], such as
 * `PROBE-1 a chat line reaches the player`, whose requirement is the id's first word, made at
 * [paceMillis] between ticks, as a [paced] attempt after the case passed when it says so.
 */
fun submitted(
    submission: Long,
    testId: String,
    demonstrates: Demonstrates = Demonstrates.HAPPY_PATH,
    demo: Boolean = false,
    paceMillis: Int = 0,
    paced: Boolean = false,
): Submit =
    Submit.partial(
        submission = submission,
        testId = testId,
        requirement = testId.substringBefore(' '),
        players = 1,
        demonstrates = demonstrates,
        demo = demo,
        paceMillis = paceMillis,
        paced = paced,
    )
