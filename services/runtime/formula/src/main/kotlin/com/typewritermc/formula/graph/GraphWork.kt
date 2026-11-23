package com.typewritermc.formula.graph

import java.util.concurrent.atomic.AtomicLong

/**
 * The work reads did on a graph, counted for whoever pinned them, so an operation can say what it cost in graph steps
 * instead of time. Reads of one pin may run on several threads at once, so the counts are atomic.
 */
class GraphWork {
    private val computed = AtomicLong()
    private val verified = AtomicLong()
    private val walked = AtomicLong()
    private val copied = AtomicLong()

    /** What the reads did so far. */
    fun counts(): Counts = Counts(computed.get(), verified.get(), walked.get(), copied.get())

    internal fun computed() = computed.incrementAndGet()

    internal fun verified() = verified.incrementAndGet()

    internal fun walked() = walked.incrementAndGet()

    internal fun copied(memos: Int) = copied.addAndGet(memos.toLong())

    data class Counts(
        /** Queries that ran their compute, also when the result turned out equal. */
        val computed: Long,
        /** Memos found unchanged at a new revision without running their compute, each once per revision. */
        val verified: Long,
        /** Keys a walk of what a query read visited. */
        val walked: Long,
        /** Memos a fork copied from the graph it forked. */
        val copied: Long,
    ) {
        operator fun minus(other: Counts) =
            Counts(computed - other.computed, verified - other.verified, walked - other.walked, copied - other.copied)

        operator fun plus(other: Counts) =
            Counts(computed + other.computed, verified + other.verified, walked + other.walked, copied + other.copied)

        /** Every step together. */
        val total: Long get() = computed + verified + walked + copied

        companion object {
            val NONE = Counts(0, 0, 0, 0)
        }
    }
}
