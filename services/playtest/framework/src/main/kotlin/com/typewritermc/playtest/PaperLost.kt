package com.typewritermc.playtest

import skirout.harness.v1.test_run.LossCause
import skirout.harness.v1.wire.PaperLoss
import java.nio.file.Path

/**
 * The attempt's own Paper was lost: it exited or did not boot in time, while booting or while the body
 * ran, or it could not claim or resume the attempt's players, as [loss] says. [report] says which Paper
 * and why, and [log] is the Paper's log; the shared Paper and every other attempt never noticed.
 */
class PaperLost private constructor(
    val loss: LossCause,
    val log: Path,
    val report: String,
) : AssertionError(report) {
    internal constructor(loss: PaperLoss) : this(loss.cause, Path.of(loss.log), "${loss.detail}; see ${loss.log}")
}
