package com.typewritermc.playtest

import skirout.harness.v1.wire.InputStep

/** [player]'s client touches nothing for [ticks], which run meanwhile; returns once they ran. */
suspend fun RequirementScope.idle(
    player: GamePlayer,
    ticks: Ticks,
): Mark = attempt.input(player, listOf(InputStep.createWait(ticks = ticks.count)), "idles for ${ticks.count} ticks")
