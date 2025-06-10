package com.typewritermc.example.entries.manifest.pathstream

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.MultiPathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.SinglePathStreamDisplay
import com.typewritermc.roadnetwork.entries.StreamProducer

@Entry(
    "example_single_display_entry",
    "A Path Stream with a single display",
    Colors.GREEN,
    "material-symbols:conversion-path"
)
//<code-block:single_path_stream_display>
class SingleDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    private val road: Ref<RoadNetworkEntry> = emptyRef(),
    private val display: Ref<PathStreamDisplayEntry> = emptyRef(),
    val target: Position = Position.ORIGIN,
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        SinglePathStreamDisplay(
            road,
            { display },
            endPosition = { target }
        )
}
//</code-block:single_path_stream_display>

@Entry(
    "example_multi_display_entry",
    "A Path Stream with multiple displays",
    Colors.GREEN,
    "material-symbols:conversion-path"
)
//<code-block:multi_path_stream_display>
class MultiDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    private val road: Ref<RoadNetworkEntry> = emptyRef(),
    private val display: Ref<PathStreamDisplayEntry> = emptyRef(),
    private val targets: List<Position> = emptyList(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        MultiPathStreamDisplay(road) { player ->
            targets.mapIndexed { index, target ->
                StreamProducer(
                    // ID must stay consistent between calls to this supplier.
                    // It is used to efficiently manage the display.
                    id = "$index",
                    display,
                    // Though the location itself can change, even dynamically,
                    endPosition = { target }
                )
            }
        }
}
//</code-block:multi_path_stream_display>