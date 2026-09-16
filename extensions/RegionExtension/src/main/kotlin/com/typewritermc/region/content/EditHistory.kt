package com.typewritermc.region.content

import java.util.concurrent.ConcurrentLinkedDeque

/**
 * Bounded undo and redo history over named state values. Each recorded change stores which
 * tool made it and the before and after values of only the keys it touched, all values
 * absolute: undoing a change applies its before values, redoing applies its after values.
 *
 * Tool scoped undo removes the tool's newest entry out of order, which is safe exactly
 * when no newer entry touches any of its keys; otherwise the result is
 * [ToolHistoryResult.Entangled] and nothing moves. Entries are never mutated or consumed
 * by a refusal, so the global history can always unwind in order.
 *
 * Bursts of the same gesture, like scroll notches, collapse into one entry when recorded
 * with a coalesce window. A burst is bounded by the gap between notches and by a total
 * duration cap, keys that return to their start value drop out on merge, and an entry
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
        tool: String,
        label: String,
        before: Map<String, Any?>,
        after: Map<String, Any?>,
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
     * Every change merged into one restore, oldest before values winning per key. The
     * entries move to the redo stack one by one, so they can still be redone step by step.
     */
    fun undoAll(): RestoredChange? {
        if (undoStack.isEmpty()) return null
        val values = mutableMapOf<String, Any?>()
        var count = 0
        var label = ""
        while (true) {
            val entry = undoStack.pollFirst() ?: break
            redoStack.addFirst(entry)
            values.putAll(entry.before)
            label = entry.label
            count++
        }
        return RestoredChange(if (count == 1) label else "$count changes", values, count)
    }

    fun redoAll(): RestoredChange? {
        if (redoStack.isEmpty()) return null
        val values = mutableMapOf<String, Any?>()
        var count = 0
        var label = ""
        while (true) {
            val entry = redoStack.pollFirst() ?: break
            undoStack.addFirst(entry)
            values.putAll(entry.after)
            label = entry.label
            count++
        }
        return RestoredChange(if (count == 1) label else "$count changes", values, count)
    }

    /**
     * Undoes [tool]'s newest change while keeping every other tool's work in place. The
     * entry is removed out of order, which is only safe when nothing newer touches its
     * keys: otherwise the result is [ToolHistoryResult.Entangled] naming the tool whose
     * newer change overlaps, nothing moves, and the arrow can unwind the history in order.
     */
    fun undoTool(tool: String): ToolHistoryResult {
        val entries = undoStack.toList()
        val index = entries.indexOfFirst { it.tool == tool }
        if (index < 0) return ToolHistoryResult.NothingLeft

        val entry = entries[index]
        val blocker = entries.subList(0, index).firstOrNull { newer -> newer.keys.any(entry.keys::contains) }
        if (blocker != null) return ToolHistoryResult.Entangled(blocker.tool)

        undoStack.removeFirstOccurrence(entry)
        redoStack.addFirst(entry)
        return ToolHistoryResult.Restored(RestoredChange(entry.label, entry.before, 1))
    }

    /**
     * Redoes [tool]'s newest undone change: the mirror of [undoTool] on the redo stack,
     * with the same out of order rule against the redo entries in front of it.
     */
    fun redoTool(tool: String): ToolHistoryResult {
        val entries = redoStack.toList()
        val index = entries.indexOfFirst { it.tool == tool }
        if (index < 0) return ToolHistoryResult.NothingLeft

        val entry = entries[index]
        val blocker = entries.subList(0, index).firstOrNull { ahead -> ahead.keys.any(entry.keys::contains) }
        if (blocker != null) return ToolHistoryResult.Entangled(blocker.tool)

        redoStack.removeFirstOccurrence(entry)
        undoStack.addFirst(entry)
        return ToolHistoryResult.Restored(RestoredChange(entry.label, entry.after, 1))
    }

    private class HistoryEntry(
        val tool: String,
        val label: String,
        before: Map<String, Any?>,
        after: Map<String, Any?>,
        val firstRecordedAt: Long,
        @Volatile var lastRecordedAt: Long,
        val coalescible: Boolean,
    ) {
        @Volatile
        var before: Map<String, Any?> = before
            private set

        @Volatile
        var after: Map<String, Any?> = after
            private set

        val keys: Set<String> get() = before.keys

        /**
         * Joins a burst continuation into this entry, keeping the oldest before and the
         * newest after per key and dropping keys that returned to their start value.
         * Returns `false` when no key changes anything anymore; the caller pops the entry.
         */
        fun merge(changed: Delta, now: Long): Boolean {
            val merged = changedDelta(changed.before + before, after + changed.after) ?: return false
            before = merged.before
            after = merged.after
            lastRecordedAt = now
            return true
        }
    }

    /** The values to apply to the working state, all keys absolute. */
    data class RestoredChange(val label: String, val values: Map<String, Any?>, val count: Int)

    companion object {
        private const val DEFAULT_CAPACITY = 64
        internal const val MAX_BURST_MILLIS = 4000L
    }
}

/** The outcome of a tool scoped undo or redo. */
internal sealed interface ToolHistoryResult {
    /** The entry moved and [change] holds the values to apply. */
    data class Restored(val change: EditHistory.RestoredChange) : ToolHistoryResult

    /** A newer change by [blockingTool] overlaps the entry's keys; nothing moved. */
    data class Entangled(val blockingTool: String) : ToolHistoryResult

    /** The tool has no entry to move. */
    data object NothingLeft : ToolHistoryResult
}

/** A change reduced to the keys whose value actually moved, absolute on both sides. */
private class Delta(val before: Map<String, Any?>, val after: Map<String, Any?>)

/**
 * The [Delta] between [before] and [after], or `null` when nothing changed. Recording and
 * burst merging share this rule, so both always agree on what counts as a change and every
 * entry's before and after maps stay on the same key set, which the tool undo conflict
 * check relies on.
 */
private fun changedDelta(before: Map<String, Any?>, after: Map<String, Any?>): Delta? {
    val changedKeys = (before.keys + after.keys).filter { before[it] != after[it] }
    if (changedKeys.isEmpty()) return null
    return Delta(changedKeys.associateWith { before[it] }, changedKeys.associateWith { after[it] })
}
