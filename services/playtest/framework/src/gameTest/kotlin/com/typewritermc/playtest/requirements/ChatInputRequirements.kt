package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.Position
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.suggestions
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import skirout.harness.v1.wire.GameMode
import skirout.harness.v1.wire.KeyboardKey

val ChatInputRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("CHAT-1", "a line the player types and sends shows in the chat") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, Position(0.5, 100.0, 0.5))
        probe.gameMode(player, GameMode.CREATIVE)

        player.typeInChat("hello there")
        player.press(KeyboardKey.ENTER)

        // Paper sends the line from its chat thread before it runs the tick after the one the line was sent in.
        within(1.ticks) { player sees chat("<${player.name}> hello there") }
    }

    requirement("CMD-1", "a command the player types runs with what was typed") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, Position(0.5, 100.0, 0.5))
        probe.gameMode(player, GameMode.CREATIVE)
        probe.command("warp", suggests = listOf("spawn", "spire", "shop"), answer = "Warping to")

        player.typeInChat("/warp spawn")
        player.press(KeyboardKey.ENTER)

        // Paper runs the command before the tick after the one it was sent in.
        within(1.ticks) { player sees chat("Warping to spawn") }
    }

    requirement("TAB-1", "warp suggestions narrow as the player types") {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, Position(0.5, 100.0, 0.5))
        probe.gameMode(player, GameMode.CREATIVE)
        probe.command("warp", suggests = listOf("spawn", "spire", "shop"), answer = "Warping to")

        player.typeInChat("/warp s")
        // The chat opens in the tick after the chat key, one character goes in after each tick from then
        // on, and the answer to "/warp " (the sixth) shows in the tick after it was typed.
        within(7.ticks) { player sees suggestions("shop", "spawn", "spire") }
        player.typeInChat("p")
        within(20.ticks) { player sees suggestions("spawn", "spire") }
    }
}
