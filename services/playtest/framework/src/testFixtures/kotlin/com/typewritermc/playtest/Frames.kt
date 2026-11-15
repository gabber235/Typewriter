package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.WaitStep

/** [player]'s frame as the client holds it now, kept in the attempt's evidence as `<name>.png`. */
suspend fun RequirementScope.frameOf(
    player: GamePlayer,
    name: String,
): Frame = attempt.capture(player, name).frame

/** [player]'s client touches nothing for [ticks], which run meanwhile; returns once they ran. */
suspend fun RequirementScope.idle(
    player: GamePlayer,
    ticks: Ticks,
): Mark = attempt.input(player, listOf(WaitStep(ticks.count)), "idles for ${ticks.count} ticks")
