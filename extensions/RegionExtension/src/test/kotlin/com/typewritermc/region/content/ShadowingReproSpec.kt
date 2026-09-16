package com.typewritermc.region.content

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.maps.shouldContain
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

/**
 * Covers a capture that shadows tool entries: marking again writes the same keys as the
 * tools, so a tool undo across it refuses with Entangled instead of consuming the entries,
 * and the full history stays available to the arrow.
 */
class ShadowingReproSpec : FunSpec({
    test("a re-mark entangles older rotate entries: Q undoes the post-capture step, then points to the arrow") {
        val history = EditHistory()

        history.record("wand", "Marked corner A", mapOf("marks.primary" to null), mapOf("marks.primary" to "A1"))
        history.record(
            "wand", "Marked corner B",
            mapOf("marks.secondary" to null, "work.origin" to "O0", "size.halfX" to 1.0),
            mapOf("marks.secondary" to "B1", "work.origin" to "O1", "size.halfX" to 4.5),
        )
        history.record("rotate", "Yaw", mapOf("work.yaw" to 0f), mapOf("work.yaw" to 15f))
        history.record("rotate", "Yaw", mapOf("work.yaw" to 15f), mapOf("work.yaw" to 30f))
        history.record(
            "wand", "Marked corner B",
            mapOf("marks.secondary" to "B1", "work.origin" to "O1", "size.halfX" to 4.5, "work.yaw" to 30f),
            mapOf("marks.secondary" to "B2", "work.origin" to "O2", "size.halfX" to 6.0, "work.yaw" to 0f),
        )
        history.record("rotate", "Yaw", mapOf("work.yaw" to 0f), mapOf("work.yaw" to 20f))

        history.undoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Restored>()
            .change.values shouldContain ("work.yaw" to 0f)

        history.undoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Entangled>()
            .blockingTool shouldBe "wand"
        history.undoCount shouldBe 5

        val recapture = history.undoLast().shouldNotBeNull()
        recapture.values shouldContain ("work.yaw" to 30f)
        recapture.values shouldContain ("work.origin" to "O1")
        history.undoLast().shouldNotBeNull().values shouldContain ("work.yaw" to 15f)
    }

    test("with no tool change after the re-capture, Q refuses instead of consuming silently") {
        val history = EditHistory()
        history.record("rotate", "Yaw", mapOf("work.yaw" to 0f), mapOf("work.yaw" to 45f))
        history.record(
            "wand", "Marked corner B",
            mapOf("marks.secondary" to "B1", "work.yaw" to 45f),
            mapOf("marks.secondary" to "B2", "work.yaw" to 0f),
        )

        history.undoTool("rotate").shouldBeInstanceOf<ToolHistoryResult.Entangled>().blockingTool shouldBe "wand"
        history.undoCount shouldBe 2
    }

    test("polygon: a point mark after a wall resize entangles it through poly.points") {
        val history = EditHistory()
        history.record("resize", "wall 1", mapOf("poly.points" to "P0"), mapOf("poly.points" to "P1"))
        history.record(
            "wand", "Outline point",
            mapOf("poly.marked" to "M0", "poly.points" to "P1", "work.origin" to "O0"),
            mapOf("poly.marked" to "M1", "poly.points" to "P2", "work.origin" to "O1"),
        )

        history.undoTool("resize").shouldBeInstanceOf<ToolHistoryResult.Entangled>().blockingTool shouldBe "wand"
    }
})
