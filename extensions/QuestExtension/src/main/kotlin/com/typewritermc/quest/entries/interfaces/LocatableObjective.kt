package com.typewritermc.quest.entries.interfaces

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.quest.entries.ObjectiveEntry
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.StreamProducer
import org.bukkit.entity.Player
import kotlin.math.roundToInt

@Tags("locatable_objective")
interface LocatableObjective : ObjectiveEntry {
    fun positions(player: Player?): List<Position>

    fun streamProducers(player: Player, pathStreamDisplay: Ref<PathStreamDisplayEntry>): List<StreamProducer>

    override fun parser(): PlaceholderParser = placeholderParser {
        include(super.parser())

        literal("distance") {
            supplyPlayer { player ->
                val playerPosition = player.position
                val objectivePositions = positions(player)
                if (objectivePositions.isEmpty()) return@supplyPlayer null
                val closestPosition =
                    objectivePositions.minBy { it.distanceSquared(playerPosition) ?: Double.POSITIVE_INFINITY }

                if (closestPosition.world != playerPosition.world) {
                    return@supplyPlayer "∞ m"
                }

                val distance = playerPosition.distance(closestPosition).roundToInt()
                "${distance}m"
            }
        }
    }
}