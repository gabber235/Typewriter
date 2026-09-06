package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe

class PolygonVertexEditSpec : FunSpec({
    val square = listOf(
        Vector(-5.0, 0.0, -5.0),
        Vector(5.0, 0.0, -5.0),
        Vector(5.0, 0.0, 5.0),
        Vector(-5.0, 0.0, 5.0),
    )
    val edges = square.map { point ->
        Vector(point.x, -2.0, point.z) to Vector(point.x, 2.0, point.z)
    }

    test("a point near a wall inserts between that wall's vertices") {
        insertionIndexFor(square, Vector(0.0, 0.0, -6.0)) shouldBe 1
        insertionIndexFor(square, Vector(6.0, 0.0, 0.0)) shouldBe 2
        insertionIndexFor(square, Vector(0.0, 0.0, 6.0)) shouldBe 3
        insertionIndexFor(square, Vector(-6.0, 0.0, 0.0)) shouldBe 4
    }

    test("a point past a corner lands on the nearer of the two walls") {
        insertionIndexFor(square, Vector(4.0, 0.0, -7.0)) shouldBe 1
    }

    test("degenerate walls do not break the insertion") {
        val doubled = listOf(square[0], square[0], square[1], square[2], square[3])
        insertionIndexFor(doubled, Vector(0.0, 0.0, -6.0)) shouldBe 2
    }

    test("segment distance clamps to the endpoints") {
        pointSegmentDistanceXZ(Vector(7.0, 0.0, -5.0), square[0], square[1]) shouldBe (2.0 plusOrMinus 1e-9)
    }

    test("ray segment distance is exact on a vertical edge") {
        val (distance, along) = raySegmentDistance(
            Vector(0.0, 0.0, 0.0), Vector(0.0, 0.0, 1.0),
            Vector(0.0, -2.0, 5.0), Vector(0.0, 2.0, 5.0),
        )
        distance shouldBe (0.0 plusOrMinus 1e-9)
        along shouldBe (5.0 plusOrMinus 1e-9)
    }

    test("the nearest corner edge along the ray wins") {
        val eye = Vector(-10.0, 0.0, -5.0)
        pickVertexEdge(edges, eye, Vector(1.0, 0.0, 0.0), 32.0) shouldBe 0
    }

    test("an aim just outside the pick radius selects nothing") {
        val eye = Vector(-10.0, 0.0, -5.5)
        pickVertexEdge(edges, eye, Vector(1.0, 0.0, 0.0), 32.0).shouldBeNull()
    }

    test("the selected corner sticks within the keep radius") {
        val eye = Vector(-10.0, 0.0, -5.5)
        pickVertexEdge(edges, eye, Vector(1.0, 0.0, 0.0), 32.0, preferredIndex = 0) shouldBe 0
    }

    test("the stickiness ends past the keep radius") {
        val eye = Vector(-10.0, 0.0, -6.0)
        pickVertexEdge(edges, eye, Vector(1.0, 0.0, 0.0), 32.0, preferredIndex = 0).shouldBeNull()
    }

    test("corners beyond the range are ignored") {
        val eye = Vector(-100.0, 0.0, -5.0)
        pickVertexEdge(edges, eye, Vector(1.0, 0.0, 0.0), 32.0).shouldBeNull()
    }

    test("an eye inside the prism picks the corner it faces") {
        val direction = Vector(1.0, 0.0, -1.0).normalize()
        pickVertexEdge(edges, Vector(0.0, 0.0, 0.0), direction, 32.0) shouldBe 1
    }

    test("a clear hit on another corner overrides a keep-zone selection") {
        val pair = listOf(
            Vector(0.0, -2.0, -5.0) to Vector(0.0, 2.0, -5.0),
            Vector(0.0, -2.0, -4.4) to Vector(0.0, 2.0, -4.4),
        )
        pickVertexEdge(pair, Vector(-10.0, 0.0, -4.4), Vector(1.0, 0.0, 0.0), 32.0, preferredIndex = 0) shouldBe 1
    }

    test("a still-hit previous selection wins over a nearer equal hit") {
        val eye = Vector(-10.0, 0.0, -5.0)
        pickVertexEdge(edges, eye, Vector(1.0, 0.0, 0.0), 32.0, preferredIndex = 1) shouldBe 1
    }

    test("fewer than two points always appends") {
        insertionIndexFor(emptyList(), Vector(0.0, 0.0, 0.0)) shouldBe 0
        insertionIndexFor(listOf(Vector(1.0, 0.0, 1.0)), Vector(0.0, 0.0, 0.0)) shouldBe 1
    }

    test("a retained index survives only while it points into the list") {
        retainedIndex(2, 5) shouldBe 2
        retainedIndex(5, 5).shouldBeNull()
        retainedIndex(null, 5).shouldBeNull()
    }
})
