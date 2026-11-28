package com.typewritermc.playtest.plugin

import java.util.UUID

/**
 * A step policy wired only with what a test looks at: each granted tick runs [granted], work counts in [work], acks
 * read their time from [acks], a stalled client goes to [stalled], and [connected] says whose connection is open. No
 * tick is pending, barriers go nowhere, every client has sent everything, and main thread tasks run at once.
 */
internal fun stepPolicy(
    granted: () -> Unit,
    work: WorkLedger = WorkLedger(ManualWatch()),
    acks: Acks = Acks { 0L },
    stalled: (Acks.Stalled) -> Unit = {},
    connected: (UUID) -> Boolean = { true },
    barrier: (UUID, Int) -> Unit = { _, _ -> },
): StepPolicy =
    StepPolicy(
        { false },
        { granted() },
        { player, id -> barrier(player, id) },
        { true },
        { it.run() },
        work,
        {},
        acks,
        { stalled(it) },
        { connected(it) },
    )
