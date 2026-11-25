package com.typewritermc.formula.graph

import java.util.concurrent.atomic.AtomicLong

/**
 * The work reads and advances did on a graph, counted for whoever pinned or advanced it, so an operation can say what it
 * cost in graph steps instead of time. Reads of one pin may run on several threads at once, so the counts are atomic.
 */
class GraphWork {
    private val computed = AtomicLong()
    private val cleaned = AtomicLong()
    private val dirtied = AtomicLong()
    private val walked = AtomicLong()
    private val read = AtomicLong()

    /** What the reads and advances did so far. */
    fun counts(): Counts = Counts(computed.get(), cleaned.get(), dirtied.get(), walked.get(), read.get())

    internal fun computed() = computed.incrementAndGet()

    internal fun cleaned() = cleaned.incrementAndGet()

    internal fun dirtied() = dirtied.incrementAndGet()

    internal fun walked() = walked.incrementAndGet()

    internal fun read() = read.incrementAndGet()

    data class Counts(
        /** Queries that ran their compute, also when the result turned out equal. */
        val computed: Long = 0,
        /** Results a change marked that were found unchanged without running their compute, each once per revision. */
        val cleaned: Long = 0,
        /** Edges an advance marked as possibly changed, each once until a read cleans it. */
        val dirtied: Long = 0,
        /** Keys a walk of what a query read visited. */
        val walked: Long = 0,
        /**
         * Reads a caller or a running query made through the graph, each one, also of a memo already current, so a
         * loop over many keys inside one compute costs what it reads.
         */
        val read: Long = 0,
    ) {
        operator fun minus(other: Counts) =
            Counts(
                computed - other.computed,
                cleaned - other.cleaned,
                dirtied - other.dirtied,
                walked - other.walked,
                read - other.read,
            )

        operator fun plus(other: Counts) =
            Counts(
                computed + other.computed,
                cleaned + other.cleaned,
                dirtied + other.dirtied,
                walked + other.walked,
                read + other.read,
            )

        /** Every step together. */
        val total: Long get() = computed + cleaned + dirtied + walked + read

        companion object {
            val NONE = Counts()
        }
    }
}
