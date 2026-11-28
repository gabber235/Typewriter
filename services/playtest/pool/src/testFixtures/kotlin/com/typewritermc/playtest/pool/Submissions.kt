package com.typewritermc.playtest.pool

import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.wire.AttemptKind
import skirout.harness.v1.wire.PlayerClaim
import skirout.harness.v1.wire.Submit

/**
 * Submission [submission] of a one player requirement whose test id is [testId], such as
 * `PROBE-1 a chat line reaches the player`, whose requirement is the id's first word, for what its
 * [kind] says.
 */
fun submitted(
    submission: Long,
    testId: String,
    demonstrates: Demonstrates = Demonstrates.HAPPY_PATH,
    kind: AttemptKind = AttemptKind.VERDICT,
): Submit =
    Submit.partial(
        submission = submission,
        testId = testId,
        requirement = testId.substringBefore(' '),
        players = count(1),
        demonstrates = demonstrates,
        kind = kind,
    )

/** A claim for [players] players. */
fun count(players: Int): PlayerClaim = PlayerClaim.CountWrapper(players)
