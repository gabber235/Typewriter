package com.typewritermc.example.entries.manifest.pathstream

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.*
import com.typewritermc.roadnetwork.gps.GPSEdge
import org.bukkit.Particle
import org.bukkit.entity.Player
import java.time.Duration

@Entry(
    "example_path_stream_display",
    "Shows a simple path stream",
    Colors.MYRTLE_GREEN,
    "material-symbols:route"
)
//<code-block:path_stream_display_entry>
class ExamplePathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val refreshDuration: Duration = Duration.ofMillis(1700),
    val travelSpeed: Double = 20.0,
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
            speed = travelSpeed,
            displayEntries = displays(), // A helper function that retrieves the correct display entries
        )
}
//</code-block:path_stream_display_entry>

//<code-block:custom_path_stream_display>
class ExampleParticleDisplay(private val player: Player) : PathStreamDisplay {
    override fun display(position: Position) {
        player.spawnParticle(Particle.FLAME, position.x, position.y, position.z, 1)
    }

    override fun dispose() {
        // As path stream displays are stateful, you can clean up resources here if needed.
    }
}
//</code-block:custom_path_stream_display>

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
        // This is a massive helper function. There are a few more helper functions that allow you to
        // separate our the different parts of the path finding.
        val (_edges, _paths) = calculatePathing() ?: return null

        // Here is the logic for the calculatePathing, you can use any of the helper functions
        // as you like.
        val (start: Position, end: Position) = points() ?: return null
        val edges: List<GPSEdge> = findEdges() ?: return null
        val visibleEdges: List<GPSEdge> = edges.filterVisible(start, end)
        val paths: List<List<Position>> = findPaths(visibleEdges) ?: return null

        val line = paths.flatten()
        if (line.isEmpty()) return null

        // Create a path stream which is used to keep track of the current position and forwards for displaying.
        // Typewriter will automatically trigger the sub functions for you.
        return ExamplePathStream(displaySupplier(player), line)
    }
}
//</code-block:custom_path_stream_producer>

//<code-block:custom_path_stream>
class ExamplePathStream(
    displays: List<PathStreamDisplay>,
    private val points: List<Position>,
) : PathStream(displays) {
    private var index = 0

    // This is allowed to have state and complex logic to find the next position.
    override fun forwardPath(): Position {
        return points[(index++).coerceAtMost(points.size - 1)]
    }

    // This is to indicate whether the path stream should continue or not.
    // When this returns false, the path stream will stop and no longer be displayed.
    override fun shouldContinue(): Boolean {
        return index < points.size
    }

    // Can be used to clean up resources or state when the path stream is no longer needed.
    override fun dispose() {
        // Make sure to keep the super.dispose() call to clean up the displays.
        super.dispose()
    }
}
//</code-block:custom_path_stream>
