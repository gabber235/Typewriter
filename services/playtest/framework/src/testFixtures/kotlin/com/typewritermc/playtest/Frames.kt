package com.typewritermc.playtest

import skirout.harness.v1.wire.InputStep

/** [player]'s frame as the client holds it now, kept in the attempt's evidence as `<name>.png`. */
suspend fun RequirementScope.frameOf(
    player: GamePlayer,
    name: String,
): Frame = attempt.capture(player, name).frame

/** [player]'s client touches nothing for [ticks], which run meanwhile; returns once they ran. */
suspend fun RequirementScope.idle(
    player: GamePlayer,
    ticks: Ticks,
): Mark = attempt.input(player, listOf(InputStep.createWait(ticks = ticks.count)), "idles for ${ticks.count} ticks")

/** How bright the pixel at column [x] of row [y] is: its red, green and blue summed, 0 to 765. */
fun Frame.brightnessAt(
    x: Int,
    y: Int,
): Int = rgbAt(x, y).let { (it shr 16 and 0xFF) + (it shr 8 and 0xFF) + (it and 0xFF) }
