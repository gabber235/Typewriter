package com.typewritermc.formula.graph

import java.util.concurrent.atomic.AtomicLong

/**
 * The work reads did on a graph, counted for whoever pinned them, so an operation can say what it cost in graph steps
 * instead of time. Reads of one pin may run on several threads at once, so the counts are atomic. Outside this module
 * work is made only by [counted], which always hands it to a recorder, so no count is dropped unseen.
 */
class GraphWork
    @PublishedApi
    internal constructor() {
        private val computed = AtomicLong()
        private val verified = AtomicLong()
        private val walked = AtomicLong()

        /** What the reads did so far. */
        fun counts(): Counts = Counts(computed.get(), verified.get(), walked.get())

        internal fun computed() = computed.incrementAndGet()

        internal fun verified() = verified.incrementAndGet()

        internal fun walked() = walked.incrementAndGet()

        companion object {
            /** Runs [block] on fresh work and hands that work to [record] once [block] ends, also when it fails. */
            inline fun <T> counted(
                record: (GraphWork) -> Unit,
                block: (GraphWork) -> T,
            ): T {
                val work = GraphWork()
                try {
                    return block(work)
                } finally {
                    record(work)
                }
            }
        }

        data class Counts(
            /** Queries that ran their compute, also when the result turned out equal. */
            val computed: Long,
            /** Memos found unchanged at a new revision without running their compute, each once per revision. */
            val verified: Long,
            /** Keys a walk of what a query read visited. */
            val walked: Long,
        )
    }
