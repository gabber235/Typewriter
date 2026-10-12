package com.typewritermc.region.content

import io.kotest.core.spec.style.FunSpec
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

        history.record(EditTool.WAND, "Marked corner A", state(PRIMARY of null), state(PRIMARY of "A1"))
        history.record(
            EditTool.WAND, "Marked corner B",
            state(SECONDARY of null, WORK_ORIGIN of "O0", SIZE_HALF_X of 1.0),
            state(SECONDARY of "B1", WORK_ORIGIN of "O1", SIZE_HALF_X of 4.5),
        )
        history.record(EditTool.ROTATE, "Yaw", state(WORK_YAW of 0f), state(WORK_YAW of 15f))
        history.record(EditTool.ROTATE, "Yaw", state(WORK_YAW of 15f), state(WORK_YAW of 30f))
        history.record(
            EditTool.WAND, "Marked corner B",
            state(SECONDARY of "B1", WORK_ORIGIN of "O1", SIZE_HALF_X of 4.5, WORK_YAW of 30f),
            state(SECONDARY of "B2", WORK_ORIGIN of "O2", SIZE_HALF_X of 6.0, WORK_YAW of 0f),
        )
        history.record(EditTool.ROTATE, "Yaw", state(WORK_YAW of 0f), state(WORK_YAW of 20f))

        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
            .change.values[WORK_YAW] shouldBe 0f

        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Entangled>()
            .blockingTool shouldBe EditTool.WAND
        history.undoCount shouldBe 5

        val recapture = history.undoLast().shouldNotBeNull()
        recapture.values[WORK_YAW] shouldBe 30f
        recapture.values[WORK_ORIGIN] shouldBe "O1"
        history.undoLast().shouldNotBeNull().values[WORK_YAW] shouldBe 15f
    }

    test("with no tool change after the re-capture, Q refuses instead of consuming silently") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(WORK_YAW of 0f), state(WORK_YAW of 45f))
        history.record(
            EditTool.WAND, "Marked corner B",
            state(SECONDARY of "B1", WORK_YAW of 45f),
            state(SECONDARY of "B2", WORK_YAW of 0f),
        )

        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Entangled>().blockingTool shouldBe EditTool.WAND
        history.undoCount shouldBe 2
    }

    test("polygon: a point mark after a wall resize entangles it through poly.points") {
        val history = EditHistory()
        history.record(EditTool.RESIZE, "wall 1", state(POLY_POINTS of "P0"), state(POLY_POINTS of "P1"))
        history.record(
            EditTool.WAND, "Outline point",
            state(MARKED of "M0", POLY_POINTS of "P1", WORK_ORIGIN of "O0"),
            state(MARKED of "M1", POLY_POINTS of "P2", WORK_ORIGIN of "O1"),
        )

        history.undoTool(EditTool.RESIZE).shouldBeInstanceOf<ToolHistoryResult.Entangled>().blockingTool shouldBe EditTool.WAND
    }
})
