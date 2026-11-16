package com.typewritermc.playtest

/**
 * The attempt's lease ran out before the test JVM sent its result: [report] says after how long and
 * which players it held. The pool recorded the attempt as failed and gave its players to other attempts.
 */
class LeaseExpired internal constructor(
    val report: String,
) : AssertionError(report)
