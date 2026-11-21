package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

class EditHistorySpec : FunSpec({
    test("undo applies the before values and redo the after values") {
        val history = EditHistory()
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 2.0)).shouldBeTrue()

        val undone = history.undoLast().shouldNotBeNull()
        undone.label shouldBe "Origin nudge"
        undone.values shouldBe state(ORIGIN of 1.0)

        val redone = history.redoLast().shouldNotBeNull()
        redone.values shouldBe state(ORIGIN of 2.0)
    }

    test("only changed keys land in the entry") {
        val history = EditHistory()
        history.record(
            EditTool.RESIZE, "+X face",
            state(HALF_X of 2.0, HALF_Y of 3.0),
            state(HALF_X of 4.0, HALF_Y of 3.0),
        ).shouldBeTrue()

        history.undoLast().shouldNotBeNull().values shouldBe state(HALF_X of 2.0)
    }

    test("recording without an actual change stores nothing") {
        val history = EditHistory()
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 1.0)).shouldBeFalse()
        history.undoCount shouldBe 0
    }

    test("empty history returns null on undo and redo") {
        val history = EditHistory()
        history.undoLast().shouldBeNull()
        history.redoLast().shouldBeNull()
        history.undoAll().shouldBeNull()
        history.redoAll().shouldBeNull()
    }

    test("a new change clears the redo entries") {
        val history = EditHistory()
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 2.0))
        history.undoLast()
        history.redoCount shouldBe 1
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 3.0))
        history.redoCount shouldBe 0
    }

    test("bursts with the same tool and label coalesce, keeping oldest before and newest after") {
        val history = EditHistory()
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(ORIGIN of 1.0),
            state(ORIGIN of 2.0),
            coalesceMillis = 1000,
            now = 0
        )
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(ORIGIN of 2.0),
            state(ORIGIN of 3.0),
            coalesceMillis = 1000,
            now = 500
        )
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(ORIGIN of 3.0),
            state(ORIGIN of 4.0),
            coalesceMillis = 1000,
            now = 900
        )

        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state(ORIGIN of 1.0)
        history.redoLast().shouldNotBeNull().values shouldBe state(ORIGIN of 4.0)
    }

    test("a coalesced burst adopts keys that only change later in the burst") {
        val history = EditHistory()
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(X of 1.0, Y of 5.0),
            state(X of 2.0, Y of 5.0),
            coalesceMillis = 1000,
            now = 0
        )
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(X of 2.0, Y of 5.0),
            state(X of 2.0, Y of 6.0),
            coalesceMillis = 1000,
            now = 100
        )

        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state(X of 1.0, Y of 5.0)
    }

    test("an expired window starts a new entry") {
        val history = EditHistory()
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(ORIGIN of 1.0),
            state(ORIGIN of 2.0),
            coalesceMillis = 1000,
            now = 0
        )
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(ORIGIN of 2.0),
            state(ORIGIN of 3.0),
            coalesceMillis = 1000,
            now = 1500
        )
        history.undoCount shouldBe 2
    }

    test("a different label breaks coalescing") {
        val history = EditHistory()
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(ORIGIN of 1.0),
            state(ORIGIN of 2.0),
            coalesceMillis = 1000,
            now = 0
        )
        history.record(
            EditTool.MOVE,
            "Origin nudge",
            state(ORIGIN of 2.0),
            state(ORIGIN of 3.0),
            coalesceMillis = 1000,
            now = 100
        )
        history.undoCount shouldBe 2
    }

    test("the history is bounded and evicts the oldest entries") {
        val history = EditHistory(capacity = 3)
        repeat(5) { index ->
            history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of index.toDouble()), state(ORIGIN of index + 1.0))
        }
        history.undoCount shouldBe 3
    }

    test("undo all merges every entry with the oldest value winning") {
        val history = EditHistory()
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 2.0))
        history.record(EditTool.ROTATE, "Rotation", state(YAW of 0f), state(YAW of 45f))
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 2.0), state(ORIGIN of 3.0))

        val undone = history.undoAll().shouldNotBeNull()
        undone.count shouldBe 3
        undone.values shouldBe state(ORIGIN of 1.0, YAW of 0f)
        history.undoCount shouldBe 0
        history.redoCount shouldBe 3

        history.redoLast().shouldNotBeNull().values shouldBe state(ORIGIN of 2.0)
    }

    test("redo all merges every entry with the newest value winning") {
        val history = EditHistory()
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 2.0))
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 2.0), state(ORIGIN of 3.0))
        history.undoAll()

        val redone = history.redoAll().shouldNotBeNull()
        redone.count shouldBe 2
        redone.values shouldBe state(ORIGIN of 3.0)
        history.undoCount shouldBe 2
    }

    test("tool undo restores the tool's newest entry and keeps a newer disjoint change in place") {
        val history = EditHistory()
        history.record(EditTool.RESIZE, "+X face", state(HALF_X of 2.0), state(HALF_X of 4.0))
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))

        val result = history.undoTool(EditTool.RESIZE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
        result.change.label shouldBe "+X face"
        result.change.values shouldBe state(HALF_X of 2.0)
        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state(YAW of 0f)
    }

    test("tool undo refuses when a newer entry touches the same key and leaves the stack intact") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))
        history.record(EditTool.WAND, "Capture", state(YAW of 45f, ORIGIN of 1.0), state(YAW of 0f, ORIGIN of 2.0))

        val result = history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Entangled>()
        result.blockingTool shouldBe EditTool.WAND
        history.undoCount shouldBe 2
        history.undoLast().shouldNotBeNull().values shouldBe state(YAW of 45f, ORIGIN of 1.0)
    }

    test("tool undo of a missing tool reports nothing left") {
        val history = EditHistory()
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 2.0))
        history.undoTool(EditTool.RESIZE) shouldBe ToolHistoryResult.NothingLeft
    }

    test("tool undo walks a tool's changes one at a time, across an interleaved axis") {
        // An editing session as recorded on a server: move, yaw x3, pitch x3, yaw x4, resize, move.
        val history = EditHistory()
        history.record(EditTool.MOVE, "carry", state(ORIGIN of 0.0), state(ORIGIN of 1.0))
        var yaw = 0f
        for (to in listOf(-15f, -30f, -45f)) {
            history.record(EditTool.ROTATE, "Yaw", state(YAW of yaw), state(YAW of to)); yaw = to
        }
        var pitch = 0f
        for (to in listOf(-15f, -30f, -45f)) {
            history.record(EditTool.ROTATE, "Pitch", state(PITCH of pitch), state(PITCH of to)); pitch = to
        }
        for (to in listOf(-60f, -75f, -90f, -105f)) {
            history.record(EditTool.ROTATE, "Yaw", state(YAW of yaw), state(YAW of to)); yaw = to
        }
        history.record(
            EditTool.RESIZE,
            "+Z face",
            state(HALF_Z of 6.5, SHIFT of 0.0),
            state(HALF_Z of 13.75, SHIFT of 7.25)
        )
        history.record(EditTool.MOVE, "carry", state(ORIGIN of 1.0), state(ORIGIN of 2.0))

        val yawThenPitchThenYaw = listOf(
            state(YAW of -90f), state(YAW of -75f), state(YAW of -60f), state(YAW of -45f),
            state(PITCH of -30f), state(PITCH of -15f), state(PITCH of 0f),
            state(YAW of -30f), state(YAW of -15f), state(YAW of 0f),
        )
        for (expected in yawThenPitchThenYaw) {
            history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe expected
        }
        history.undoTool(EditTool.ROTATE) shouldBe ToolHistoryResult.NothingLeft

        history.undoTool(EditTool.MOVE)
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state(ORIGIN of 1.0)
        history.undoTool(EditTool.MOVE)
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state(ORIGIN of 0.0)
        history.undoTool(EditTool.RESIZE).shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state(
            HALF_Z of 6.5,
            SHIFT of 0.0
        )
    }

    test("tool undo moves the entry to the redo stack and the arrow redoes it") {
        val history = EditHistory()
        history.record(EditTool.RESIZE, "+X face", state(HALF_X of 2.0), state(HALF_X of 3.0))
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))

        history.undoTool(EditTool.RESIZE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
        history.redoCount shouldBe 1
        history.redoLast().shouldNotBeNull().values shouldBe state(HALF_X of 3.0)
        history.undoCount shouldBe 2
    }

    test("tool redo brings back the tool's last undone change") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))
        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()

        val result = history.redoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
        result.change.values shouldBe state(YAW of 45f)
        history.undoCount shouldBe 1
        history.redoCount shouldBe 0
    }

    test("tool redo reaches past another tool's undone change when the keys are disjoint") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 2.0))
        history.undoTool(EditTool.ROTATE)
        history.undoTool(EditTool.MOVE)

        history.redoTool(EditTool.ROTATE)
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state(YAW of 45f)
        history.redoTool(EditTool.MOVE)
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state(ORIGIN of 2.0)
        history.redoCount shouldBe 0
    }

    test("tool redo refuses when an undone change in front shares a key") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))
        history.record(EditTool.WAND, "Capture", state(YAW of 45f), state(YAW of 0f))
        history.undoLast()
        history.undoLast()

        val result = history.redoTool(EditTool.WAND).shouldBeInstanceOf<ToolHistoryResult.Entangled>()
        result.blockingTool shouldBe EditTool.ROTATE
        history.redoCount shouldBe 2
    }

    test("tool redo reports nothing left when the tool has no undone changes") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))
        history.undoTool(EditTool.ROTATE)
        history.redoTool(EditTool.MOVE) shouldBe ToolHistoryResult.NothingLeft
    }

    test("a new change clears the tool redo entries too") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))
        history.undoTool(EditTool.ROTATE)
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 2.0))
        history.redoTool(EditTool.ROTATE) shouldBe ToolHistoryResult.NothingLeft
    }

    test("mixed tool and arrow traffic stays consistent when entries move out of order") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 45f))
        history.record(EditTool.MOVE, "Origin nudge", state(ORIGIN of 1.0), state(ORIGIN of 2.0))

        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
        history.undoLast().shouldNotBeNull().values shouldBe state(ORIGIN of 1.0)

        history.redoLast().shouldNotBeNull().values shouldBe state(ORIGIN of 2.0)
        history.redoLast().shouldNotBeNull().values shouldBe state(YAW of 45f)
        history.undoCount shouldBe 2
        history.redoCount shouldBe 0

        history.undoLast().shouldNotBeNull().values shouldBe state(YAW of 0f)
        history.undoLast().shouldNotBeNull().values shouldBe state(ORIGIN of 1.0)
    }

    test("a click entry never absorbs a following scroll") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 15f), coalesceMillis = 0, now = 0)
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 15f), state(YAW of 20f), coalesceMillis = 1200, now = 300)

        history.undoCount shouldBe 2
        history.undoTool(EditTool.ROTATE)
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state(YAW of 15f)
    }

    test("a scroll burst never absorbs a following click") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 5f), coalesceMillis = 1200, now = 0)
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 5f), state(YAW of 20f), coalesceMillis = 0, now = 300)
        history.undoCount shouldBe 2
    }

    test("a merge drops keys that returned to their start value but keeps the live ones") {
        val history = EditHistory()
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(X of 1.0, Y of 5.0),
            state(X of 2.0, Y of 6.0),
            coalesceMillis = 1200,
            now = 0
        )
        history.record(
            EditTool.MOVE,
            "Origin slide",
            state(X of 2.0, Y of 6.0),
            state(X of 1.0, Y of 6.0),
            coalesceMillis = 1200,
            now = 300
        )

        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state(Y of 5.0)
    }

    test("a coalescing record merges into an entry a tool redo just brought back") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 0f), state(YAW of 5f), coalesceMillis = 1200, now = 0)
        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
        history.redoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
        history.record(EditTool.ROTATE, "Yaw", state(YAW of 5f), state(YAW of 10f), coalesceMillis = 1200, now = 500)

        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state(YAW of 0f)
    }

    test("a point carry entry restores the pre-grab vertex list via tool undo") {
        val history = EditHistory()
        val before = state(POINTS of listOf(Vector(1.0, 0.0, 1.0), Vector(2.0, 0.0, 2.0)))
        val after = state(POINTS of listOf(Vector(1.0, 0.0, 1.0), Vector(5.0, 0.0, 5.0)))
        history.record(EditTool.WAND, "Point 2 carry", before, after)

        val result = history.undoTool(EditTool.WAND).shouldBeInstanceOf<ToolHistoryResult.Restored>()
        result.change.values shouldBe before
    }

    test("wand point edits entangle with a newer resize wall drag") {
        val history = EditHistory()
        history.record(
            EditTool.WAND, "Point 1 nudge",
            state(POINTS of listOf(Vector(1.0, 0.0, 1.0))),
            state(POINTS of listOf(Vector(1.5, 0.0, 1.0))),
        )
        history.record(
            EditTool.RESIZE, "wall 1",
            state(POINTS of listOf(Vector(1.5, 0.0, 1.0))),
            state(POINTS of listOf(Vector(2.0, 0.0, 1.0))),
        )

        val result = history.undoTool(EditTool.WAND).shouldBeInstanceOf<ToolHistoryResult.Entangled>()
        result.blockingTool shouldBe EditTool.RESIZE
    }

    test("point slides coalesce and an out-and-back slide pops off the stack") {
        val history = EditHistory()
        val start = state(POINTS of listOf(Vector(1.0, 0.0, 1.0)))
        val out = state(POINTS of listOf(Vector(1.25, 0.0, 1.0)))
        history.record(EditTool.WAND, "Point 1 slide", start, out, coalesceMillis = 1200, now = 1000)
        history.record(EditTool.WAND, "Point 1 slide", out, start, coalesceMillis = 1200, now = 1500)

        history.undoCount shouldBe 0
    }
})
