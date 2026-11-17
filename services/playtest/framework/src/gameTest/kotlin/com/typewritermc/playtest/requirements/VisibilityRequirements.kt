package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.entity
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.wire.KeyboardKey

val VisibilityRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("SEEN-1", "an entity in the open owns visible pixels") {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        val villager = probe.spawn("villager", 0.5, 100.0, 4.5, yaw = 180f)

        // Paper sends the entity in the tick after the spawn, and the client watches it from that tick on.
        within(1.ticks) { player sees entity(villager).visible() }
    }

    requirement("SEEN-2", "an entity behind a wall is drawn but not seen", demonstrates = Demonstrates.EDGE_CASE) {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "stone")
        probe.fill(BlockPos(-3, 100, 2), BlockPos(3, 103, 2), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        val villager = probe.spawn("villager", 0.5, 100.0, 4.5, yaw = 180f)

        within(10.ticks) {
            player sees entity(villager).drawn()
            player.never sees entity(villager).visible()
        }
    }

    requirement("SEEN-3", "an invisible entity is drawn but not seen", demonstrates = Demonstrates.EDGE_CASE) {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        val villager = probe.spawn("villager", 0.5, 100.0, 4.5, yaw = 180f, invisible = true)

        within(10.ticks) {
            player sees entity(villager).drawn()
            player.never sees entity(villager).visible()
        }
    }

    requirement("SEEN-4", "an entity behind the player is not seen while one in front is", demonstrates = Demonstrates.EDGE_CASE) {
        probe.fill(BlockPos(-3, 99, -6), BlockPos(3, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        val behind = probe.spawn("villager", 0.5, 100.0, -3.5)
        val ahead = probe.spawn("villager", 0.5, 100.0, 4.5, yaw = 180f)

        within(1.ticks) {
            player sees entity(ahead).visible()
            player.never sees entity(behind).visible()
        }
    }

    requirement("SEEN-5", "an entity behind the open inventory is drawn but not seen", demonstrates = Demonstrates.EDGE_CASE) {
        probe.fill(BlockPos(-3, 99, -3), BlockPos(3, 99, 12), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)
        player.press(KeyboardKey.E)
        // Ten blocks away the pig and its shadow stand wholly behind the inventory's panel.
        val pig = probe.spawn("pig", 0.5, 100.0, 10.5, yaw = 180f)

        within(10.ticks) {
            player sees entity(pig).drawn()
            player.never sees entity(pig).visible()
        }
    }
}
