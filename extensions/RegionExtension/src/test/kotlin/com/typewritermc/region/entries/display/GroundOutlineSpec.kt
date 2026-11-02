package com.typewritermc.region.entries.display

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.SphereShape
import io.kotest.assertions.withClue
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.doubles.shouldBeGreaterThan
import io.kotest.matchers.doubles.shouldBeLessThan
import io.kotest.matchers.ints.shouldBeGreaterThanOrEqual
import io.kotest.matchers.shouldBe
import org.bukkit.Material
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import kotlin.math.hypot
import kotlin.math.sqrt

class GroundOutlineSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock
    private lateinit var terrain: WorldTerrain

    private fun transformAt(x: Double, y: Double, z: Double, yawDegrees: Float = 0f) = ResolvedTransform(
        world = World(world.uid.toString()),
        worldOrigin = Vector(x, y, z),
        yawDegrees = yawDegrees,
        pitchDegrees = 0f,
    )

    /** Horizontal distances between consecutive points, wrap included, in list order. */
    private fun loopGaps(points: List<GroundOutlinePoint>): List<Double> = points.indices.map { index ->
        val a = points[index].position
        val b = points[(index + 1) % points.size].position
        hypot(b.x - a.x, b.z - a.z)
    }

    private fun placePlatform(minX: Int, maxX: Int, minZ: Int, maxZ: Int, y: Int) {
        for (x in minX..maxX) for (z in minZ..maxZ) {
            world.getBlockAt(x, y, z).type = Material.STONE
        }
        for (chunkX in (minX shr 4)..(maxX shr 4)) for (chunkZ in (minZ shr 4)..(maxZ shr 4)) {
            world.loadChunk(chunkX, chunkZ)
        }
    }

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("ground-world")
            terrain = WorldTerrain(world)
        }

        afterSpec {
            MockBukkit.unmock()
        }

        test("a grounded box outlines its footprint perimeter on the platform surface") {
            placePlatform(90, 110, 90, 110, y = 99)
            val shape = CuboidShape(3.0, 3.0, 3.0)
            val transform = transformAt(100.0, 101.0, 100.0)
            val points = sampleGroundOutline(shape, transform, world, terrain)

            // Columns 97..102 on both axes are inside; a 6 by 6 square has 20 border columns.
            points.size shouldBe 20
            for ((position) in points) {
                position.y shouldBe (99.0 + 1.0 + 0.05 plusOrMinus 1e-9)
                // Every point hugs the silhouette, pulled slightly inside.
                shape.signedDistanceHorizontal(transform.toLocal(position)) shouldBe (-0.05 plusOrMinus 0.05)
            }

            for (cornerX in listOf(97.05, 102.95)) for (cornerZ in listOf(97.05, 102.95)) {
                points.minOf { hypot(it.position.x - cornerX, it.position.z - cornerZ) } shouldBeLessThan 0.1
            }

            val westEdge = points.minBy { hypot(it.position.x - 97.05, it.position.z - 100.5) }
            westEdge.position.x shouldBe (97.05 plusOrMinus 0.01)
            westEdge.outward.x shouldBe (-1.0 plusOrMinus 1e-6)
            westEdge.outward.z shouldBe (0.0 plusOrMinus 1e-6)
        }

        test("a rotated box gets outline points at its silhouette tips") {
            placePlatform(90, 110, 90, 110, y = 99)
            val shape = CuboidShape(3.0, 3.0, 3.0)
            val transform = transformAt(100.0, 101.0, 100.0, yawDegrees = 45f)
            val points = sampleGroundOutline(shape, transform, world, terrain)

            // At 45 degrees the footprint is a diamond; its tips fall between block
            // columns, so only explicit corner recovery puts a point there.
            val tipDistance = (3.0 - 0.05) * sqrt(2.0)
            val tips = listOf(
                Vector(100.0 + tipDistance, 0.0, 100.0),
                Vector(100.0 - tipDistance, 0.0, 100.0),
                Vector(100.0, 0.0, 100.0 + tipDistance),
                Vector(100.0, 0.0, 100.0 - tipDistance),
            )
            for ((x, _, z) in tips) {
                points.minOf { hypot(it.position.x - x, it.position.z - z) } shouldBeLessThan 0.3
            }
        }

        test("where the ground ends under the region, the outline follows the cliff") {
            placePlatform(90, 99, 120, 140, y = 99)
            val shape = CuboidShape(3.0, 3.0, 3.0)
            val points = sampleGroundOutline(shape, transformAt(100.0, 101.0, 130.0), world, terrain)

            // Only columns 97..99 have ground; a 3 by 6 rectangle has 14 border columns.
            points.size shouldBe 14
            points.count { it.position.x > 99.5 } shouldBe 0
        }

        test("a canopy inside the region's span does not lift the line off the ground") {
            placePlatform(190, 210, 190, 210, y = 99)
            // A solid slab hanging inside the span, like a tree canopy or a roof.
            placePlatform(196, 204, 196, 204, y = 104)
            val shape = CuboidShape(4.0, 5.0, 4.0)
            val transform = transformAt(200.0, 102.0, 200.0)
            val points = sampleGroundOutline(shape, transform, world, terrain)

            points.size shouldBeGreaterThanOrEqual 8
            for ((position) in points) {
                position.y shouldBe (99.0 + 1.0 + 0.05 plusOrMinus 1e-9)
            }
        }

        test("a region hovering above the ground draws nothing") {
            placePlatform(90, 110, 90, 110, y = 99)
            val shape = CuboidShape(3.0, 3.0, 3.0)
            sampleGroundOutline(shape, transformAt(100.0, 110.0, 100.0), world, terrain).shouldBeEmpty()
        }

        test("resampling spreads points evenly along each edge with a point on every corner") {
            placePlatform(90, 110, 90, 110, y = 99)
            val shape = CuboidShape(3.0, 3.0, 3.0)
            val transform = transformAt(100.0, 101.0, 100.0)
            val raw = sampleGroundOutline(shape, transform, world, terrain)
            val points = resampleBySpacing(raw, 1.0, shape, transform, world, terrain)

            for (cornerX in listOf(97.05, 102.95)) for (cornerZ in listOf(97.05, 102.95)) {
                points.minOf { hypot(it.position.x - cornerX, it.position.z - cornerZ) } shouldBeLessThan 0.1
            }
            val gaps = loopGaps(points)
            gaps.min() shouldBeGreaterThan 0.85
            gaps.max() shouldBeLessThan 1.15
        }

        test("entity spacing is uniform around a rotated box, corners included") {
            placePlatform(90, 110, 90, 110, y = 99)
            val shape = CuboidShape(3.0, 3.0, 3.0)
            val transform = transformAt(100.0, 101.0, 100.0, yawDegrees = 45f)
            val raw = sampleGroundOutline(shape, transform, world, terrain)
            val points = resampleBySpacing(raw, 3.0, shape, transform, world, terrain)

            val tipDistance = (3.0 - 0.05) * sqrt(2.0)
            val tips = listOf(
                Vector(100.0 + tipDistance, 0.0, 100.0),
                Vector(100.0 - tipDistance, 0.0, 100.0),
                Vector(100.0, 0.0, 100.0 + tipDistance),
                Vector(100.0, 0.0, 100.0 - tipDistance),
            )
            for ((x, _, z) in tips) {
                points.minOf { hypot(it.position.x - x, it.position.z - z) } shouldBeLessThan 0.3
            }
            val gaps = loopGaps(points)
            gaps.min() shouldBeGreaterThan 2.5
            gaps.max() shouldBeLessThan 3.5
        }

        test("a cornerless loop resamples seamlessly, the closing gap matching the rest") {
            placePlatform(90, 110, 90, 110, y = 99)
            val shape = SphereShape(4.0)
            val transform = transformAt(100.0, 100.0, 100.0)
            val raw = sampleGroundOutline(shape, transform, world, terrain)
            raw.none { it.corner } shouldBe true

            val points = resampleBySpacing(raw, 3.0, shape, transform, world, terrain)
            val gaps = loopGaps(points)
            gaps.min() shouldBeGreaterThan 2.5
            (gaps.max() / gaps.min()) shouldBeLessThan 1.2
        }

        test("a silhouette overhanging the footprint still resamples along the walkable line") {
            placePlatform(90, 110, 90, 110, y = 99)
            // The sphere's widest slice floats a block above the floor, so the silhouette
            // is wider than what the floor can drape; the chord fallback keeps the line.
            val shape = SphereShape(4.0)
            val transform = transformAt(100.0, 101.0, 100.0)
            val raw = sampleGroundOutline(shape, transform, world, terrain)
            val points = resampleBySpacing(raw, 3.0, shape, transform, world, terrain)

            points.size shouldBeGreaterThanOrEqual 6
            val gaps = loopGaps(points)
            gaps.min() shouldBeGreaterThan 2.0
            gaps.max() shouldBeLessThan 4.5
        }

        test("corner coverage and even spacing hold across yaws") {
            placePlatform(80, 120, 80, 120, y = 99)
            val halfX = 3.0
            val halfZ = 5.0
            val shape = CuboidShape(halfX, 3.0, halfZ)
            for (yawDegrees in 0..90 step 5) {
                val transform = transformAt(100.0, 101.0, 100.0, yawDegrees = yawDegrees.toFloat())
                val raw = sampleGroundOutline(shape, transform, world, terrain)
                val points = resampleBySpacing(raw, 1.0, shape, transform, world, terrain)
                val corners = listOf(
                    Vector(halfX - 0.05, 0.0, halfZ - 0.05),
                    Vector(-(halfX - 0.05), 0.0, halfZ - 0.05),
                    Vector(halfX - 0.05, 0.0, -(halfZ - 0.05)),
                    Vector(-(halfX - 0.05), 0.0, -(halfZ - 0.05)),
                ).map { transform.toWorld(it) }

                withClue("yaw $yawDegrees") {
                    for ((x, _, z) in corners) {
                        points.minOf { hypot(it.position.x - x, it.position.z - z) } shouldBeLessThan 0.35
                    }
                    val gaps = loopGaps(points)
                    gaps.min() shouldBeGreaterThan 0.3
                    gaps.max() shouldBeLessThan 1.6
                }
            }
        }
    }
}
