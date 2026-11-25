package com.typewritermc.playtest.plugin

import java.util.UUID

/**
 * A step policy whose granted ticks run [grantTick], with nothing left to send, every main thread task
 * run at once and no counted work; [clock] is its wall clock, [reportStalled] hears each stalled client
 * and [connected] says whose connection is open.
 */
internal fun stepPolicy(
    grantTick: () -> Unit,
    clock: () -> Long = { 0L },
    reportStalled: (UUID) -> Unit = {},
    connected: (UUID) -> Boolean = { true },
) = StepPolicy(
    { false },
    grantTick,
    { _, _ -> },
    { true },
    { it.run() },
    WorkLedger { _, _ -> },
    {},
    Acks { clock() },
    { reportStalled(it.player()) },
    connected,
    { clock() },
)
