package com.typewritermc.region.data

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.region.content.EditField
import com.typewritermc.region.content.EditHistory
import com.typewritermc.region.content.EditTool
import com.typewritermc.region.content.EditorState
import com.typewritermc.region.shape.LocalBounds
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe

private const val TOLERANCE = 1e-9

private infix fun Vector.shouldBeCloseTo(expected: Vector) {
    x shouldBe (expected.x plusOrMinus TOLERANCE)
    y shouldBe (expected.y plusOrMinus TOLERANCE)
    z shouldBe (expected.z plusOrMinus TOLERANCE)
}

class ResolvedTransformSpec : FunSpec({
    val world = World("test-world")

    test("toLocal and toWorld are inverse under yaw and pitch") {
        val transform = ResolvedTransform(world, Vector(10.0, 20.0, 30.0), 37f, -20f)
        val points = listOf(
            Vector(0.0, 0.0, 0.0),
            Vector(1.0, 2.0, 3.0),
            Vector(-4.5, 0.25, 12.0),
        )
        for (point in points) {
            transform.toWorld(transform.toLocal(point)) shouldBeCloseTo point
            transform.toLocal(transform.toWorld(point)) shouldBeCloseTo point
        }
    }

    test("fromOriginAndOffset rotates only the horizontal offset components") {
        val origin = Position(world, 10.0, 20.0, 30.0, 0f, 0f)
        val transform = ResolvedTransform.fromOriginAndOffset(origin, Vector(1.0, 2.0, 3.0), 90f, 0f)
        transform.worldOrigin shouldBeCloseTo Vector(7.0, 22.0, 31.0)
    }

    test("rotateLocalToWorld follows Minecraft's yaw and pitch convention") {
        val plusZ = Vector(0.0, 0.0, 1.0)
        ResolvedTransform(world, Vector.ZERO, 90f, 0f).rotateLocalToWorld(plusZ) shouldBeCloseTo
                Vector(-1.0, 0.0, 0.0)
        ResolvedTransform(world, Vector.ZERO, 0f, -90f).rotateLocalToWorld(plusZ) shouldBeCloseTo
                Vector(0.0, 1.0, 0.0)
    }

    test("resolve adds the origin's facing only when the region rotates with its origin") {
        val origin = Position(world, 10.0, 20.0, 30.0, 90f, -10f)
        val offset = Vector(3.0, 1.0, 0.0)

        val following = ResolvedTransform.resolve(origin, offset, 15f, 5f, 2f, rotateWithOrigin = true)
        following.yawDegrees shouldBe 105f
        following.pitchDegrees shouldBe -5f
        following.rollDegrees shouldBe 2f
        following.worldOrigin shouldBeCloseTo
                ResolvedTransform.fromOriginAndOffset(origin, offset, 105f, -5f, 2f).worldOrigin

        val fixed = ResolvedTransform.resolve(origin, offset, 15f, 5f, 2f, rotateWithOrigin = false)
        fixed.yawDegrees shouldBe 15f
        fixed.pitchDegrees shouldBe 5f
    }

    test("the editor's resolution of a constant origin facing 90 matches the tracker's") {
        val origin = Position(world, 0.0, 64.0, 0.0, 90f, 0f)
        val offset = Vector(4.0, 0.0, 0.0)
        val trackerYaw = 0f + origin.yaw
        val trackerPitch = 0f + origin.pitch
        val tracker = ResolvedTransform.fromOriginAndOffset(origin, offset, trackerYaw, trackerPitch, 0f)

        val editor = ResolvedTransform.resolve(origin, offset, 0f, 0f, 0f, rotateWithOrigin = true)

        editor shouldBe tracker
        editor.worldOrigin shouldBeCloseTo Vector(0.0, 64.0, 4.0)
        editor.toWorld(Vector(0.0, 0.0, 1.0)) shouldBeCloseTo tracker.toWorld(Vector(0.0, 0.0, 1.0))
    }

    test("originForAnchor places the resolved anchor exactly on the target despite a rotated offset") {
        val offset = Vector(2.0, 1.5, -3.0)
        val anchor = Vector(100.5, 70.0, -40.25)
        for (yaw in listOf(0f, 37f, 90f, -135f)) {
            for (rotate in listOf(false, true)) {
                val origin = ResolvedTransform.originForAnchor(world, anchor, offset, yaw, rotate, 25f, 10f)

                origin.yaw shouldBe 25f
                origin.pitch shouldBe 10f
                ResolvedTransform.resolve(origin, offset, yaw, 0f, 0f, rotate).worldOrigin shouldBeCloseTo anchor
            }
        }
    }

    test("a capture with a nonzero offset and rotation puts the region where the marks are") {
        val offset = Vector(0.0, 0.0, 5.0)
        val markedCenter = Vector(12.5, 64.5, 8.5)
        val capturedYaw = 90f

        val origin = ResolvedTransform.originForAnchor(world, markedCenter, offset, capturedYaw, rotateWithOrigin = false)

        origin.yaw shouldBe 0f
        origin.pitch shouldBe 0f
        ResolvedTransform.resolve(origin, offset, capturedYaw, 0f, 0f, false).worldOrigin shouldBeCloseTo markedCenter
    }

    test("a carry with offset and rotation undoes back to the origin it started from") {
        val originField = EditField<Position?>("work.origin", null)
        val history = EditHistory()
        val offset = Vector(3.0, 0.0, 1.0)
        val yaw = 45f
        val start = Position(world, 0.0, 64.0, 0.0, 0f, 0f)
        val crosshair = Vector(20.0, 65.0, -7.5)

        val carried = ResolvedTransform.originForAnchor(world, crosshair, offset, yaw, rotateWithOrigin = false)
        ResolvedTransform.resolve(carried, offset, yaw, 0f, 0f, false).worldOrigin shouldBeCloseTo crosshair

        history.record(
            EditTool.MOVE,
            "Region carry",
            EditorState.of(originField of start),
            EditorState.of(originField of carried),
        )
        history.undoLast()?.values?.get(originField) shouldBe start
        history.redoLast()?.values?.get(originField) shouldBe carried
    }

    test("rotated local bounds swap the horizontal extents under a quarter turn") {
        val rotated = LocalBounds(-1.0, -2.0, -3.0, 1.0, 2.0, 3.0).rotated(90f, 0f)
        rotated.minX shouldBe (-3.0 plusOrMinus TOLERANCE)
        rotated.maxX shouldBe (3.0 plusOrMinus TOLERANCE)
        rotated.minY shouldBe (-2.0 plusOrMinus TOLERANCE)
        rotated.maxY shouldBe (2.0 plusOrMinus TOLERANCE)
        rotated.minZ shouldBe (-1.0 plusOrMinus TOLERANCE)
        rotated.maxZ shouldBe (1.0 plusOrMinus TOLERANCE)
    }
})
