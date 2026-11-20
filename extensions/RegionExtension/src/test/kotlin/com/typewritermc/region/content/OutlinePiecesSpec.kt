package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.SphereShape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.doubles.shouldBeLessThanOrEqual
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.matchers.ints.shouldBeLessThanOrEqual
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.joml.Quaternionf
import org.joml.Vector3f

private infix fun Vector.shouldBeCloseTo(expected: Vector) {
    x shouldBe (expected.x plusOrMinus 1e-6)
    y shouldBe (expected.y plusOrMinus 1e-6)
    z shouldBe (expected.z plusOrMinus 1e-6)
}

private fun rotateExpected(rotation: Quaternionf, vector: Vector): Vector {
    val rotated = Vector3f(vector.x.toFloat(), vector.y.toFloat(), vector.z.toFloat()).rotate(rotation)
    return Vector(rotated.x.toDouble(), rotated.y.toDouble(), rotated.z.toDouble())
}

class OutlinePiecesSpec : FunSpec({
    val small = CuboidShape(3.0, 3.0, 3.0)
    val huge = CuboidShape(100.0, 20.0, 100.0)

    test("no piece is longer than the piece length") {
        val pieces = buildOutlinePieces(huge, 0f, 0f, 0f, 1f)
        pieces.shouldNotBeEmpty()
        for (piece in pieces) {
            (piece.to - piece.from).length shouldBeLessThanOrEqual PIECE_LENGTH + 1e-6
        }
    }

    test("the pieces of an edge reconstruct it end to end") {
        val pieces = buildOutlinePieces(CuboidShape(10.0, 1.0, 1.0), 0f, 0f, 0f, 1f)
        // The bottom rectangle's first edge runs from (-10, -1, -1) to (10, -1, -1).
        val edge = pieces.filter { piece ->
            val start = piece.anchorOffset
            start.y == -1.0 && start.z == -1.0 && (piece.to - piece.from).x > 0.0
        }.sortedBy { it.anchorOffset.x }
        edge.size shouldBeGreaterThan 1
        edge.first().anchorOffset.x shouldBe (-10.0 plusOrMinus 1e-9)
        for (index in 0 until edge.size - 1) {
            val end = edge[index].anchorOffset + (edge[index].to - edge[index].from)
            end.x shouldBe (edge[index + 1].anchorOffset.x plusOrMinus 1e-9)
        }
        val last = edge.last()
        (last.anchorOffset + (last.to - last.from)).x shouldBe (10.0 plusOrMinus 1e-9)
    }

    test("the scale draws bigger geometry without moving the anchors") {
        val plain = buildOutlinePieces(small, 0f, 0f, 0f, 1f)
        val pulsed = buildOutlinePieces(small, 0f, 0f, 0f, 1.5f)
        pulsed.size shouldBe plain.size
        for (index in plain.indices) {
            pulsed[index].anchorOffset shouldBe plain[index].anchorOffset
            pulsed[index].midOffset shouldBe plain[index].midOffset
        }
        pulsed.first().from shouldNotBe plain.first().from
    }

    test("a small outline renders whole, however far away the player stands") {
        val pieces = buildOutlinePieces(small, 0f, 0f, 0f, 1f)
        val visible = visibleOutlinePieces(
            pieces,
            anchor = Vector.ZERO,
            viewer = Vector(500.0, 0.0, 0.0),
            renderDistance = 64.0,
            budget = MAX_LINE_DISPLAYS,
        )
        visible.size shouldBe pieces.size
    }

    test("a huge outline renders only the border near the player, nearest first") {
        val pieces = buildOutlinePieces(huge, 0f, 0f, 0f, 1f)
        pieces.size shouldBeGreaterThan MAX_LINE_DISPLAYS

        val viewer = Vector(100.0, 0.0, 0.0)
        val visible = visibleOutlinePieces(pieces, Vector.ZERO, viewer, 64.0, MAX_LINE_DISPLAYS)

        visible.size shouldBeLessThanOrEqual MAX_LINE_DISPLAYS
        visible.shouldNotBeEmpty()
        for ((_, piece) in visible) {
            (piece.midOffset - viewer).length shouldBeLessThanOrEqual 64.0
        }
        val distances = visible.map { (_, piece) -> (piece.midOffset - viewer).length }
        distances shouldBe distances.sorted()
    }

    test("indices are stable, so a piece keeps its display while the player walks") {
        val pieces = buildOutlinePieces(huge, 0f, 0f, 0f, 1f)
        val here = visibleOutlinePieces(pieces, Vector.ZERO, Vector(100.0, 0.0, 0.0), 64.0, MAX_LINE_DISPLAYS)
        val there = visibleOutlinePieces(pieces, Vector.ZERO, Vector(100.0, 0.0, 2.0), 64.0, MAX_LINE_DISPLAYS)
        val shared = here.map { it.index }.intersect(there.map { it.index }.toSet())
        shared.shouldNotBeEmpty()
        for (index in shared) {
            here.first { it.index == index }.value shouldBe there.first { it.index == index }.value
        }
    }

    test("a player far from every part of a huge border sees nothing") {
        val pieces = buildOutlinePieces(huge, 0f, 0f, 0f, 1f)
        val visible = visibleOutlinePieces(pieces, Vector.ZERO, Vector(0.0, 0.0, 0.0), 64.0, MAX_LINE_DISPLAYS)
        visible.size shouldBe 0
    }

    test("a rotated region's line stays local while its anchor rotates into the world") {
        val shape = CuboidShape(5.0, 5.0, 5.0)
        val yaw = 90f
        val rotation = RegionOutline.regionRotation(yaw, 0f)
        val pieces = buildOutlinePieces(shape, yaw, 0f, 0f, 1f)

        // The bottom and top rectangles' first edge each run along local +X, from
        // (-5, y, -5) to (5, y, -5). A piece's line has to point along local +X, unrotated: a
        // segment rotated before it is stored would point along world +/-Z here instead.
        val localPlusX = pieces.filter { piece ->
            val direction = piece.to - piece.from
            direction.x > 0.0 && direction.y == 0.0 && direction.z == 0.0
        }
        val bottomEdge = localPlusX.filter { it.anchorOffset.y < 0.0 }
        val topEdge = localPlusX.filter { it.anchorOffset.y > 0.0 }
        bottomEdge.size shouldBeGreaterThan 1
        topEdge.size shouldBeGreaterThan 1

        for ((y, edge) in listOf(-5.0 to bottomEdge, 5.0 to topEdge)) {
            val start = rotateExpected(rotation, Vector(-5.0, y, -5.0))
            val end = rotateExpected(rotation, Vector(5.0, y, -5.0))
            edge.first().anchorOffset shouldBeCloseTo start

            var cursor = edge.first().anchorOffset
            for (piece in edge) {
                cursor shouldBeCloseTo piece.anchorOffset
                cursor += rotateExpected(rotation, piece.to - piece.from)
            }
            cursor shouldBeCloseTo end
        }
    }

    test("circle segments scale with the shape so a big sphere stays round") {
        adaptiveCircleSegments(SphereShape(5.0)) shouldBe OUTLINE_CIRCLE_SEGMENTS
        adaptiveCircleSegments(SphereShape(50.0)) shouldBeGreaterThan OUTLINE_CIRCLE_SEGMENTS
        adaptiveCircleSegments(SphereShape(50.0)) shouldBeLessThanOrEqual MAX_CIRCLE_SEGMENTS
        adaptiveCircleSegments(SphereShape(1000.0)) shouldBe MAX_CIRCLE_SEGMENTS
    }

    test("adaptive segments keep a big sphere's chords near the piece length") {
        val radius = 50.0
        val segments = adaptiveCircleSegments(SphereShape(radius))
        val chord = 2.0 * radius * kotlin.math.sin(Math.PI / segments)
        chord shouldBeLessThanOrEqual PIECE_LENGTH * 1.1
    }

    test("a pulse's scale never changes which pieces are visible") {
        val plain = buildOutlinePieces(huge, 0f, 0f, 0f, 1f)
        val pulsed = buildOutlinePieces(huge, 0f, 0f, 0f, 1.5f)
        val viewer = Vector(100.0, 0.0, 0.0)

        val plainVisible = visibleOutlinePieces(plain, Vector.ZERO, viewer, 64.0, MAX_LINE_DISPLAYS)
        val pulsedVisible = visibleOutlinePieces(pulsed, Vector.ZERO, viewer, 64.0, MAX_LINE_DISPLAYS)

        pulsedVisible.map { it.index } shouldBe plainVisible.map { it.index }
    }
})
