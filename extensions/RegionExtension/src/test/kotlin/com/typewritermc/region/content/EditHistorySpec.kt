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
    fun state(vararg pairs: Pair<String, Any?>): Map<String, Any?> = mapOf(*pairs)

    test("undo applies the before values and redo the after values") {
        val history = EditHistory()
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 2.0)).shouldBeTrue()

        val undone = history.undoLast().shouldNotBeNull()
        undone.label shouldBe "Origin nudge"
        undone.values shouldBe state("origin" to 1.0)

        val redone = history.redoLast().shouldNotBeNull()
        redone.values shouldBe state("origin" to 2.0)
    }

    test("only changed keys land in the entry") {
        val history = EditHistory()
        history.record(
            "resize", "+X face",
            state("halfX" to 2.0, "halfY" to 3.0),
            state("halfX" to 4.0, "halfY" to 3.0),
        ).shouldBeTrue()

        history.undoLast().shouldNotBeNull().values shouldBe state("halfX" to 2.0)
    }

    test("recording without an actual change stores nothing") {
        val history = EditHistory()
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 1.0)).shouldBeFalse()
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
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 2.0))
        history.undoLast()
        history.redoCount shouldBe 1
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 3.0))
        history.redoCount shouldBe 0
    }

    test("bursts with the same tool and label coalesce, keeping oldest before and newest after") {
        val history = EditHistory()
        history.record(
            "move",
            "Origin slide",
            state("origin" to 1.0),
            state("origin" to 2.0),
            coalesceMillis = 1000,
            now = 0
        )
        history.record(
            "move",
            "Origin slide",
            state("origin" to 2.0),
            state("origin" to 3.0),
            coalesceMillis = 1000,
            now = 500
        )
        history.record(
            "move",
            "Origin slide",
            state("origin" to 3.0),
            state("origin" to 4.0),
            coalesceMillis = 1000,
            now = 900
        )

        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state("origin" to 1.0)
        history.redoLast().shouldNotBeNull().values shouldBe state("origin" to 4.0)
    }

    test("a coalesced burst adopts keys that only change later in the burst") {
        val history = EditHistory()
        history.record(
            "move",
            "Origin slide",
            state("x" to 1.0, "y" to 5.0),
            state("x" to 2.0, "y" to 5.0),
            coalesceMillis = 1000,
            now = 0
        )
        history.record(
            "move",
            "Origin slide",
            state("x" to 2.0, "y" to 5.0),
            state("x" to 2.0, "y" to 6.0),
            coalesceMillis = 1000,
            now = 100
        )

        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state("x" to 1.0, "y" to 5.0)
    }

    test("an expired window starts a new entry") {
        val history = EditHistory()
        history.record(
            "move",
            "Origin slide",
            state("origin" to 1.0),
            state("origin" to 2.0),
            coalesceMillis = 1000,
            now = 0
        )
        history.record(
            "move",
            "Origin slide",
            state("origin" to 2.0),
            state("origin" to 3.0),
            coalesceMillis = 1000,
            now = 1500
        )
        history.undoCount shouldBe 2
    }

    test("a different label breaks coalescing") {
        val history = EditHistory()
        history.record(
            "move",
            "Origin slide",
            state("origin" to 1.0),
            state("origin" to 2.0),
            coalesceMillis = 1000,
            now = 0
        )
        history.record(
            "move",
            "Origin nudge",
            state("origin" to 2.0),
            state("origin" to 3.0),
            coalesceMillis = 1000,
            now = 100
        )
        history.undoCount shouldBe 2
    }

    test("the history is bounded and evicts the oldest entries") {
        val history = EditHistory(capacity = 3)
        repeat(5) { index ->
            history.record("move", "Origin nudge", state("origin" to index), state("origin" to index + 1))
        }
        history.undoCount shouldBe 3
    }

    test("undo all merges every entry with the oldest value winning") {
        val history = EditHistory()
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 2.0))
        history.record("rotate", "Rotation", state("yaw" to 0f), state("yaw" to 45f))
        history.record("move", "Origin nudge", state("origin" to 2.0), state("origin" to 3.0))

        val undone = history.undoAll().shouldNotBeNull()
        undone.count shouldBe 3
        undone.values shouldBe state("origin" to 1.0, "yaw" to 0f)
        history.undoCount shouldBe 0
        history.redoCount shouldBe 3

        history.redoLast().shouldNotBeNull().values shouldBe state("origin" to 2.0)
    }

    test("redo all merges every entry with the newest value winning") {
        val history = EditHistory()
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 2.0))
        history.record("move", "Origin nudge", state("origin" to 2.0), state("origin" to 3.0))
        history.undoAll()

        val redone = history.redoAll().shouldNotBeNull()
        redone.count shouldBe 2
        redone.values shouldBe state("origin" to 3.0)
        history.undoCount shouldBe 2
    }

    test("tool undo restores the tool's newest entry and keeps a newer disjoint change in place") {
        val history = EditHistory()
        history.record("resize", "+X face", state("halfX" to 2.0), state("halfX" to 4.0))
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))

        val result = history.undoTool("resize").shouldBeInstanceOf<ToolHistoryResult.Restored>()
        result.change.label shouldBe "+X face"
        result.change.values shouldBe state("halfX" to 2.0)
        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state("yaw" to 0f)
    }

    test("tool undo refuses when a newer entry touches the same key and leaves the stack intact") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))
        history.record("wand", "Capture", state("yaw" to 45f, "origin" to 1.0), state("yaw" to 0f, "origin" to 2.0))

        val result = history.undoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Entangled>()
        result.blockingTool shouldBe "wand"
        history.undoCount shouldBe 2
        history.undoLast().shouldNotBeNull().values shouldBe state("yaw" to 45f, "origin" to 1.0)
    }

    test("tool undo of a missing tool reports nothing left") {
        val history = EditHistory()
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 2.0))
        history.undoTool("resize") shouldBe ToolHistoryResult.NothingLeft
    }

    test("tool undo walks a tool's changes one at a time, across an interleaved axis") {
        // An editing session as recorded on a server: move, yaw x3, pitch x3, yaw x4, resize, move.
        val history = EditHistory()
        history.record("move", "carry", state("origin" to 0.0), state("origin" to 1.0))
        var yaw = 0f
        for (to in listOf(-15f, -30f, -45f)) {
            history.record("rotate", "Yaw", state("yaw" to yaw), state("yaw" to to)); yaw = to
        }
        var pitch = 0f
        for (to in listOf(-15f, -30f, -45f)) {
            history.record("rotate", "Pitch", state("pitch" to pitch), state("pitch" to to)); pitch = to
        }
        for (to in listOf(-60f, -75f, -90f, -105f)) {
            history.record("rotate", "Yaw", state("yaw" to yaw), state("yaw" to to)); yaw = to
        }
        history.record(
            "resize",
            "+Z face",
            state("halfZ" to 6.5, "shift" to 0.0),
            state("halfZ" to 13.75, "shift" to 7.25)
        )
        history.record("move", "carry", state("origin" to 1.0), state("origin" to 2.0))

        val yawThenPitchThenYaw = listOf(
            state("yaw" to -90f), state("yaw" to -75f), state("yaw" to -60f), state("yaw" to -45f),
            state("pitch" to -30f), state("pitch" to -15f), state("pitch" to 0f),
            state("yaw" to -30f), state("yaw" to -15f), state("yaw" to 0f),
        )
        for (expected in yawThenPitchThenYaw) {
            history.undoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe expected
        }
        history.undoTool("rotate") shouldBe ToolHistoryResult.NothingLeft

        history.undoTool("move")
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state("origin" to 1.0)
        history.undoTool("move")
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state("origin" to 0.0)
        history.undoTool("resize").shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state(
            "halfZ" to 6.5,
            "shift" to 0.0
        )
    }

    test("tool undo moves the entry to the redo stack and the arrow redoes it") {
        val history = EditHistory()
        history.record("resize", "+X face", state("halfX" to 2.0), state("halfX" to 3.0))
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))

        history.undoTool("resize").shouldBeInstanceOf<ToolHistoryResult.Restored>()
        history.redoCount shouldBe 1
        history.redoLast().shouldNotBeNull().values shouldBe state("halfX" to 3.0)
        history.undoCount shouldBe 2
    }

    test("tool redo brings back the tool's last undone change") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))
        history.undoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Restored>()

        val result = history.redoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Restored>()
        result.change.values shouldBe state("yaw" to 45f)
        history.undoCount shouldBe 1
        history.redoCount shouldBe 0
    }

    test("tool redo reaches past another tool's undone change when the keys are disjoint") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 2.0))
        history.undoTool("rotate")
        history.undoTool("move")

        history.redoTool("rotate")
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state("yaw" to 45f)
        history.redoTool("move")
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state("origin" to 2.0)
        history.redoCount shouldBe 0
    }

    test("tool redo refuses when an undone change in front shares a key") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))
        history.record("wand", "Capture", state("yaw" to 45f), state("yaw" to 0f))
        history.undoLast()
        history.undoLast()

        val result = history.redoTool("wand").shouldBeInstanceOf<ToolHistoryResult.Entangled>()
        result.blockingTool shouldBe "rotate"
        history.redoCount shouldBe 2
    }

    test("tool redo reports nothing left when the tool has no undone changes") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))
        history.undoTool("rotate")
        history.redoTool("move") shouldBe ToolHistoryResult.NothingLeft
    }

    test("a new change clears the tool redo entries too") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))
        history.undoTool("rotate")
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 2.0))
        history.redoTool("rotate") shouldBe ToolHistoryResult.NothingLeft
    }

    test("mixed tool and arrow traffic stays consistent when entries move out of order") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 45f))
        history.record("move", "Origin nudge", state("origin" to 1.0), state("origin" to 2.0))

        history.undoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Restored>()
        history.undoLast().shouldNotBeNull().values shouldBe state("origin" to 1.0)

        history.redoLast().shouldNotBeNull().values shouldBe state("origin" to 2.0)
        history.redoLast().shouldNotBeNull().values shouldBe state("yaw" to 45f)
        history.undoCount shouldBe 2
        history.redoCount shouldBe 0

        history.undoLast().shouldNotBeNull().values shouldBe state("yaw" to 0f)
        history.undoLast().shouldNotBeNull().values shouldBe state("origin" to 1.0)
    }

    test("a click entry never absorbs a following scroll") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 15f), coalesceMillis = 0, now = 0)
        history.record("rotate", "Yaw", state("yaw" to 15f), state("yaw" to 20f), coalesceMillis = 1200, now = 300)

        history.undoCount shouldBe 2
        history.undoTool("rotate")
            .shouldBeInstanceOf<ToolHistoryResult.Restored>().change.values shouldBe state("yaw" to 15f)
    }

    test("a scroll burst never absorbs a following click") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 5f), coalesceMillis = 1200, now = 0)
        history.record("rotate", "Yaw", state("yaw" to 5f), state("yaw" to 20f), coalesceMillis = 0, now = 300)
        history.undoCount shouldBe 2
    }

    test("a merge drops keys that returned to their start value but keeps the live ones") {
        val history = EditHistory()
        history.record(
            "move",
            "Origin slide",
            state("x" to 1.0, "y" to 5.0),
            state("x" to 2.0, "y" to 6.0),
            coalesceMillis = 1200,
            now = 0
        )
        history.record(
            "move",
            "Origin slide",
            state("x" to 2.0, "y" to 6.0),
            state("x" to 1.0, "y" to 6.0),
            coalesceMillis = 1200,
            now = 300
        )

        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state("y" to 5.0)
    }

    test("a coalescing record merges into an entry a tool redo just brought back") {
        val history = EditHistory()
        history.record("rotate", "Yaw", state("yaw" to 0f), state("yaw" to 5f), coalesceMillis = 1200, now = 0)
        history.undoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Restored>()
        history.redoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Restored>()
        history.record("rotate", "Yaw", state("yaw" to 5f), state("yaw" to 10f), coalesceMillis = 1200, now = 500)

        history.undoCount shouldBe 1
        history.undoLast().shouldNotBeNull().values shouldBe state("yaw" to 0f)
    }

    test("a point carry entry restores the pre-grab vertex list via tool undo") {
        val history = EditHistory()
        val before = mapOf("poly.points" to listOf(Vector(1.0, 0.0, 1.0), Vector(2.0, 0.0, 2.0)))
        val after = mapOf("poly.points" to listOf(Vector(1.0, 0.0, 1.0), Vector(5.0, 0.0, 5.0)))
        history.record("wand", "Point 2 carry", before, after)

        val result = history.undoTool("wand").shouldBeInstanceOf<ToolHistoryResult.Restored>()
        result.change.values shouldBe before
    }

    test("wand point edits entangle with a newer resize wall drag") {
        val history = EditHistory()
        history.record(
            "wand", "Point 1 nudge",
            mapOf("poly.points" to listOf(Vector(1.0, 0.0, 1.0))),
            mapOf("poly.points" to listOf(Vector(1.5, 0.0, 1.0))),
        )
        history.record(
            "resize", "wall 1",
            mapOf("poly.points" to listOf(Vector(1.5, 0.0, 1.0))),
            mapOf("poly.points" to listOf(Vector(2.0, 0.0, 1.0))),
        )

        val result = history.undoTool("wand").shouldBeInstanceOf<ToolHistoryResult.Entangled>()
        result.blockingTool shouldBe "resize"
    }

    test("point slides coalesce and an out-and-back slide pops off the stack") {
        val history = EditHistory()
        val start = mapOf("poly.points" to listOf(Vector(1.0, 0.0, 1.0)))
        val out = mapOf("poly.points" to listOf(Vector(1.25, 0.0, 1.0)))
        history.record("wand", "Point 1 slide", start, out, coalesceMillis = 1200, now = 1000)
        history.record("wand", "Point 1 slide", out, start, coalesceMillis = 1200, now = 1500)

        history.undoCount shouldBe 0
    }
})
