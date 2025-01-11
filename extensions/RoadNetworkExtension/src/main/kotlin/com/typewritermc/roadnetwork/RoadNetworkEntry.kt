package com.typewritermc.roadnetwork

import com.github.retrooper.packetevents.util.Vector3f
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.ContentEditor
import com.typewritermc.core.extension.annotations.Factory
import com.typewritermc.core.extension.annotations.Named
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.RuntimeTypeAdapterFactory
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.content.*
import com.typewritermc.engine.paper.content.components.bossBar
import com.typewritermc.engine.paper.content.components.exit
import com.typewritermc.engine.paper.content.components.nodes
import com.typewritermc.engine.paper.entry.entries.ArtifactEntry
import com.typewritermc.engine.paper.entry.fieldValue
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.loader.serializers.WorldSerializer
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.LocationSerializer
import com.typewritermc.engine.paper.utils.playSound
import com.typewritermc.roadnetwork.content.RoadNetworkEditorComponent
import com.typewritermc.roadnetwork.content.material
import net.kyori.adventure.bossbar.BossBar
import net.kyori.adventure.text.format.NamedTextColor
import org.bukkit.Location
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

val roadNetworkMaxDistance by snippet(
    "road_network.distance.max", 30.0, """
    |The maximum distance that can be between two nodes. 
    |Therefore it is also the maximum radius the player can be from a node to be inside the road network
    """.trimMargin()
)

@Tags("road_network")
interface RoadNetworkEntry : ArtifactEntry {
    suspend fun loadRoadNetwork(gson: Gson): RoadNetwork
    suspend fun saveRoadNetwork(gson: Gson, network: RoadNetwork)
}

@Tags("road_network_node")
interface RoadNodeEntry : Entry {
    val roadNetwork: Ref<RoadNetworkEntry>

    @ContentEditor(SelectRoadNodeContentMode::class)
    val nodeId: RoadNodeId
}

@Tags("road_network_node_collection")
interface RoadNodeCollectionEntry : Entry {
    val roadNetwork: Ref<RoadNetworkEntry>

    @ContentEditor(SelectRoadNodeCollectionContentMode::class)
    val nodes: List<RoadNodeId>
}

data class RoadNetwork(
    val nodes: List<RoadNode> = emptyList(),
    val edges: List<RoadEdge> = emptyList(),
    val modifications: List<RoadModification> = emptyList(),
    val negativeNodes: List<RoadNode> = emptyList(),
)

@JvmInline
value class RoadNodeId(val id: Int = 0) {
    override fun toString(): String = id.toString()
}

data class RoadNode(
    val id: RoadNodeId,
    val location: Location,
    val radius: Double,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as RoadNode

        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()
}

data class RoadEdge(
    val start: RoadNodeId,
    val end: RoadNodeId,
    val weight: Double,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as RoadEdge

        if (start != other.start) return false
        if (end != other.end) return false

        return true
    }

    override fun hashCode(): Int {
        var result = start.hashCode()
        result = 31 * result + end.hashCode()
        return result
    }
}

fun Collection<RoadEdge>.containsEdge(start: RoadNodeId, end: RoadNodeId): Boolean =
    any { it.start == start && it.end == end }

sealed interface RoadModification {
    sealed interface EdgeModification : RoadModification {
        val start: RoadNodeId
        val end: RoadNodeId
    }

    data class EdgeAddition(
        override val start: RoadNodeId,
        override val end: RoadNodeId,
        val weight: Double
    ) :
        EdgeModification {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false

            other as EdgeAddition

            if (start != other.start) return false
            if (end != other.end) return false

            return true
        }

        override fun hashCode(): Int {
            var result = start.hashCode()
            result = 31 * result + end.hashCode()
            return result
        }
    }

    data class EdgeRemoval(override val start: RoadNodeId, override val end: RoadNodeId) :
        EdgeModification
}

fun Collection<RoadModification>.containsRemoval(start: RoadNodeId, end: RoadNodeId): Boolean =
    any { it is RoadModification.EdgeRemoval && it.start == start && it.end == end }

fun Collection<RoadModification>.containsAddition(start: RoadNodeId, end: RoadNodeId): Boolean =
    any { it is RoadModification.EdgeAddition && it.start == start && it.end == end }

@Factory
@Named("roadNetworkParser")
fun createRoadNetworkParser(): Gson = GsonBuilder()
    .registerTypeAdapter(Location::class.java, LocationSerializer())
    .registerTypeAdapter(World::class.java, WorldSerializer())
    .registerTypeAdapterFactory(
        RuntimeTypeAdapterFactory.of(RoadModification::class.java)
            .registerSubtype(RoadModification.EdgeAddition::class.java)
            .registerSubtype(RoadModification.EdgeRemoval::class.java)
    )
    .create()

class SelectRoadNodeContentMode(context: ContentContext, player: Player) : ContentMode(context, player) {
    private lateinit var editorComponent: RoadNetworkEditorComponent
    private val network: RoadNetwork
        get() = editorComponent.network

    private var cycle = 0

    override suspend fun setup(): Result<Unit> {
        val fieldPath = context.fieldPath ?: return failure(Exception("No field path found"))
        val entryId = context.entryId ?: return failure(Exception("No entry id found"))

        val entry = Query.findById<RoadNodeEntry>(entryId)
            ?: return failure(Exception("No road node found with id $entryId"))

        val roadNetworkRef = entry.roadNetwork

        if (!roadNetworkRef.isSet) {
            return failure("No road network found with id ${entry.roadNetwork.id} associated with road node $entryId")
        }

        editorComponent = RoadNetworkEditorComponent(roadNetworkRef)

        exit(doubleShiftExits = true)
        bossBar {
            title = "Select Road Node"
            color = BossBar.Color.WHITE
        }

        nodes({ network.nodes }, ::showingLocation) { node ->
            item = ItemStack(node.material(network.modifications))
            glow = NamedTextColor.WHITE
            scale = Vector3f(0.5f, 0.5f, 0.5f)

            onInteract {
                val value = node.id.id
                entry.ref().fieldValue(fieldPath, value)
                ContentPopTrigger.triggerFor(player, context())
            }
        }

        return ok(Unit)
    }

    override suspend fun tick() {
        super.tick()
        cycle++
    }

    private fun showingLocation(node: RoadNode): Location = node.location.clone().apply {
        yaw = (cycle % 360).toFloat()
    }
}

class SelectRoadNodeCollectionContentMode(context: ContentContext, player: Player) : ContentMode(context, player) {
    private lateinit var editorComponent: RoadNetworkEditorComponent
    private val network: RoadNetwork
        get() = editorComponent.network

    private var cycle = 0

    private var nodes: List<RoadNodeId> = emptyList()

    override suspend fun setup(): Result<Unit> {
        val fieldPath = context.fieldPath ?: return failure(Exception("No field path found"))
        val entryId = context.entryId ?: return failure(Exception("No entry id found"))

        val entry = Query.findById<RoadNodeCollectionEntry>(entryId)
            ?: return failure(Exception("No road node collection found with id $entryId"))

        nodes = entry.nodes
        val ref = entry.ref()

        val roadNetworkRef = entry.roadNetwork

        if (!roadNetworkRef.isSet) {
            return failure("No road network found with id ${entry.roadNetwork.id} associated with road node collection $entryId")
        }


        editorComponent = RoadNetworkEditorComponent(roadNetworkRef)

        exit(doubleShiftExits = true)
        bossBar {
            title = "Select Road Nodes <gray>(${nodes.size})"
            color = BossBar.Color.WHITE
        }

        nodes({ network.nodes }, ::showingLocation) { node ->
            item = ItemStack(node.material(network.modifications))
            glow = when {
                nodes.any { it.id == node.id.id } -> NamedTextColor.BLUE
                else -> NamedTextColor.WHITE
            }
            scale = Vector3f(0.5f, 0.5f, 0.5f)

            onInteract {
                val value = node.id.id
                val newNodes = if (nodes.any { it.id == value }) {
                    nodes.filter { it.id != value }
                } else {
                    nodes + RoadNodeId(value)
                }
                ref.fieldValue(fieldPath, newNodes)
                nodes = newNodes
                player.playSound("ui.button.click")
            }
        }

        return ok(Unit)
    }

    override suspend fun tick() {
        super.tick()
        cycle++
    }

    private fun showingLocation(node: RoadNode): Location = node.location.clone().apply {
        yaw = (cycle % 360).toFloat()
    }
}