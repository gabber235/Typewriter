package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.anyToast
import com.typewritermc.playtest.backToBack
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val ToastRequirements by testSuite(compartment = { GameCompartment }) {
    backToBack(
        "TOAST-1",
        "an attempt shows no toast the attempt before it showed on the same client",
        first = {
            probe.give(player, 0, "oak_log")
            within(20.ticks) { player sees anyToast() }
        },
        then = {
            probe.chat(player, "Hello")
            within(10.ticks) {
                player sees chat("Hello")
                player.never sees anyToast()
            }
        },
    )
}
