package com.typewritermc.roadnetwork.gps

import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.engine.paper.snippets.SnippetDatabase
import com.typewritermc.roadnetwork.RoadEdge
import com.typewritermc.roadnetwork.RoadNetwork
import com.typewritermc.roadnetwork.RoadNetworkManager
import com.typewritermc.roadnetwork.RoadNode
import com.typewritermc.roadnetwork.RoadNodeId
import de.bsommerfeld.pathetic.api.pathing.Pathfinder
import de.bsommerfeld.pathetic.api.pathing.PathfindingSearch
import de.bsommerfeld.pathetic.api.pathing.context.EnvironmentContext
import de.bsommerfeld.pathetic.api.pathing.hook.PathfinderHook
import de.bsommerfeld.pathetic.api.pathing.result.Path
import de.bsommerfeld.pathetic.api.pathing.result.PathState
import de.bsommerfeld.pathetic.api.pathing.result.PathfinderResult
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.mockk.coEvery
import io.mockk.mockk
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import java.util.Optional
import java.util.concurrent.atomic.AtomicInteger
import java.util.function.Consumer
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.sqrt
import kotlin.reflect.KClass

/**
 * A block level pathfinder that always succeeds with a straight line, one block per step.
 * A path therefore holds `ceil(distance) + 1` positions, which is what pathetic reports as its length.
 */
private class StraightLinePathfinder(private val calls: AtomicInteger) : Pathfinder {
    override fun findPath(start: PathPosition, target: PathPosition, context: EnvironmentContext): PathfindingSearch {
        calls.incrementAndGet()
        return CompletedSearch(StraightPath(straightLineBetween(start, target)))
    }

    @Suppress("OVERRIDE_DEPRECATION")
    override fun registerPathfindingHook(hook: PathfinderHook) {}
}

private class CompletedSearch(path: Path) : PathfindingSearch {
    private val result: PathfinderResult = SuccessfulResult(path)

    override fun ifPresent(consumer: Consumer<PathfinderResult>): PathfindingSearch {
        consumer.accept(result)
        return this
    }

    override fun orElse(consumer: Consumer<PathfinderResult>): PathfindingSearch = this
    override fun exceptionally(consumer: Consumer<Throwable>): PathfindingSearch = this
    override fun resultBlocking(): PathfinderResult = result
    override fun result(): Optional<PathfinderResult> = Optional.of(result)
    override fun done(): Boolean = true
    override fun abort() {}
}

private class SuccessfulResult(private val path: Path) : PathfinderResult {
    override fun successful(): Boolean = true
    override fun hasFailed(): Boolean = false
    override fun hasFallenBack(): Boolean = false
    override fun getPathState(): PathState = PathState.FOUND
    override fun getPath(): Path = path
}

private class StraightPath(private val positions: MutableList<PathPosition>) : Path {
    override fun length(): Int = positions.size
    override fun getStart(): PathPosition = positions.first()
    override fun getEnd(): PathPosition = positions.last()
    override fun collect(): Collection<PathPosition> = positions
    override fun iterator(): MutableIterator<PathPosition> = positions.iterator()
}

private fun straightLineBetween(start: PathPosition, end: PathPosition): MutableList<PathPosition> {
    val dx = end.x - start.x
    val dy = end.y - start.y
    val dz = end.z - start.z
    val steps = max(1, ceil(sqrt(dx * dx + dy * dy + dz * dz)).toInt())
    return (0..steps).mapTo(mutableListOf()) { step ->
        val progress = step.toDouble() / steps
        PathPosition(start.x + dx * progress, start.y + dy * progress, start.z + dz * progress)
    }
}

private fun blockPathLength(from: Position, to: Position): Double =
    (max(1, ceil(sqrt(from.distanceSquared(to)!!)).toInt()) + 1).toDouble()

private class DefaultSnippetDatabase : SnippetDatabase {
    override fun get(path: String, default: Any, comment: String): Any = default
    override fun <T : Any> getSnippet(path: String, klass: KClass<T>, default: T, comment: String): T = default
    override fun registerSnippet(path: String, defaultValue: Any, comment: String) {}
}

private const val NODE_COUNT = 9
private const val NODE_SPACING = 25.0

class TemporaryStartNodeGPSSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: World
    private lateinit var network: RoadNetwork
    private val blockPathfinderCalls = AtomicInteger()

    private fun positionAt(x: Double) = Position(world, x, 64.0, 0.0)

    init {
        beforeTest {
            blockPathfinderCalls.set(0)
            server = MockBukkit.mock()
            world = World(server.addSimpleWorld("gps-temporary-node-world").uid.toString())

            // A straight road running from x = 0 to x = 200. The spacing is close enough that a start
            // between the first two nodes reaches both, and the destination is far enough that the
            // node behind the start still scores lower than the node ahead of it.
            val nodes = (0 until NODE_COUNT).map { index ->
                RoadNode(RoadNodeId(index + 1), positionAt(index * NODE_SPACING), 1.0)
            }
            val edges = nodes.zipWithNext().flatMap { (first, second) ->
                val length = blockPathLength(first.position, second.position)
                listOf(
                    RoadEdge(first.id, second.id, weight = length, length = length),
                    RoadEdge(second.id, first.id, weight = length, length = length),
                )
            }
            network = RoadNetwork(nodes = nodes, edges = edges)

            val manager = mockk<RoadNetworkManager>()
            coEvery { manager.getNetwork(any()) } returns network

            startKoin {
                modules(
                    module {
                        single<RoadNetworkManager> { manager }
                        factory<Boolean>(named("isEnabled")) { true }
                        single<SnippetDatabase> { DefaultSnippetDatabase() }
                        factory<Pathfinder> { StraightLinePathfinder(blockPathfinderCalls) }
                    }
                )
            }
        }

        afterTest {
            stopKoin()
            MockBukkit.unmock()
        }

        test("a start between two nodes builds a temporary node and heads forward") {
            val gps = PointToPointGPS(emptyRef(), { positionAt(3.0) }, { positionAt(200.0) })

            val route = gps.findPath().getOrThrow()

            blockPathfinderCalls.get() shouldBeGreaterThan 0
            route.first().start shouldBe positionAt(3.0)
            route.first().end shouldBe positionAt(25.0)
            route.last().end shouldBe positionAt(200.0)
        }

        test("a search from between two nodes heads forward once the previous route is cleared") {
            var start = positionAt(-5.0)
            val gps = PointToPointGPS(emptyRef(), { start }, { positionAt(200.0) })

            val first = gps.findPath().getOrThrow()
            val callsAfterFirst = blockPathfinderCalls.get()

            start = positionAt(3.0)
            gps.clearPreviousPath()
            val second = gps.findPath().getOrThrow()

            callsAfterFirst shouldBeGreaterThan 0
            blockPathfinderCalls.get() shouldBeGreaterThan callsAfterFirst
            first.first().start shouldBe positionAt(-5.0)
            first.first().end shouldBe positionAt(0.0)

            second.first().start shouldBe positionAt(3.0)
            second.first().end shouldBe positionAt(25.0)
            second.last().end shouldBe positionAt(200.0)
        }
    }
}
