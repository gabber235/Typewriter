package com.typewritermc.region.content

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

/**
 * Covers undo without the wand, using the real labels and windows from RegionContentMode:
 * rotate gestures record per axis ("Yaw", "Pitch") with a 1200ms scroll window, and clicks
 * record with window 0 and never coalesce.
 */
class CoalescingReproSpec : FunSpec({
    test("A: a yaw scroll and a pitch scroll stay separate entries") {
        val history = EditHistory()
        history.record(
            EditTool.ROTATE,
            "Yaw",
            state(WORK_YAW of 0f),
            state(WORK_YAW of 5f),
            coalesceMillis = 1200,
            now = 0
        )
        history.record(
            EditTool.ROTATE,
            "Pitch",
            state(WORK_PITCH of 0f),
            state(WORK_PITCH of 5f),
            coalesceMillis = 1200,
            now = 500
        )

        history.undoCount shouldBe 2
        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
            .change.values shouldBe state(WORK_PITCH of 0f)
        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
            .change.values shouldBe state(WORK_YAW of 0f)
    }

    test("B: a fine scroll after a rotate click stays its own entry, one Q reverts only the scroll") {
        val history = EditHistory()
        history.record(EditTool.ROTATE, "Yaw", state(WORK_YAW of 0f), state(WORK_YAW of 15f), coalesceMillis = 0, now = 0)
        history.record(
            EditTool.ROTATE,
            "Yaw",
            state(WORK_YAW of 15f),
            state(WORK_YAW of 20f),
            coalesceMillis = 1200,
            now = 300
        )

        history.undoCount shouldBe 2
        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
            .change.values shouldBe state(WORK_YAW of 15f)
    }

    test("C: a scroll out and back leaves no entry and no phantom undo") {
        val history = EditHistory()
        history.record(
            EditTool.RESIZE,
            "+Z face",
            state(SIZE_HALF_Z of 6.5),
            state(SIZE_HALF_Z of 6.75),
            coalesceMillis = 1200,
            now = 0
        )
        history.record(
            EditTool.RESIZE,
            "+Z face",
            state(SIZE_HALF_Z of 6.75),
            state(SIZE_HALF_Z of 6.5),
            coalesceMillis = 1200,
            now = 300
        )

        history.undoCount shouldBe 0
        history.undoTool(EditTool.RESIZE) shouldBe ToolHistoryResult.NothingLeft
    }

    test("D: a fine-tuning session chunks at the burst cap instead of collapsing into one step") {
        val history = EditHistory()
        var yaw = 0f
        var now = 0L
        repeat(20) {
            history.record(
                EditTool.ROTATE,
                "Yaw",
                state(WORK_YAW of yaw),
                state(WORK_YAW of yaw + 5f),
                coalesceMillis = 1200,
                now = now
            )
            yaw += 5f
            now += 1000
        }

        // Notches 1s apart never hit the 1200ms gap, but the 4s cap cuts a chunk of four.
        history.undoCount shouldBe 5
        history.undoTool(EditTool.ROTATE).shouldBeInstanceOf<ToolHistoryResult.Restored>()
            .change.values shouldBe state(WORK_YAW of 80f)
    }
})
