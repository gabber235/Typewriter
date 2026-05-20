package com.typewritermc.roadnetwork.content

import com.github.retrooper.packetevents.protocol.particle.Particle
import com.github.retrooper.packetevents.protocol.particle.data.ParticleDustData
import com.github.retrooper.packetevents.protocol.particle.type.ParticleTypes
import com.github.retrooper.packetevents.util.Vector3d
import com.github.retrooper.packetevents.util.Vector3f
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerParticle
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.loopingDistance
import com.typewritermc.core.utils.ok
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.content.*
import com.typewritermc.engine.paper.content.components.*
import com.typewritermc.engine.paper.entry.forceTriggerFor
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.*
import com.typewritermc.roadnetwork.*
import com.typewritermc.roadnetwork.content.debug.findPathWithDebug
import com.typewritermc.roadnetwork.gps.roadNetworkFindPath
import com.typewritermc.roadnetwork.pathfinding.pathetic.PathCalculationResult
import de.bsommerfeld.pathetic.api.pathing.result.Path
import kotlinx.coroutines.Dispatchers
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import net.kyori.adventure.bossbar.BossBar
import net.kyori.adventure.text.format.NamedTextColor
import net.kyori.adventure.text.format.TextColor
import org.bukkit.Color
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerItemHeldEvent
import org.bukkit.inventory.ItemStack
import org.koin.core.component.KoinComponent
import java.time.Duration
import java.util.*

class SelectedRoadNodeContentMode(
    context: ContentContext,
    player: Player,
    private val ref: Ref<RoadNetworkEntry>,
    private val selectedNodeId: RoadNodeId,
    private val initiallyScrolling: Boolean,
    private val recalculateOnExit: Boolean = false,
) : ContentMode(context, player), KoinComponent {
    private lateinit var editorComponent: RoadNetworkEditorComponent

    private val network get() = editorComponent.network
    private val selectedNode get() = network.nodes.find { it.id == selectedNodeId }

    private var cycle = 0

    override suspend fun setup(): Result<Unit> {
        editorComponent = +RoadNetworkEditorComponent(ref)

        val pathsComponent = +SelectedNodePathsComponent(::selectedNode, ::network)
        bossBar {
            var suffix = editorComponent.state.message
            if (!pathsComponent.isPathsLoaded) suffix += " <gray><i>(calculating edges)</i></gray>"

            title = "Editing <gray>${selectedNode?.id}</gray> node$suffix"
            color = when {
                editorComponent.state == RoadNetworkEditorState.Dirty -> BossBar.Color.RED
                !pathsComponent.isPathsLoaded -> BossBar.Color.PURPLE
                else -> BossBar.Color.GREEN
            }
        }
        exit(doubleShiftExits = true)

        +NodeRadiusComponent(::selectedNode, initiallyScrolling) { radiusChange ->
            editorComponent.updateAsync { roadNetwork ->
                roadNetwork.copy(nodes = roadNetwork.nodes.map { node ->
                    if (node.id == selectedNodeId) node.copy(
                        radius = (node.radius + radiusChange).coerceAtLeast(
                            0.5
                        )
                    ) else node
                })
            }
        }

        +RemoveNodeComponent {
            editorComponent.updateAsync { roadNetwork ->
                roadNetwork.copy(
                    nodes = roadNetwork.nodes.filter { it.id != selectedNodeId },
                    edges = roadNetwork.edges.filter { it.start != selectedNodeId && it.end != selectedNodeId },
                    modifications = roadNetwork.modifications.filter {
                        if (it !is RoadModification.EdgeModification) return@filter true
                        it.start != selectedNodeId && it.end != selectedNodeId
                    }
                )
            }
        }

        +ModificationComponent(::selectedNode, ::network)

        +RecalculateNodeComponent(
            nodeFetcher = ::selectedNode,
            editorStateFetcher = { editorComponent.state },
            onRecalculate = { editorComponent.recalculateEdgesForSingleNode(selectedNodeId) }
        )

        +PathfindingDebugInitiatorComponent()

        nodes({ network.nodes }, ::showingPosition) { node ->
            item = ItemStack(node.material(network.modifications))
            glow = when {
                node == selectedNode -> NamedTextColor.WHITE
                network.edges.any { it.start == selectedNodeId && it.end == node.id } -> NamedTextColor.BLUE
                network.modifications.containsRemoval(
                    selectedNodeId,
                    node.id
                ) && network.modifications.containsRemoval(node.id, selectedNodeId) -> NamedTextColor.RED

                network.modifications.containsRemoval(selectedNodeId, node.id) -> NamedTextColor.GOLD
                network.modifications.containsAddition(
                    selectedNodeId,
                    node.id
                ) && network.modifications.containsAddition(node.id, selectedNodeId) -> NamedTextColor.GREEN

                network.modifications.containsAddition(selectedNodeId, node.id) -> TextColor.color(0x4fec97)
                else -> null
            }
            scale = Vector3f(0.5f, 0.5f, 0.5f)
            onInteract { interactWithNode(node) }
        }

        nodes({ network.negativeNodes }, ::showingPosition) {
            item = ItemStack(Material.NETHERITE_BLOCK)
            glow = NamedTextColor.BLACK
            scale = Vector3f(0.5f, 0.5f, 0.5f)
            onInteract {
                ContentModeSwapTrigger(
                    context,
                    SelectedNegativeNodeContentMode(
                        context,
                        player,
                        ref,
                        it.id,
                        false
                    )
                ).triggerFor(player, context())
            }
        }
        +NegativeNodePulseComponent { network.negativeNodes }

        return ok(Unit)
    }

    private fun showingPosition(node: RoadNode): Position = node.position.withYaw((cycle % 360).toFloat())

    private fun interactWithNode(node: RoadNode) {
        if (node == selectedNode) {
            ContentPopTrigger.triggerFor(player, context())
            return
        }

        when (player.inventory.heldItemSlot) {
            5 -> {
                edgeAddition(node)
                return
            }

            6 -> {
                edgeRemoval(node)
                return
            }

            7 -> {
                startDebugPathfinding(node)
                return
            }
        }

        if (player.inventory.itemInMainHand.isEmpty) {
            ContentModeSwapTrigger(
                context,
                SelectedRoadNodeContentMode(context, player, ref, node.id, false),
            ).triggerFor(player, context())
            return
        }
    }

    /**
     * Toggle the edge between modified and unmodified bidirectional
     * When the player is shifting, then we want to do it only directionally
     */
    private inline fun <reified M : RoadModification.EdgeModification> edgeModification(
        node: RoadNode,
        create: (RoadNodeId, RoadNodeId) -> M,
        crossinline modifyNetwork: (RoadNode, RoadNode, RoadNetwork) -> RoadNetwork,
    ) {
        if (node == selectedNode) return
        // If it contains the other modification, we don't want to do anything
        val containsOtherModification =
            network.modifications.any {
                it is RoadModification.EdgeModification && it !is M
                        && it.start == selectedNodeId && it.end == node.id
            }
        if (containsOtherModification) return

        player.playSound("ui.button.click")

        val containsModification =
            network.modifications.any { it is M && it.start == selectedNodeId && it.end == node.id }

        val modification = create(selectedNodeId, node.id)
        val reverseModification = create(node.id, selectedNodeId)

        if (containsModification) {
            editorComponent.updateAsync { roadNetwork ->
                roadNetwork.copy(
                    modifications = roadNetwork.modifications.filter {
                        it != modification && if (player.isSneaking) it != reverseModification else true
                    }
                )
            }
        } else {
            val selectedNode = selectedNode ?: return
            editorComponent.updateAsync { roadNetwork ->
                val modifications = if (player.isSneaking) {
                    roadNetwork.modifications + modification
                } else {
                    roadNetwork.modifications + modification + reverseModification
                }

                val n1 = roadNetwork.copy(
                    modifications = modifications
                )
                if (player.isSneaking) {
                    modifyNetwork(selectedNode, node, n1)
                } else {
                    modifyNetwork(selectedNode, node, modifyNetwork(node, selectedNode, n1))
                }
            }
        }
    }

    private fun edgeAddition(node: RoadNode) {
        edgeModification(
            node,
            { start, end -> RoadModification.EdgeAddition(start, end, 0.0) }) { start, end, network ->
            network.copy(
                edges = network.edges + RoadEdge(start.id, end.id, 0.0, 0.0)
            )
        }
    }

    private fun edgeRemoval(node: RoadNode) {
        edgeModification(node, { start, end -> RoadModification.EdgeRemoval(start, end) }) { start, end, network ->
            network.copy(
                edges = network.edges.filter { it.start != start.id || it.end != end.id }
            )
        }
    }

    override suspend fun tick(deltaTime: Duration) {
        cycle++

        if (selectedNode == null) {
            // If the node is no longer in the network, we want to pop the content
            ContentPopTrigger.forceTriggerFor(player, context())
        }

        super.tick(deltaTime)
    }

    override suspend fun dispose() {
        if (recalculateOnExit && selectedNode != null) {
            editorComponent.recalculateEdgesForSingleNode(selectedNodeId)
        }
        super.dispose()
    }

    private fun startDebugPathfinding(targetNode: RoadNode) {
        val startNode = selectedNode ?: return

        Dispatchers.UntickedAsync.launch {
            player.msg("<dark_purple>Starting debug pathfinding from ${startNode.id} to ${targetNode.id}...")

            try {
                val (result, debugSession) = findPathWithDebug(
                    startNode,
                    targetNode,
                    nodes = network.nodes,
                    negativeNodes = network.negativeNodes
                )

                debugSession?.let { session ->
                    player.msg("<green>Debug session captured with ${session.steps.size} steps!")

                    ContentModeTrigger(
                        context,
                        PathfindingDebugContentMode(context, player, ref, selectedNodeId, session)
                    ).triggerFor(player, context())
                } ?: run {
                    player.msg("<red>Debug pathfinding failed - no session data captured")

                    when (result) {
                        is PathCalculationResult.Success -> {
                            player.msg("<yellow>But pathfinding succeeded with path length ${result.length}")
                        }

                        is PathCalculationResult.Failure -> {
                            player.msg("<red>Pathfinding failed")
                        }
                    }
                }
            } catch (exception: Exception) {
                player.msg("<red>Debug pathfinding error: ${exception.message}")
                exception.printStackTrace()
            }
        }
    }
}

class RemoveNodeComponent(
    private val slot: Int = 0,
    private val onRemove: () -> Unit,
) : ItemComponent {
    override fun item(player: Player): Pair<Int, IntractableItem> {
        return slot to (ItemStack(Material.REDSTONE_BLOCK).apply {
            editMeta { meta ->
                meta.name = "<red><b>Remove Node"
                meta.loreString = "<line> <gray>Careful! This action is irreversible."
            }
        } onInteract {
            onRemove()
        })
    }
}

private class SelectedNodePathsComponent(
    private val nodeFetcher: () -> RoadNode?,
    private val networkFetcher: () -> RoadNetwork,
) : ContentComponent {
    private var paths: Map<RoadEdge, Path>? = null
    private var lastLoadHadFailure = false

    val isPathsLoaded: Boolean
        get() = paths != null

    override suspend fun initialize(player: Player) {
        Dispatchers.UntickedAsync.launch {
            paths = loadEdgePaths(player)
        }
    }

    private suspend fun loadEdgePaths(player: Player): Map<RoadEdge, Path> {
        val node = nodeFetcher() ?: return emptyMap()
        val network = networkFetcher()
        val nodes = network.nodes.associateBy { it.id }
        var hadFailure = false

        return network.edges.filter { it.start == node.id }
            .mapNotNull { edge ->
                val start = nodes[edge.start] ?: return@mapNotNull null
                val end = nodes[edge.end] ?: return@mapNotNull null

                val result = roadNetworkFindPath(
                    start,
                    end,
                    nodes = network.nodes,
                    negativeNodes = network.negativeNodes
                )

                if (result !is PathCalculationResult.Success) {
                    hadFailure = true
                    return@mapNotNull null
                }

                edge to result.path
            }
            .toMap()
            .also {
                when {
                    hadFailure && !lastLoadHadFailure -> {
                        player.msg("<red>Failed to load road network edges. You need to recalculate them.")
                        lastLoadHadFailure = true
                    }

                    !hadFailure -> lastLoadHadFailure = false
                }
            }
    }

    private suspend fun refreshEdges(player: Player) {
        val node = nodeFetcher() ?: return
        val network = networkFetcher()
        val edges = network.edges.filter { it.start == node.id }
        if (paths?.keys?.toSet() == edges.toSet()) return
        paths = loadEdgePaths(player)
    }

    private var tick = 0
    override suspend fun tick(player: Player) {
        if (paths == null) return
        if (tick++ % 20 == 0) {
            refreshEdges(player)
        }
        if (tick++ % 3 != 0) return

        paths?.forEach { (edge, pathPostion) ->
            pathPostion.forEach {
                WrapperPlayServerParticle(
                    Particle(
                        ParticleTypes.DUST,
                        ParticleDustData(1f, NetworkEdgesComponent.colorFromHash(edge.end.hashCode()).toPacketColor())
                    ),
                    true,
                    Vector3d(it.x + 0.5, it.y + 0.5, it.z + 0.5),
                    Vector3f.zero(),
                    0f,
                    1
                ) sendPacketTo player
            }
        }
    }

    override suspend fun dispose(player: Player) {}
}

class NodeRadiusComponent(
    private val nodeFetcher: () -> RoadNode?,
    private val initiallyScrolling: Boolean,
    private val slot: Int = 2,
    private val color: Color = Color.RED,
    private val editRadius: (Double) -> Unit,
) : ItemComponent, Listener {

    private var scrolling: UUID? = null

    override fun item(player: Player): Pair<Int, IntractableItem> {
        val item = if (scrolling != null) ItemStack(Material.CALIBRATED_SCULK_SENSOR).apply {
            editMeta { meta ->
                meta.name = "<yellow><b>Selecting Radius"
                meta.loreString = "<line> <gray>Right click to set the radius of the node."
                meta.unClickable()
            }
        } else ItemStack(Material.SCULK_SENSOR).apply {
            editMeta { meta ->
                meta.name = "<yellow><b>Change Radius"
                meta.loreString = "<line> <gray>Current radius: <white>${nodeFetcher()?.radius}"
                meta.unClickable()
            }
        }
        return slot to (item onInteract {
            scrolling = if (scrolling == player.uniqueId) {
                null
            } else {
                player.uniqueId
            }
            player.playSound("ui.button.click")
        })
    }

    override suspend fun initialize(player: Player) {
        super.initialize(player)
        if (initiallyScrolling) {
            // When we start out already selecting, we want to make sure the player is holding the correct item
            // So that they can stop changing the radius
            player.inventory.heldItemSlot = slot
            scrolling = player.uniqueId
        }
        plugin.registerEvents(this)
    }

    @EventHandler
    private fun onScroll(event: PlayerItemHeldEvent) {
        val player = event.player
        if (player.uniqueId != scrolling) return
        val delta = loopingDistance(event.previousSlot, event.newSlot, 8)
        val radiusMultiplier = if (player.isSneaking) 0.1 else 0.5
        editRadius(delta * radiusMultiplier)
        val sound = if (player.isSneaking) {
            "block.note_block.bell"
        } else {
            "block.note_block.hat"
        }
        player.playSound(sound, pitch = 1f + (delta * 0.1f), volume = 0.5f)
        event.isCancelled = true
    }

    private var tick: Int = 0
    override suspend fun tick(player: Player) {
        super.tick(player)
        if (tick++ % 2 == 0) return
        val node = nodeFetcher() ?: return
        val radius = node.radius
        val location = node.position

        location.particleSphere(player, radius, color, phiDivisions = 16, thetaDivisions = 8)
    }

    override suspend fun dispose(player: Player) {
        super.dispose(player)
        unregister()
    }
}

private class ModificationComponent(
    private val nodeFetcher: () -> RoadNode?,
    private val networkFetcher: () -> RoadNetwork,
) : ContentComponent, ItemsComponent {
    override fun items(player: Player): Map<Int, IntractableItem> {
        val map = mutableMapOf<Int, IntractableItem>()
        val node = nodeFetcher() ?: return map
        val network = networkFetcher()

        map[5] = ItemStack(Material.EMERALD).apply {
            editMeta { meta ->
                meta.name = "<green><b>Add Fast Travel Connection"
                meta.loreString = """
                    |<line> <gray>Click on a unconnected node to <green>add a fast travel connection</green> to it.
                    |<line> <gray>Click on a modified node to <red>remove the connection</red>.
                    |
                    |<line> <gray>If you only want to connect one way, hold <red>Shift</red> while clicking.
                    |""".trimMargin()
                meta.unClickable()
            }
        } onInteract {}

        val hasEdges = network.edges.any { it.start == node.id }
        if (hasEdges) {
            map[6] = ItemStack(Material.REDSTONE).apply {
                editMeta { meta ->
                    meta.name = "<red><b>Remove Edge"
                    meta.loreString = """
                    |<line> <gray>Click on a connected node to <red>force remove the edge</red> between them.
                    |<line> <gray>Click on a modified node to allow the edge to be added again.
                    |
                    |<line> <gray>If you only want to remove one way, hold <red>Shift</red> while clicking.
                """.trimMargin()
                    meta.unClickable()
                }
            } onInteract {
            }
        }

        return map
    }

    override suspend fun initialize(player: Player) {}

    override suspend fun tick(player: Player) {}

    override suspend fun dispose(player: Player) {}
}

private class RecalculateNodeComponent(
    private val nodeFetcher: () -> RoadNode?,
    private val editorStateFetcher: () -> RoadNetworkEditorState,
    private val onRecalculate: () -> Unit
) : ContentComponent, ItemsComponent {
    private var wasRecalculating = false

    override fun items(player: Player): Map<Int, IntractableItem> {
        val node = nodeFetcher() ?: return emptyMap()
        val state = editorStateFetcher()
        val isRecalculating = state is RoadNetworkEditorState.Calculating

        val compassItem = if (isRecalculating) {
            ItemStack(Material.CLOCK).apply {
                editMeta { meta ->
                    meta.name = "<yellow><b>Recalculating..."
                    meta.loreString = """
                        |<line> <gray>Recalculating edges for node ${node.id}
                        |<line> <gray>and connected nodes...
                        |
                        |<line> <yellow>Progress: ${state.max - state.nodesTodo}/${state.max}
                        |
                        |<line> <red>Please wait...
                        """.trimMargin()
                    meta.unClickable()
                }
            }
        } else {
            ItemStack(Material.COMPASS).apply {
                editMeta { meta ->
                    meta.name = "<blue><b>Recalculate Node Edges"
                    meta.loreString = """
                        |<line> <gray>Recalculate edges for this node
                        |<line> <gray>and connected nodes
                        |
                        |<line> <gray>Faster than recalculating all edges
                        """.trimMargin()
                }
            }
        }

        return mapOf(3 to (compassItem onInteract {
            if (it.type.isClick && !isRecalculating) {
                onRecalculate()
                player.playSound("ui.button.click")
            }
        }))
    }

    override suspend fun initialize(player: Player) {}

    override suspend fun tick(player: Player) {
        val state = editorStateFetcher()
        val isRecalculating = state is RoadNetworkEditorState.Calculating

        if (wasRecalculating && !isRecalculating) {
            if (nodeFetcher() != null) {
                player.playSound("entity.experience_orb.pickup")
            }
        }

        wasRecalculating = isRecalculating
    }

    override suspend fun dispose(player: Player) {}
}

private class PathfindingDebugInitiatorComponent : ItemComponent {
    override fun item(player: Player): Pair<Int, IntractableItem> {
        val item = ItemStack(Material.SPYGLASS).apply {
            editMeta { meta ->
                meta.name = "<dark_purple><b>Debug Pathfinding"
                meta.loreString = """
                    |<line> <gray>Hold this item and click on another node
                    |<line> <gray>to start a debug pathfinding session.
                    """.trimMargin()
                meta.unClickable()
            }
        }
        return 7 to (item onInteract { })
    }
}