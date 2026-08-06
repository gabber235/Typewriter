package com.typewritermc.roadnetwork.gps

import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.roadnetwork.RoadEdge
import com.typewritermc.roadnetwork.RoadNetwork
import com.typewritermc.roadnetwork.RoadNetworkManager
import com.typewritermc.roadnetwork.RoadNode
import com.typewritermc.roadnetwork.RoadNodeId
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.core.qualifier.named
import org.koin.dsl.module
import kotlinx.coroutines.Job
import kotlinx.coroutines.withTimeout
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.math.abs
import kotlin.time.Duration.Companion.seconds

private const val SEARCH_TIMEOUT_SECONDS = 10L

private val world = World("gps-world")

private fun positionAt(x: Double) = Position(world, x, 64.0, 0.0)

private fun CountDownLatch.awaitSearch() {
    await(SEARCH_TIMEOUT_SECONDS, TimeUnit.SECONDS) shouldBe true
}

private suspend fun Job.joinSearch() {
    withTimeout(SEARCH_TIMEOUT_SECONDS.seconds) { join() }
}

private fun edgeBetween(start: RoadNode, end: RoadNode): RoadEdge {
    val length = abs(start.position.x - end.position.x)
    return RoadEdge(start.id, end.id, weight = length, length = length)
}

class PointToPointGPSSpec : FunSpec({
    val behind = RoadNode(RoadNodeId(1), positionAt(0.0), 1.0)
    val ahead = RoadNode(RoadNodeId(2), positionAt(40.0), 1.0)
    val destination = RoadNode(RoadNodeId(3), positionAt(200.0), 1.0)
    val between = RoadNode(RoadNodeId(4), positionAt(5.0), 1.0)

    val network = RoadNetwork(
        nodes = listOf(behind, ahead, destination, between),
        edges = listOf(
            edgeBetween(behind, ahead), edgeBetween(ahead, behind),
            edgeBetween(ahead, destination), edgeBetween(destination, ahead),
            edgeBetween(between, behind), edgeBetween(behind, between),
            edgeBetween(between, ahead), edgeBetween(ahead, between),
        ),
    )

    beforeTest {
        val manager = mockk<RoadNetworkManager>()
        coEvery { manager.getNetwork(any()) } returns network
        startKoin {
            modules(
                module {
                    single<RoadNetworkManager> { manager }
                    factory<Boolean>(named("isEnabled")) { true }
                }
            )
        }
    }

    afterTest { stopKoin() }

    test("a search from between two nodes takes the node ahead") {
        val gps = PointToPointGPS(emptyRef(), { between.position }, { destination.position })

        val route = gps.findPath().getOrThrow()

        route.map { it.end } shouldBe listOf(ahead.position, destination.position)
    }

    test("a search takes the node ahead once the previous route is cleared") {
        var start = behind.position
        val gps = PointToPointGPS(emptyRef(), { start }, { destination.position })

        gps.findPath().getOrThrow()
        start = between.position
        gps.clearPreviousPath()

        val route = gps.findPath().getOrThrow()

        route.map { it.end } shouldBe listOf(ahead.position, destination.position)
    }

    test("a search that finishes after a clear does not store its route") {
        val startedSearch = CountDownLatch(1)
        val holdSearch = CountDownLatch(1)
        var holdNextSearch = false
        var start = behind.position
        val gps = PointToPointGPS(emptyRef(), {
            if (holdNextSearch) {
                startedSearch.countDown()
                holdSearch.await()
            }
            start
        }, { destination.position })

        gps.findPath().getOrThrow()

        holdNextSearch = true
        val job = Dispatchers.UntickedAsync.launch { gps.findPath() }
        try {
            startedSearch.awaitSearch()
            gps.clearPreviousPath()
        } finally {
            holdSearch.countDown()
        }
        job.joinSearch()

        start = between.position
        val route = gps.findPath().getOrThrow()

        route.map { it.end } shouldBe listOf(ahead.position, destination.position)
    }

    test("a cancelled search does not store its route") {
        val startedSearch = CountDownLatch(1)
        val holdSearch = CountDownLatch(1)
        var start = behind.position
        val gps = PointToPointGPS(emptyRef(), {
            startedSearch.countDown()
            holdSearch.await()
            start
        }, { destination.position })

        val job = Dispatchers.UntickedAsync.launch { runCatching { gps.findPath() } }
        try {
            startedSearch.awaitSearch()
            job.cancel()
        } finally {
            holdSearch.countDown()
        }
        job.joinSearch()

        start = between.position
        val route = gps.findPath().getOrThrow()

        route.map { it.end } shouldBe listOf(ahead.position, destination.position)
    }
})
