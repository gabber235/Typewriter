package com.typewritermc.formula.graph

import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

/**
 * The work reads did on a graph, counted for whoever pinned them by the kind of key each step touched, so an operation
 * can say what it cost in graph steps instead of time, and which kinds of query that work went to. Reads of one pin may
 * run on several threads at once, so the counts are atomic. Outside this module work is made only by [counted], which
 * always hands it to a recorder, so no count is dropped unseen.
 */
class GraphWork
    @PublishedApi
    internal constructor() {
        private val byKind = ConcurrentHashMap<Class<*>, Tally>()

        @Volatile
        private var closed = false

        /** What the reads did so far, over every kind of key. */
        fun counts(): Counts =
            byKind.values.map(Tally::counts).fold(Counts(0, 0, 0)) { sum, it ->
                Counts(sum.computed + it.computed, sum.verified + it.verified, sum.walked + it.walked)
            }

        /** What the reads did so far, per kind of key: the simple name of the key's class. */
        fun countsByKind(): Map<String, Counts> =
            buildMap {
                byKind.forEach { (kind, tally) ->
                    merge(kind.simpleName.ifEmpty { "anonymous" }, tally.counts()) { a, b -> a + b }
                }
            }

        internal fun computed(key: GraphKey<*>) = tallyOf(key).computed.incrementAndGet()

        internal fun verified(key: GraphKey<*>) = tallyOf(key).verified.incrementAndGet()

        internal fun walked(key: GraphKey<*>) = tallyOf(key).walked.incrementAndGet()

        private fun tallyOf(key: GraphKey<*>): Tally {
            check(!closed) { "This work was already recorded, so nothing more can count on it." }
            return byKind.computeIfAbsent(key.javaClass) { Tally() }
        }

        /** Ends the counting: what reads do on this work from now on fails instead of going uncounted. */
        @PublishedApi
        internal fun close() {
            closed = true
        }

        private class Tally {
            val computed = AtomicLong()
            val verified = AtomicLong()
            val walked = AtomicLong()

            fun counts() = Counts(computed.get(), verified.get(), walked.get())
        }

        private operator fun Counts.plus(other: Counts) =
            Counts(computed + other.computed, verified + other.verified, walked + other.walked)

        companion object {
            /**
             * Runs [block] on fresh work and hands that work to [record] once [block] ends, also when it fails. The work
             * is closed first, so a read that kept it past [block] fails instead of counting what [record] never sees.
             */
            inline fun <T> counted(
                record: (GraphWork) -> Unit,
                block: (GraphWork) -> T,
            ): T {
                val work = GraphWork()
                try {
                    return block(work)
                } finally {
                    work.close()
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
