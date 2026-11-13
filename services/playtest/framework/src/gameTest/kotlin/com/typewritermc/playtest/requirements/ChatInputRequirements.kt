package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.GameMode
import com.typewritermc.playtest.Key
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.suggestions
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite

val ChatInputRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("CHAT-1", "a line the player types and sends shows in the chat") {
        probe.fill(BlockPos(126, 99, -2), BlockPos(130, 99, 8), "stone")
        probe.teleport(player, 128.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)

        player.typeInChat("hello there")
        player.press(Key.ENTER)

        within(10.ticks) { player sees chat("<${player.name}> hello there") }
    }

    requirement("CMD-1", "a command the player types runs with what was typed") {
        probe.fill(BlockPos(134, 99, -2), BlockPos(138, 99, 8), "stone")
        probe.teleport(player, 136.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        probe.command("warp", suggests = listOf("spawn", "spire", "shop"), answer = "Warping to")

        player.typeInChat("/warp spawn")
        player.press(Key.ENTER)

        within(10.ticks) { player sees chat("Warping to spawn") }
    }

    requirement("TAB-1", "warp suggestions narrow as the player types") {
        probe.fill(BlockPos(142, 99, -2), BlockPos(146, 99, 8), "stone")
        probe.teleport(player, 144.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)
        probe.command("warp", suggests = listOf("spawn", "spire", "shop"), answer = "Warping to")

        player.typeInChat("/warp s")
        within(20.ticks) { player sees suggestions("shop", "spawn", "spire") }
        player.typeInChat("p")
        within(20.ticks) { player sees suggestions("spawn", "spire") }
    }
}
