package com.typewritermc.example.entries.manifest

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.*
import org.bukkit.Particle
import org.bukkit.entity.Player
import java.time.Duration

//<code-block:custom_path_stream_display>
class ExampleParticleDisplay(private val player: Player) : PathStreamDisplay {
    override fun display(position: Position) {
        player.spawnParticle(Particle.FLAME, position.x, position.y, position.z, 1)
    }

    override fun dispose() {}
}
//</code-block:custom_path_stream_display>

//<code-block:custom_path_stream>
class ExamplePathStream(
    displays: List<PathStreamDisplay>,
    private val points: List<Position>,
) : PathStream(displays) {
    private var index = 0
    override fun forwardPath(): Position = points[index++]
    override fun shouldContinue(): Boolean = index < points.size
}
//</code-block:custom_path_stream>

//<code-block:path_stream_display_entry>
@Entry(
    "example_path_stream_display",
    "Shows a simple path stream",
    Colors.MYRTLE_GREEN,
    "material-symbols:route"
)
class ExamplePathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val refreshDuration: Duration = Duration.ofMillis(1700),
) : PathStreamDisplayEntry {
    override fun createDisplay(player: Player): PathStreamDisplay = ExampleParticleDisplay(player)

    override fun createProducer(
        player: Player,
        roadNetwork: Ref<RoadNetworkEntry>,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position,
    ): PathStreamProducer =
        LinePathStreamProducer(
            player = player,
            ref = ref(),
            roadNetwork = roadNetwork,
            startPosition = startPosition,
            endPosition = endPosition,
            refreshDuration = refreshDuration,
            speed = 20.0,
            displayEntries = displays(),
        )
}
//</code-block:path_stream_display_entry>

//<code-block:custom_path_stream_producer>
class ExampleProducer(
    player: Player,
    id: String,
    roadNetwork: Ref<RoadNetworkEntry>,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration,
    displayEntries: List<Ref<PathStreamDisplayEntry>>,
) : PathStreamProducer(
    player,
    id,
    roadNetwork,
    startPosition,
    endPosition,
    refreshDuration,
    { displayEntries.createDisplays(it) },
) {
    override suspend fun refreshPath(): PathStream? {
        val (edges, paths) = calculatePathing() ?: return null
        val line = paths.flatten()
        if (line.isEmpty()) return null
        return ExamplePathStream(displaySupplier(player), line)
    }
}
//</code-block:custom_path_stream_producer>
