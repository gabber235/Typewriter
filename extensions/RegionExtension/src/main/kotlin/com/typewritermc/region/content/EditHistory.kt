package com.typewritermc.region.content

import java.util.concurrent.ConcurrentLinkedDeque

/**
 * Bounded undo and redo history over typed [EditorState] snapshots. Each recorded change stores
 * which tool made it and the before and after values of only the fields it touched, all values
 * absolute: undoing a change applies its before values, redoing applies its after values.
 *
 * Tool scoped undo removes the tool's newest entry out of order, which is safe exactly
 * when no newer entry touches any of its fields; otherwise the result is
 * [ToolHistoryResult.Entangled] and nothing moves. Entries are never mutated or consumed
 * by a refusal, so the global history can always unwind in order.
 *
 * Bursts of the same gesture, like scroll notches, collapse into one entry when recorded
 * with a coalesce window. A burst is bounded by the gap between notches and by a total
 * duration cap, fields that return to their start value drop out on merge, and an entry
 * left without an effect pops off the stack. Entries recorded without a window never
 * coalesce, so a click never absorbs a following scroll.
 *
 * Mutations happen on the server main thread. The deques are concurrent because the
 * editor's async tick reads the counts for the undo item and the hologram.
 */
internal class EditHistory(private val capacity: Int = DEFAULT_CAPACITY) {
    private val undoStack = ConcurrentLinkedDeque<HistoryEntry>()
    private val redoStack = ConcurrentLinkedDeque<HistoryEntry>()

    init {
        require(capacity > 0) { "History capacity must be positive, got $capacity" }
    }

    val undoCount: Int get() = undoStack.size
    val redoCount: Int get() = redoStack.size

    /**
     * Records the difference between [before] and [after]. Returns `false` when nothing
     * changed. A recorded change makes the redo entries unreachable, so they are dropped.
     * With a positive [coalesceMillis] the change joins a coalescible top entry carrying
     * the same [tool] and [label] when the gap and the total burst duration allow it.
     */
    fun record(
        tool: EditTool,
        label: String,
        before: EditorState,
        after: EditorState,
        coalesceMillis: Long = 0,
        now: Long = System.currentTimeMillis(),
    ): Boolean {
        val delta = changedDelta(before, after) ?: return false
        redoStack.clear()

        val top = undoStack.peekFirst()
        if (top != null && coalesceMillis > 0 && top.coalescible && top.tool == tool && top.label == label &&
            now - top.lastRecordedAt < coalesceMillis && now - top.firstRecordedAt < MAX_BURST_MILLIS
        ) {
            if (!top.merge(delta, now)) undoStack.removeFirstOccurrence(top)
            return true
        }

        undoStack.addFirst(
            HistoryEntry(
                tool = tool,
                label = label,
                before = delta.before,
                after = delta.after,
                firstRecordedAt = now,
                lastRecordedAt = now,
                coalescible = coalesceMillis > 0,
            ),
        )
        while (undoStack.size > capacity) undoStack.pollLast()
        return true
    }

    /** The newest change; the caller applies [RestoredChange.values]. */
    fun undoLast(): RestoredChange? {
        val entry = undoStack.pollFirst() ?: return null
        redoStack.addFirst(entry)
        return RestoredChange(entry.label, entry.before, 1)
    }

    fun redoLast(): RestoredChange? {
        val entry = redoStack.pollFirst() ?: return null
        undoStack.addFirst(entry)
        return RestoredChange(entry.label, entry.after, 1)
    }

    /**
     * Every change merged into one restore, oldest before values winning per field. The
     * entries move to the redo stack one by one, so they can still be redone step by step.
     */
    fun undoAll(): RestoredChange? {
        if (undoStack.isEmpty()) return null
        var values = EditorState.EMPTY
        var count = 0
        var label = ""
        while (true) {
            val entry = undoStack.pollFirst() ?: break
            redoStack.addFirst(entry)
            values = values.overriddenBy(entry.before)
            label = entry.label
            count++
        }
        return RestoredChange(if (count == 1) label else "$count changes", values, count)
    }

    fun redoAll(): RestoredChange? {
        if (redoStack.isEmpty()) return null
        var values = EditorState.EMPTY
        var count = 0
        var label = ""
        while (true) {
            val entry = redoStack.pollFirst() ?: break
            undoStack.addFirst(entry)
            values = values.overriddenBy(entry.after)
            label = entry.label
            count++
        }
        return RestoredChange(if (count == 1) label else "$count changes", values, count)
    }

    /**
     * Undoes [tool]'s newest change while keeping every other tool's work in place. The
     * entry is removed out of order, which is only safe when nothing newer touches its
     * fields: otherwise the result is [ToolHistoryResult.Entangled] naming the tool whose
     * newer change overlaps, nothing moves, and the arrow can unwind the history in order.
     */
    fun undoTool(tool: EditTool): ToolHistoryResult {
        val entries = undoStack.toList()
        val index = entries.indexOfFirst { it.tool == tool }
        if (index < 0) return ToolHistoryResult.NothingLeft

        val entry = entries[index]
        val blocker = entries.subList(0, index).firstOrNull { newer -> newer.fields.any(entry.fields::contains) }
        if (blocker != null) return ToolHistoryResult.Entangled(blocker.tool)

        undoStack.removeFirstOccurrence(entry)
        redoStack.addFirst(entry)
        return ToolHistoryResult.Restored(RestoredChange(entry.label, entry.before, 1))
    }

    /**
     * Redoes [tool]'s newest undone change: the mirror of [undoTool] on the redo stack,
     * with the same out of order rule against the redo entries in front of it.
     */
    fun redoTool(tool: EditTool): ToolHistoryResult {
        val entries = redoStack.toList()
        val index = entries.indexOfFirst { it.tool == tool }
        if (index < 0) return ToolHistoryResult.NothingLeft

        val entry = entries[index]
        val blocker = entries.subList(0, index).firstOrNull { ahead -> ahead.fields.any(entry.fields::contains) }
        if (blocker != null) return ToolHistoryResult.Entangled(blocker.tool)

        redoStack.removeFirstOccurrence(entry)
        undoStack.addFirst(entry)
        return ToolHistoryResult.Restored(RestoredChange(entry.label, entry.after, 1))
    }

    private class HistoryEntry(
        val tool: EditTool,
        val label: String,
        before: EditorState,
        after: EditorState,
        val firstRecordedAt: Long,
        @Volatile var lastRecordedAt: Long,
        val coalescible: Boolean,
    ) {
        @Volatile
        var before: EditorState = before
            private set

        @Volatile
        var after: EditorState = after
            private set

        val fields: Set<EditField<*>> get() = before.fields

        /**
         * Joins a burst continuation into this entry, keeping the oldest before and the
         * newest after per field and dropping fields that returned to their start value.
         * Returns `false` when no field changes anything anymore; the caller pops the entry.
         */
        fun merge(changed: Delta, now: Long): Boolean {
            val merged = changedDelta(changed.before.overriddenBy(before), after.overriddenBy(changed.after))
                ?: return false
            before = merged.before
            after = merged.after
            lastRecordedAt = now
            return true
        }
    }

    /** The values to apply to the working state, all fields absolute. */
    data class RestoredChange(val label: String, val values: EditorState, val count: Int)

    companion object {
        private const val DEFAULT_CAPACITY = 64
        internal const val MAX_BURST_MILLIS = 4000L
    }
}

/** The outcome of a tool scoped undo or redo. */
internal sealed interface ToolHistoryResult {
    /** The entry moved and [change] holds the values to apply. */
    data class Restored(val change: EditHistory.RestoredChange) : ToolHistoryResult

    /** A newer change by [blockingTool] overlaps the entry's fields; nothing moved. */
    data class Entangled(val blockingTool: EditTool) : ToolHistoryResult

    /** The tool has no entry to move. */
    data object NothingLeft : ToolHistoryResult
}

/** A change reduced to the fields whose value actually moved, absolute on both sides. */
private class Delta(val before: EditorState, val after: EditorState)

/**
 * The [Delta] between [before] and [after], or `null` when nothing changed. Recording and
 * burst merging share this rule, so both always agree on what counts as a change and every
 * entry's before and after snapshots hold the same fields, which the tool undo conflict
 * check relies on.
 */
private fun changedDelta(before: EditorState, after: EditorState): Delta? {
    val changed = changedFields(before, after)
    if (changed.isEmpty()) return null
    return Delta(before.onlyWithDefaults(changed), after.onlyWithDefaults(changed))
}

/**
 * [EditorState.only], with a field this snapshot does not hold filled in with its default, so
 * both sides of a delta always hold the same fields.
 */
private fun EditorState.onlyWithDefaults(fields: Set<EditField<*>>): EditorState {
    var reduced = only(fields)
    for (field in fields) {
        if (field !in reduced.fields) reduced = reduced.withDefault(field)
    }
    return reduced
}

private fun <T> EditorState.withDefault(field: EditField<T>): EditorState = with(field, field.default)
