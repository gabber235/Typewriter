package com.typewritermc.roadnetwork

import co.touchlab.stately.concurrency.AtomicInt
import com.github.shynixn.mccoroutine.bukkit.launch
import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.ThreadType.DISPATCHERS_ASYNC
import com.typewritermc.roadnetwork.gps.roadNetworkFindPath
import com.typewritermc.roadnetwork.pathfinding.PFInstanceSpace
import com.typewritermc.roadnetwork.pathfinding.instanceSpace
import kotlinx.coroutines.Job
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.concurrent.Executors
import kotlin.math.max

class RoadNetworkEditor(
    private val ref: Ref<out RoadNetworkEntry>,
) : KoinComponent {
    private val networkManager: RoadNetworkManager by inject()

    var network: RoadNetwork = RoadNetwork()
        private set

    private var lastChange: Long = -1
    private var job: Job? = null
    private var jobRecalculateEdges: Job? = null
    private var recalculateEdges = AtomicInt(0)
    private var mutex = Mutex()

    val state: RoadNetworkEditorState
        get() = when {
            jobRecalculateEdges != null -> RoadNetworkEditorState.Calculating(
                recalculateEdges.get(),
                network.nodes.size
            )

            lastChange < 0 -> RoadNetworkEditorState.Loading
            job != null -> RoadNetworkEditorState.Saving
            lastChange != Long.MAX_VALUE -> RoadNetworkEditorState.Dirty
            else -> RoadNetworkEditorState.Idle
        }

    fun load() {
        DISPATCHERS_ASYNC.launch {
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

        val nrOfThreads = max(Runtime.getRuntime().availableProcessors() / 2, 1)
        jobRecalculateEdges = plugin.launch(Executors.newFixedThreadPool(nrOfThreads).asCoroutineDispatcher()) {
            update {
                it.copy(edges = emptyList())
            }
            recalculateEdges.set(network.nodes.size)
            coroutineScope {
                network.nodes.map {
                    launch {
                        recalculateEdgesForNode(it, it.location.world.instanceSpace)
                        recalculateEdges.decrementAndGet()
                    }
                }
            }
            jobRecalculateEdges = null
        }
    }

    private suspend fun recalculateEdgesForNode(node: RoadNode, instance: PFInstanceSpace) {
        val interestingNodes = network.nodes
            .filter { it != node && it.location.world == node.location.world && it.location.distanceSquared(node.location) < roadNetworkMaxDistance * roadNetworkMaxDistance }
        val generatedEdges =
            interestingNodes
                .filter { !network.modifications.containsRemoval(node.id, it.id) }
                .mapNotNull { target ->
                    val path = roadNetworkFindPath(
                        node,
                        target,
                        instance = instance,
                        nodes = interestingNodes,
                        negativeNodes = network.negativeNodes
                    ) ?: return@mapNotNull null

                    RoadEdge(node.id, target.id, path.length().toDouble())
                }

        val manualEdges = network.modifications
            .asSequence()
            .filterIsInstance<RoadModification.EdgeAddition>()
            .filter { it.start == node.id }
            .map { RoadEdge(it.start, it.end, it.weight) }

        val edges = (generatedEdges + manualEdges).toList()

        update { roadNetwork ->
            roadNetwork.copy(edges = roadNetwork.edges.filter { it.start != node.id } + edges)
        }
    }

    fun refresh() {
        if (lastChange < 0) return
        if (lastChange + 3_000 > System.currentTimeMillis()) return
        if (job != null) return
        job = DISPATCHERS_ASYNC.launch {
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
        RoadNetworkEditorState(" <red><i>(calculating ${max - nodesTodo}/$max)</i></red>") {
        val percentage: Float
            get() = (max - nodesTodo) / max.toFloat()
    }
}