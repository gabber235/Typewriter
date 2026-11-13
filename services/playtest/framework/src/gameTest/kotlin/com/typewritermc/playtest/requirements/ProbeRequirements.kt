package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val ProbeRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("PROBE-1", "a chat line the probe sends reaches the player") {
        probe.chat(player, "Hello")

        within(10.ticks) { player sees chat("Hello") }
    }
}
