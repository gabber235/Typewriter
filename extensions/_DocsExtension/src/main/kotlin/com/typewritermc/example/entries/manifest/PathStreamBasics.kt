package com.typewritermc.example.entries.manifest

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.MultiPathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.SinglePathStreamDisplay
import com.typewritermc.roadnetwork.entries.StreamProducer
import com.typewritermc.core.utils.point.Position
import org.bukkit.entity.Player

//<code-block:single_path_stream_display>
class SingleDisplayEntry(
    private val road: Ref<RoadNetworkEntry>,
    private val display: Ref<PathStreamDisplayEntry>,
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        SinglePathStreamDisplay(
            road,
            { display },
            endPosition = { Position.ORIGIN }
        )
}
//</code-block:single_path_stream_display>

//<code-block:multi_path_stream_display>
class MultiDisplayEntry(
    private val road: Ref<RoadNetworkEntry>,
    private val streams: (Player) -> List<StreamProducer>,
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        MultiPathStreamDisplay(road, streams)
}
//</code-block:multi_path_stream_display>
