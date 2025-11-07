package com.typewritermc.quest.entries.interfaces

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.PlaceholderParser
import com.typewritermc.engine.paper.entry.include
import com.typewritermc.engine.paper.entry.literal
import com.typewritermc.engine.paper.entry.placeholderParser
import com.typewritermc.engine.paper.entry.supplyPlayer
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.quest.entries.ObjectiveEntry
import org.bukkit.entity.Player
import kotlin.math.roundToInt

interface LocatableObjective : ObjectiveEntry {
    fun positions(player: Player?): List<Position>

    override fun parser(): PlaceholderParser = placeholderParser {
        include(super.parser())

        literal("distance") {
            supplyPlayer { player ->
                val playerPosition = player.position;
                val positions = positions(player)
                if (positions.isEmpty()) return@supplyPlayer null
                val closestPosition =
                    positions(player).maxBy { it.distanceSqrt(playerPosition) ?: Double.POSITIVE_INFINITY }

                if (closestPosition.world != playerPosition.world) {
                    return@supplyPlayer "∞ m"
                }

                val distance = player.position.distance(closestPosition).roundToInt()
                "${distance}m"
            }
        }
    }
}