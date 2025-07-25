package com.typewritermc.roadnetwork.entries

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.ContentEditor
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.hasData
import com.typewritermc.engine.paper.entry.entries.stringData
import com.typewritermc.roadnetwork.RoadNetwork
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.content.RoadNetworkContentMode

@Entry("base_road_network", "A definition of the words road network", Colors.YELLOW, "material-symbols:map")
/**
 * The `Simple Road Network` is a definition of a road network.
 * The road network is a system of interconnected nodes and edges that represent a network in the world.
 *
 * ## How could this be used?
 * To let npc's navigate the world.
 * And to let players navigate the world by showing them the way to go.
 */
class BaseRoadNetworkEntry(
    override val id: String = "",
    override val name: String = "",
    @ContentEditor(RoadNetworkContentMode::class)
    override val artifactId: String = "",
) : RoadNetworkEntry {
    override suspend fun loadRoadNetwork(gson: Gson): RoadNetwork {
        if (!hasData()) return RoadNetwork()
        return gson.fromJson(stringData(), object : TypeToken<RoadNetwork>() {}.type)
    }

    override suspend fun saveRoadNetwork(gson: Gson, network: RoadNetwork) {
        stringData(gson.toJson(network))
    }
}