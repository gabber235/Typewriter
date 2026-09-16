package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin
import kotlin.system.measureTimeMillis

/**
 * A boundary sample becomes a fake entity, a block packet or a particle, so the count has to
 * stay bounded whatever a builder types into the panel. The step length alone does not bound
 * it: a shape sampled edge by edge or ring by ring emits at least one column per edge.
 */
class SampleBudgetSpec : FunSpec({
    fun polygon(vertices: Int, radius: Double, halfHeight: Double): PolygonShape {
        val points = List(vertices) { index ->
            val angle = 2 * PI * index / vertices
            Vector(cos(angle) * radius, 0.0, sin(angle) * radius)
        }
        return PolygonShape(points, halfHeight)
    }

    test("a traced town outline stays within the budget") {
        for (shape in listOf(polygon(40, 50.0, 160.0), polygon(120, 50.0, 160.0), polygon(60, 30.0, 30.0))) {
            (shape.sampleBoundary(0.5).count() <= MAX_BOUNDARY_SAMPLES) shouldBe true
        }
    }

    test("a polygon whose vertex count alone breaches the budget is truncated at it") {
        // One column per edge is the floor whatever the step is, so enough vertices exceed the
        // budget on their own and only the hard stop can bound them.
        polygon(2000, 500.0, 500.0).sampleBoundary(0.5).count() shouldBe MAX_BOUNDARY_SAMPLES
    }

    test("a needle cuboid stays within the budget") {
        (CuboidShape(1.0, 20000.0, 1.0).sampleBoundary(0.5).count() <= MAX_BOUNDARY_SAMPLES) shouldBe true
        (CuboidShape(1.0, 1000000.0, 1.0).sampleBoundary(0.5).count() <= MAX_BOUNDARY_SAMPLES) shouldBe true
    }

    test("a long cone and a long capsule stay within the budget") {
        for (length in listOf(300.0, 1000.0, 2000.0)) {
            (ConeShape(length, 30.0).sampleBoundary(0.5).count() <= MAX_BOUNDARY_SAMPLES) shouldBe true
            (ConeShape(length, 10.0).sampleBoundary(0.5).count() <= MAX_BOUNDARY_SAMPLES) shouldBe true
        }
        (CapsuleShape(1.0, 1000000.0).sampleBoundary(0.5).count() <= MAX_BOUNDARY_SAMPLES) shouldBe true
        (CapsuleShape(2000.0, 1.0).sampleBoundary(0.5).count() <= MAX_BOUNDARY_SAMPLES) shouldBe true
    }

    test("a wide capsule keeps its caps rather than losing them to the budget") {
        // Truncation drops the tail of the sequence, and the caps are emitted last, so sizing a
        // polar ring like the equator spends the budget before reaching the poles.
        for (radius in listOf(60.0, 100.0, 150.0)) {
            val capsule = CapsuleShape(radius, 0.0)
            val samples = capsule.sampleBoundary(0.5).toList()
            (samples.size <= MAX_BOUNDARY_SAMPLES) shouldBe true
            val highest = samples.maxOf { it.y }
            (highest > radius * 0.98) shouldBe true
            (samples.minOf { it.y } < -radius * 0.98) shouldBe true
        }
    }

    test("a plaza sized cuboid keeps every face rather than losing the last ones to truncation") {
        val plaza = CuboidShape(100.0, 5.0, 100.0)
        val samples = plaza.sampleBoundary(0.5).toList()
        (samples.size < MAX_BOUNDARY_SAMPLES) shouldBe true
        for (y in listOf(-5.0, -2.5, 0.0, 2.5, 5.0)) {
            samples.any { abs(it.y - y) < 1.5 && (abs(abs(it.x) - 100.0) < 1e-6 || abs(abs(it.z) - 100.0) < 1e-6) } shouldBe true
        }
        samples.any { it.y == 5.0 } shouldBe true
        samples.any { it.y == -5.0 } shouldBe true
    }

    test("a traced town outline keeps its floor and its ceiling") {
        val samples = polygon(40, 50.0, 160.0).sampleBoundary(0.5).toList()
        (samples.size < MAX_BOUNDARY_SAMPLES) shouldBe true
        samples.any { it.y == 160.0 } shouldBe true
        samples.any { it.y == -160.0 } shouldBe true
    }

    test("the cap fill covers exactly the lattice points inside the outline") {
        val square = PolygonShape(
            points = listOf(
                Vector(-2.0, 0.0, -2.0),
                Vector(2.0, 0.0, -2.0),
                Vector(2.0, 0.0, 2.0),
                Vector(-2.0, 0.0, 2.0),
            ),
            halfHeight = 1.0,
        )
        // Step 1.0 over a 4 by 4 outline: nine lattice points lie strictly inside, and each of
        // them belongs to both the floor and the ceiling.
        val caps = square.sampleBoundary(1.0).filter { square.signedDistanceHorizontal(it) < -1e-9 }.toList()
        caps.size shouldBe 18
        caps.all { abs(abs(it.y) - 1.0) < 1e-9 } shouldBe true
    }

    test("the cap fill skips a concave outline's notch") {
        val ell = PolygonShape(
            points = listOf(
                Vector(0.0, 0.0, 0.0),
                Vector(6.0, 0.0, 0.0),
                Vector(6.0, 0.0, 2.0),
                Vector(2.0, 0.0, 2.0),
                Vector(2.0, 0.0, 6.0),
                Vector(0.0, 0.0, 6.0),
            ),
            halfHeight = 1.0,
        )
        val samples = ell.sampleBoundary(1.0).toList()
        samples.none { it.x > 2.0 + 1e-9 && it.z > 2.0 + 1e-9 } shouldBe true
        samples.any { abs(it.x - 1.0) < 1e-9 && abs(it.z - 1.0) < 1e-9 && abs(it.y - 1.0) < 1e-9 } shouldBe true
    }

    test("a diagonal band costs its own area rather than its bounding box's") {
        // The budget counts samples emitted, and a lattice point outside the outline is rejected
        // for free, so walking the whole bounding box is work no budget bounds. This outline fills
        // a thousandth of its box: testing every point in it is tens of millions of outline tests,
        // and the boundary displays run this per player per render.
        val half = 7071.0
        val band = PolygonShape(
            points = listOf(
                Vector(-half, 0.0, -half),
                Vector(-half + 1.0, 0.0, -half),
                Vector(half, 0.0, half - 1.0),
                Vector(half, 0.0, half),
            ),
            halfHeight = 0.5,
        )
        val elapsed = measureTimeMillis { band.sampleBoundary(0.5).count() }
        (elapsed < 3000) shouldBe true
    }

    test("an ordinary region is not truncated") {
        val samples = SphereShape(10.0).sampleBoundary(0.5).count()
        (samples in 100..MAX_BOUNDARY_SAMPLES) shouldBe true
        (CuboidShape(5.0, 3.0, 5.0).sampleBoundary(0.5).count() < MAX_BOUNDARY_SAMPLES) shouldBe true
    }
})
