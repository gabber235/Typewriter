package com.typewritermc.playtest.sibling

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.Key
import com.typewritermc.playtest.camera
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val SiblingRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("SIBLING-1", "a second module's requirement reaches its player on the pool both modules share") {
        probe.chat(player, "Hello from a second module")

        within(10.ticks) { player sees chat("Hello from a second module") }
    }

    requirement("SIBLING-2", "a second module's requirement moves its player on the pool both modules share") {
        probe.gameMode(player, GameMode.SPECTATOR)

        player.hold(Key.SPACE, 3.ticks)

        within(10.ticks) { player sees camera.rose() }
    }
}
