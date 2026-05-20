package com.typewritermc.roadnetwork

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.roadnetwork.gps.roadNetworkFindPath
import com.typewritermc.roadnetwork.pathfinding.pathetic.PathCalculationResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.concurrent.atomic.AtomicInteger

class RoadNetworkEditor(
    private val ref: Ref<out RoadNetworkEntry>,
) : KoinComponent {
    private val networkManager: RoadNetworkManager by inject()

    var network: RoadNetwork = RoadNetwork()
        private set

    private var lastChange: Long = -1
    private var job: Job? = null
    private var jobRecalculateEdges: Job? = null
    private var recalculateEdges = AtomicInteger(0)
    private var totalNodesToRecalculate = AtomicInteger(0)
    private var mutex = Mutex()

    val state: RoadNetworkEditorState
        get() = when {
            jobRecalculateEdges != null -> RoadNetworkEditorState.Calculating(
                recalculateEdges.get(),
                totalNodesToRecalculate.get()
            )

            lastChange < 0 -> RoadNetworkEditorState.Loading
            job != null -> RoadNetworkEditorState.Saving
            lastChange != Long.MAX_VALUE -> RoadNetworkEditorState.Dirty
            else -> RoadNetworkEditorState.Idle
        }

    fun load() {
        Dispatchers.UntickedAsync.launch {
            mutex.withLock {
                network = networkManager.getNetwork(ref)
                lastChange = Long.MAX_VALUE
            }
        }
    }

    suspend fun update(block: suspend (RoadNetwork) -> RoadNetwork) {
        mutex.withLock {
            network = block(network)
            lastChange = System.currentTimeMillis()
        }
    }

    fun recalculateEdges() {
        jobRecalculateEdges?.cancel()

        jobRecalculateEdges = Dispatchers.UntickedAsync.launch {
            update {
                it.copy(edges = emptyList())
            }

            val allNodes = network.nodes
            recalculateEdges.set(allNodes.size)
            totalNodesToRecalculate.set(allNodes.size)

            coroutineScope {
                allNodes.chunked(10).map { nodeChunk ->
                    launch {
                        nodeChunk.forEach { node ->
                            recalculateEdgesForNode(node)
                            recalculateEdges.decrementAndGet()
                        }
                    }
                }
            }
            jobRecalculateEdges = null
        }
    }

    fun recalculateEdgesForSingleNode(nodeId: RoadNodeId) {
        val node = network.nodes.find { it.id == nodeId } ?: return

        jobRecalculateEdges?.cancel()

        jobRecalculateEdges = Dispatchers.UntickedAsync.launch {
            val affectedNodes = findAffectedNodes(node)

            recalculateEdges.set(affectedNodes.size)
            totalNodesToRecalculate.set(affectedNodes.size)

            coroutineScope {
                affectedNodes.chunked(5).map { nodeChunk ->
                    launch {
                        nodeChunk.forEach { affectedNode ->
                            recalculateEdgesForNode(affectedNode)
                            recalculateEdges.decrementAndGet()
                        }
                    }
                }
            }

            jobRecalculateEdges = null
        }
    }

    private fun findAffectedNodes(targetNode: RoadNode): Set<RoadNode> {
        val affectedNodes = mutableSetOf(targetNode)

        val nodesWithEdgesToTarget = network.edges
            .filter { it.end == targetNode.id }
            .mapNotNull { edge -> network.nodes.find { it.id == edge.start } }

        val nodesWithEdgesFromTarget = network.edges
            .filter { it.start == targetNode.id }
            .mapNotNull { edge -> network.nodes.find { it.id == edge.end } }

        val nodesInRange = network.nodes.filter {
            it != targetNode
                    && it.position.world == targetNode.position.world
                    && it.position.distanceSquared(targetNode.position)!! < roadNetworkMaxDistance * roadNetworkMaxDistance
        }

        affectedNodes.addAll(nodesWithEdgesToTarget)
        affectedNodes.addAll(nodesWithEdgesFromTarget)
        affectedNodes.addAll(nodesInRange)

        return affectedNodes
    }

    private suspend fun recalculateEdgesForNode(node: RoadNode) {
        val interestingNodes = network.nodes
            .filter {
                it != node
                        && it.position.world == node.position.world
                        && it.position.distanceSquared(node.position)!! < roadNetworkMaxDistance * roadNetworkMaxDistance
            }
        val generatedEdges =
            interestingNodes
                .filter { !network.modifications.containsRemoval(node.id, it.id) }
                .mapNotNull { target ->
                    val path = roadNetworkFindPath(
                        node,
                        target,
                        nodes = interestingNodes,
                        negativeNodes = network.negativeNodes
                    )

                    if (path !is PathCalculationResult.Success) {
                        return@mapNotNull null
                    }

                    RoadEdge(node.id, target.id, weight = path.weight, length = path.length)
                }

        val manualEdges = network.modifications
            .asSequence()
            .filterIsInstance<RoadModification.EdgeAddition>()
            .filter { it.start == node.id }
            .map { RoadEdge(it.start, it.end, it.weight, it.length) }

        val edges = (generatedEdges + manualEdges).toList()

        update { roadNetwork ->
            roadNetwork.copy(edges = roadNetwork.edges.filter { it.start != node.id } + edges)
        }
    }

    fun refresh() {
        if (lastChange < 0) return
        if (lastChange + 3_000 > System.currentTimeMillis()) return
        if (job != null) return
        job = Dispatchers.UntickedAsync.launch {
            val network = mutex.withLock {
                lastChange = Long.MAX_VALUE
                network = network.copy(
                    nodes = network.nodes.distinct(),
                    edges = network.edges.distinct(),
                    modifications = network.modifications.distinct(),
                )
                network
            }
            networkManager.saveRoadNetwork(ref, network)
            job = null
        }
    }

    suspend fun dispose() {
        job?.cancel()
        job = null
        jobRecalculateEdges?.cancel()
        jobRecalculateEdges = null
        networkManager.saveRoadNetwork(ref, network)
        lastChange = Long.MAX_VALUE
    }
}

sealed class RoadNetworkEditorState(val message: String) {
    data object Loading : RoadNetworkEditorState(" <gray><i>(loading)</i></gray>")
    data object Idle : RoadNetworkEditorState("")
    data object Dirty : RoadNetworkEditorState(" <gray><i>(unsaved changes)</i></gray>")
    data object Saving : RoadNetworkEditorState(" <red><i>(saving)</i></red>")

    class Calculating(val nodesTodo: Int, val max: Int) :
        RoadNetworkEditorState(" <red><i>(calculating ${max - nodesTodo}/$max nodes)</i></red>") {
        val percentage: Float
            get() = if (max > 0) (max - nodesTodo) / max.toFloat() else 1f
    }
}