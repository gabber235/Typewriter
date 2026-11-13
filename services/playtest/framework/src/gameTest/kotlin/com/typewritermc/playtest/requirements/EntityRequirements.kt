package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.entity
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val EntityRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("ENTITY-1", "attacking an entity the crosshair rests on hurts it") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        val pig = probe.spawn("pig", 0.5, 100.0, 2.5, yaw = 180f)

        player.aimAt(pig)
        player.click(Button.LEFT)

        within(10.ticks) { player sees entity(pig).hurt() }
    }

    requirement("ENTITY-2", "attacking an entity only the client knows makes it react") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        val guide = probe.packetEntity(player, "villager", 0.5, 100.0, 2.5, yaw = 180f, onHit = "Ouch")

        player.aimAt(guide)
        player.click(Button.LEFT)

        within(10.ticks) { player sees entity(guide).named("Ouch") }
    }

    requirement("ENTITY-3", "using an entity the crosshair rests on makes it react") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        val pig = probe.spawn("pig", 0.5, 100.0, 2.5, yaw = 180f, onClick = "Oink")

        player.aimAt(pig)
        player.click(Button.RIGHT)

        within(10.ticks) { player sees entity(pig).named("Oink") }
    }

    requirement("ENTITY-4", "using an entity only the client knows makes it react") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        val guide = probe.packetEntity(player, "villager", 0.5, 100.0, 2.5, yaw = 180f, onClick = "Hello")

        player.aimAt(guide)
        player.click(Button.RIGHT)

        within(10.ticks) { player sees entity(guide).named("Hello") }
    }
}
