package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.anyChat
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val GroupRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("GROUP-1", "a line sent to the members of a group reaches each member and nobody else", players = 3) {
        val (member, partner, outsider) = players

        probe.chat(to = listOf(member, partner), "Bank: 1")

        within(10.ticks) {
            member sees chat("Bank: 1")
            partner sees chat("Bank: 1")
            outsider.never sees anyChat()
        }
    }
}
