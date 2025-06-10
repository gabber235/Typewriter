package com.typewritermc.entity.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.EntityDefinitionEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.PathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.PathStreamProducer
import org.bukkit.entity.Player
import java.time.Duration

@Entry(
    "animated_entity_path_stream_display",
    "An entity which moves along the path stream path",
    Colors.MYRTLE_GREEN,
    "material-symbols:move-location-rounded"
)
/**
 * This path display lets an entity follow the path stream path.
 */
class AnimatedEntityPathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    @Default("1200")
    override val refreshDuration: Duration = Duration.ofMillis(1200),
    @Help("How fast the stream travels in blocks per second")
    @Default("0.3")
    val travelSpeed: Double = 0.3,
    val definition: Ref<EntityDefinitionEntry> = emptyRef(),
) : PathStreamDisplayEntry {
    override fun createDisplay(player: Player): PathStreamDisplay? {
        val definitionEntry = definition.get() ?: return null
        return EntityPathStreamDisplay(player, definitionEntry)
    }

    override fun createProducer(
        player: Player,
        roadNetwork: Ref<RoadNetworkEntry>,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position
    ): PathStreamProducer {
        return PathFindingPathStreamProducer(
            player,
            ref(),
            roadNetwork,
            startPosition,
            endPosition,
            refreshDuration,
            travelSpeed,
            displays()
        )
    }
}

