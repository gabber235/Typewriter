package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.heapShareOf
import com.typewritermc.playtest.paperFolder
import com.typewritermc.playtest.poolHeapShare
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.wire.HeapShare
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val HeapRequirements by testSuite(compartment = { GameCompartment }) {
    requirement(
        "HEAP-1",
        "every game JVM caps its heap at its kind's share of the machine: the pool, the shared Paper, an own Paper and a client",
        restartsPaper = true,
    ) {
        poolHeapShare() shouldBe HeapShare.POOL.percent
        heapShareOf("paper") shouldBe HeapShare.PAPER.percent
        heapShareOf(paperFolder) shouldBe HeapShare.OWN_PAPER.percent
        heapShareOf("client-${player.name}") shouldBe HeapShare.CLIENT.percent
    }
}
