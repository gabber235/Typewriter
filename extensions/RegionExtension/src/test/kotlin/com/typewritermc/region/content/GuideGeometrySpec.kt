package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.region.shape.LocalBounds
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.doubles.shouldBeGreaterThan
import io.kotest.matchers.doubles.shouldBeLessThan
import io.kotest.matchers.doubles.shouldBeLessThanOrEqual
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.matchers.ints.shouldBeLessThan
import io.kotest.matchers.shouldBe
import kotlin.math.abs
import kotlin.math.sqrt

class GuideGeometrySpec : FunSpec({
    fun bounds(half: Double) = LocalBounds(-half, -half, -half, half, half, half)

    val east = Vector(1.0, 0.0, 0.0)
    val up = Vector(0.0, 1.0, 0.0)
    val south = Vector(0.0, 0.0, 1.0)

    test("a small region gets a small guide instead of a ten block arrow") {
        moveAxisLength(bounds(1.0), east) shouldBe (2.0 plusOrMinus 1e-9)
    }

    test("the guide grows with the region") {
        moveAxisLength(bounds(12.0), east) shouldBe (13.0 plusOrMinus 1e-9)
    }

    test("the guide stops growing at the cap") {
        moveAxisLength(bounds(200.0), east) shouldBe 24.0
    }

    test("the axis length follows the axis the move direction points down") {
        val flat = LocalBounds(-30.0, -2.0, -30.0, 30.0, 2.0, 30.0)
        moveAxisLength(flat, up) shouldBe (3.0 plusOrMinus 1e-9)
        moveAxisLength(flat, east) shouldBe 24.0
    }

    test("a long axis splits into pieces no longer than the guide piece length") {
        val segments = splitGuideSegment(Vector.ZERO, Vector(24.0, 0.0, 0.0))
        segments.size shouldBe 6
        for ((from, to) in segments) {
            (to - from).length shouldBeLessThanOrEqual 4.0 + 1e-9
        }
        var cursor = Vector.ZERO
        for ((from, to) in segments) {
            from shouldBe cursor
            cursor = to
        }
        cursor.x shouldBe (24.0 plusOrMinus 1e-9)
    }

    test("a short axis stays a single piece") {
        splitGuideSegment(Vector.ZERO, Vector(3.0, 0.0, 0.0)).size shouldBe 1
    }

    test("the move guide is a chained axis plus two prongs meeting at the tip") {
        val boundsFour = bounds(4.0)
        val length = moveAxisLength(boundsFour, east)
        val segments = moveGuideSegments(boundsFour, east, south)
        val axisPieces = segments.dropLast(2)
        val prongs = segments.takeLast(2)

        axisPieces.shouldNotBeEmpty()
        axisPieces.first().first shouldBe Vector.ZERO
        val tip = axisPieces.last().second
        tip.x shouldBe (length plusOrMinus 1e-9)

        for ((from, to) in prongs) {
            from shouldBe tip
            // The prongs point back down the axis and away from it.
            (to.x - tip.x) shouldBeLessThan 0.0
            val offAxis = abs(to.y - tip.y) + abs(to.z - tip.z)
            offAxis shouldBeGreaterThan 0.0
        }
    }

    test("the arrowhead is flat and faces the viewer") {
        // Viewer looks along +Z at an east pointing arrow: the prongs must spread along Y,
        // so the arrow plane (X, Y) stands perpendicular to the view.
        val side = prongBasis(east, south)
        abs(side.dot(east)) shouldBeLessThan 1e-9
        abs(side.dot(south)) shouldBeLessThan 1e-9
        side.length shouldBe (1.0 plusOrMinus 1e-9)

        val segments = moveGuideSegments(bounds(4.0), east, south)
        val (first, second) = segments.takeLast(2)
        // Two prongs on opposite sides of the axis, mirrored through it.
        (first.second.y + second.second.y) shouldBe (2 * first.first.y plusOrMinus 1e-9)
        abs(first.second.z - first.first.z) shouldBeLessThan 1e-9
    }

    test("a view along the axis still finds a perpendicular prong basis") {
        val side = prongBasis(up, up)
        abs(side.dot(up)) shouldBeLessThan 1e-9
        side.length shouldBe (1.0 plusOrMinus 1e-9)
    }

    test("the prong basis snaps, so a step sideways does not re-render the guide") {
        val a = prongBasis(east, south)
        val b = prongBasis(east, Vector(0.02, 0.0, 1.0).normalize())
        a shouldBe b
    }

    test("the rotation ring clears a small region and caps at a compact gizmo size") {
        rotationRingRadius(bounds(1.0), pitchPlane = false) shouldBe (1.5 plusOrMinus 1e-9)
        rotationRingRadius(bounds(5.0), pitchPlane = false) shouldBe (5.5 plusOrMinus 1e-9)
        rotationRingRadius(bounds(10.0), pitchPlane = false) shouldBe 8.0
        rotationRingRadius(bounds(100.0), pitchPlane = false) shouldBe 8.0
    }

    test("the pitch ring accounts for the vertical extent") {
        val tall = LocalBounds(-2.0, -20.0, -2.0, 2.0, 20.0, 2.0)
        rotationRingRadius(tall, pitchPlane = false) shouldBe (2.5 plusOrMinus 1e-9)
        rotationRingRadius(tall, pitchPlane = true) shouldBe 8.0
    }

    test("a tiny region still gets a readable ring") {
        rotationRingRadius(bounds(0.5), pitchPlane = false) shouldBe (1.25 plusOrMinus 1e-9)
    }

    test("asymmetric bounds size by half extents, not the farthest corner") {
        val lopsided = LocalBounds(0.0, -1.0, -2.0, 10.0, 1.0, 4.0)
        moveAxisLength(lopsided, east) shouldBe (6.0 plusOrMinus 1e-9)
        rotationRingRadius(lopsided, pitchPlane = false) shouldBe (5.5 plusOrMinus 1e-9)
        boundsCenter(lopsided) shouldBe Vector(5.0, 0.0, 1.0)
    }

    test("the push axis runs through the point with the arrowhead on the push end only") {
        val segments = pushAxisSegments(east, south)
        segments.first().first shouldBe Vector(-1.5, 0.0, 0.0)
        segments.first().second shouldBe Vector.ZERO
        val prongs = segments.takeLast(2)
        for ((from, to) in prongs) {
            from.x shouldBe (1.5 plusOrMinus 1e-9)
            (to.x - from.x) shouldBeLessThan 0.0
        }
    }

    test("the far ring hugs a region the player stands outside of") {
        val flat = LocalBounds(-3.0, -2.0, -4.0, 3.0, 2.0, 4.0)
        farRingRadius(flat, 30.0, pitchPlane = false) shouldBe (5.5 plusOrMinus 1e-9)
    }

    test("the far ring still passes through a player inside a huge region") {
        farRingRadius(bounds(100.0), 30.0, pitchPlane = false) shouldBe (30.0 plusOrMinus 1e-9)
    }

    test("the far ring never shrinks below the near gizmo radius") {
        farRingRadius(bounds(1.0), 0.0, pitchPlane = false) shouldBe (1.5 plusOrMinus 1e-9)
    }

    test("the pitch far ring measures its reach in the vertical plane") {
        val slab = LocalBounds(-1.0, -3.0, -4.0, 1.0, 3.0, 4.0)
        farRingRadius(slab, 30.0, pitchPlane = true) shouldBe (5.5 plusOrMinus 1e-9)
    }

    test("the tilt facing quantizes to the region frame, picking pitch or roll") {
        quantizedTiltFacing(0.0, -10.0, 0f) shouldBe Vector(0.0, 0.0, -1.0)
        quantizedTiltFacing(-10.0, 0.0, 0f) shouldBe Vector(-1.0, 0.0, 0.0)
        quantizedTiltFacing(3.0, 10.0, 0f) shouldBe Vector(0.0, 0.0, 1.0)
    }

    test("the quantized facing follows the region's yaw") {
        val facing = quantizedTiltFacing(0.0, 10.0, 30f)
        facing.x shouldBe (-0.5 plusOrMinus 1e-9)
        facing.z shouldBe (sqrt(3.0) / 2 plusOrMinus 1e-9)
    }

    test("a tilt step from the front or back is a clean pitch tipping the top away") {
        steppedTilt(0f, 0f, Vector(0.0, 0.0, 1.0), 0f, 15f) shouldBe (15f to 0f)
        steppedTilt(0f, 0f, Vector(0.0, 0.0, -1.0), 0f, 15f) shouldBe (-15f to 0f)
    }

    test("a tilt step from a flank is a clean roll tipping the top away") {
        steppedTilt(0f, 0f, Vector(1.0, 0.0, 0.0), 0f, 15f) shouldBe (0f to -15f)
        steppedTilt(0f, 0f, Vector(-1.0, 0.0, 0.0), 0f, 15f) shouldBe (0f to 15f)
    }

    test("tilting a pitched region from the flank leaves yaw and pitch alone") {
        steppedTilt(45f, 0f, Vector(-1.0, 0.0, 0.0), 0f, 15f) shouldBe (45f to 15f)
    }

    test("the tilt step follows the region's yaw frame") {
        val facing = quantizedTiltFacing(0.0, 10.0, 90f)
        steppedTilt(0f, 0f, facing, 90f, 15f) shouldBe (0f to -15f)
    }

    test("a tilt step wraps past a half turn") {
        steppedTilt(175f, 0f, Vector(0.0, 0.0, 1.0), 0f, 15f) shouldBe (-170f to 0f)
    }

    test("ring segments grow with the radius and clamp at both ends") {
        ringSegmentCount(1.5) shouldBe 16
        ringSegmentCount(10.0) shouldBeGreaterThan 16
        ringSegmentCount(10.0) shouldBeLessThan ringSegmentCount(20.0)
        ringSegmentCount(200.0) shouldBe 96
    }

    test("a ring chains around and keeps every point on the circle") {
        val offset = Vector(0.0, 3.0, 0.0)
        val segments = ringSegments(10.0, offset, east, south)
        segments.size shouldBe ringSegmentCount(10.0)
        for ((from, to) in segments) {
            (from - offset).length shouldBe (10.0 plusOrMinus 1e-9)
            (to - offset).length shouldBe (10.0 plusOrMinus 1e-9)
        }
        for (index in segments.indices) {
            segments[index].second shouldBe segments[(index + 1) % segments.size].first
        }
    }

    test("culling keeps only the arc near the viewer") {
        val segments = ringSegments(50.0, Vector.ZERO, east, south)
        val viewer = Vector(0.0, 0.0, 50.0)
        val visible = cullSegmentsNear(segments, viewer, range = 20.0)
        visible.shouldNotBeEmpty()
        visible.size shouldBeLessThan segments.size
        for ((from, to) in visible) {
            ((from + to) * 0.5 - viewer).length shouldBeLessThanOrEqual 20.0 + 1e-9
        }
    }

    test("cross gives a vector perpendicular to both inputs") {
        val cross = east.cross(up)
        cross.dot(east) shouldBe (0.0 plusOrMinus 1e-9)
        cross.dot(up) shouldBe (0.0 plusOrMinus 1e-9)
        cross.length shouldBe (1.0 plusOrMinus 1e-9)
    }

    val hoverWorld = World("hover-world")
    fun block(x: Int, y: Int, z: Int) = CapturedBlock(hoverWorld, x, y, z)

    test("aiming at a marked block picks it regardless of anything in between") {
        val point = block(10, 64, 0)
        val eye = Vector(0.5, 64.5, 0.5)
        val aim = Vector(1.0, 0.0, 0.0)
        pickHoveredBlock(listOf(point), hoverWorld.identifier, eye, aim, 32.0) shouldBe point
    }

    test("the nearest marked block along the ray wins") {
        val near = block(5, 64, 0)
        val far = block(12, 64, 0)
        val eye = Vector(0.5, 64.5, 0.5)
        val aim = Vector(1.0, 0.0, 0.0)
        pickHoveredBlock(listOf(far, near), hoverWorld.identifier, eye, aim, 32.0) shouldBe near
    }

    test("a ray passing beside the block picks nothing") {
        val point = block(10, 64, 3)
        val eye = Vector(0.5, 64.5, 0.5)
        val aim = Vector(1.0, 0.0, 0.0)
        pickHoveredBlock(listOf(point), hoverWorld.identifier, eye, aim, 32.0) shouldBe null
    }

    test("flying inside a marked block hovers it") {
        val point = block(10, 64, 0)
        val eye = Vector(10.5, 64.5, 0.5)
        val aim = Vector(0.0, -1.0, 0.0)
        pickHoveredBlock(listOf(point), hoverWorld.identifier, eye, aim, 32.0) shouldBe point
    }

    test("marked blocks beyond the range or in another world are ignored") {
        val far = block(50, 64, 0)
        val elsewhere = CapturedBlock(World("other-world"), 10, 64, 0)
        val eye = Vector(0.5, 64.5, 0.5)
        val aim = Vector(1.0, 0.0, 0.0)
        pickHoveredBlock(listOf(far, elsewhere), hoverWorld.identifier, eye, aim, 32.0) shouldBe null
    }
})
