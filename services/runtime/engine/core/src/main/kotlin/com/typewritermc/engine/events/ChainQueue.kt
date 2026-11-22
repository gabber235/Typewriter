package com.typewritermc.engine.events

import com.typewritermc.events.EnginePart
import com.typewritermc.identity.Protagonist
import kotlinx.coroutines.CancellationException
import java.util.logging.Level
import java.util.logging.Logger

/**
 * Tells the host that a protagonist has chain work queued or running, from the moment a chain is queued until it ends.
 * A test host uses it to know when a player's reaction is complete; the production engine counts nothing.
 */
interface SubjectWork : EnginePart {
    fun begin(
        protagonist: Protagonist,
        name: String,
    ): AutoCloseable
}

/** The production [SubjectWork]: nothing waits on chain work. */
object NoSubjectWork : SubjectWork {
    override fun begin(
        protagonist: Protagonist,
        name: String,
    ): AutoCloseable = AutoCloseable {}
}

/**
 * The chains of one engine, waiting for the next pickup. Sources and handlers queue inline; one pickup per tick drains
 * the queue on a worker. A start equal to one already waiting (same subject, entry, and context) merges into it, so
 * identical starts within one tick run once. Each chain counts as work of its protagonists until it ends (its subject,
 * or every live protagonist for an event without a subject, whose handlers run for them), and a chain it queues begins
 * counting before it ends, so the count only reaches zero when the whole reaction is done.
 */
class ChainQueue(
    private val work: SubjectWork = NoSubjectWork,
) {
    private class Chain(
        val key: Any?,
        /** The open work count of each protagonist this chain is work of; a wipe closes and removes its entry. */
        val work: MutableMap<Protagonist, AutoCloseable>,
        val run: suspend () -> Unit,
    )

    private val lock = Any()
    private val waiting = ArrayDeque<Chain>()

    /**
     * Queues [run] as work of [protagonists]; with a [key] equal to a waiting chain's, it merges into that chain
     * instead.
     */
    fun enqueue(
        protagonists: Set<Protagonist>,
        name: String,
        key: Any? = null,
        run: suspend () -> Unit,
    ) {
        synchronized(lock) {
            if (key != null && waiting.any { it.key == key }) return
            waiting += Chain(key, protagonists.associateWithTo(mutableMapOf()) { work.begin(it, name) }, run)
        }
    }

    /**
     * Wipes [protagonist], as between tests: a waiting chain that is only its work is dropped, and a chain that is also
     * work of others stops counting as its work but still runs for them.
     */
    fun clear(protagonist: Protagonist) {
        val released =
            synchronized(lock) {
                val mine = waiting.filter { protagonist in it.work }
                waiting.removeAll(mine.filter { it.work.keys == setOf(protagonist) })
                mine.mapNotNull { it.work.remove(protagonist) }
            }
        released.forEach { it.close() }
    }

    /** Runs waiting chains until none is left, including the chains they queue. A failing chain is logged and ends. */
    suspend fun runPending() {
        while (true) {
            val chain = synchronized(lock) { waiting.removeFirstOrNull() } ?: return
            try {
                chain.run()
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (
                @Suppress("TooGenericExceptionCaught") failure: Exception,
            ) {
                log.log(Level.WARNING, "A chain failed and ended.", failure)
            } finally {
                synchronized(lock) {
                    chain.work.values
                        .toList()
                        .also { chain.work.clear() }
                }.forEach { it.close() }
            }
        }
    }

    private companion object {
        val log: Logger = Logger.getLogger(ChainQueue::class.java.name)
    }
}
