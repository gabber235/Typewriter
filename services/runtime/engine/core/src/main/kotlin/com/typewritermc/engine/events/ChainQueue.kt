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
 * identical starts within one tick run once. Each chain counts as work of its protagonist until it ends, and a chain
 * it queues begins counting before it ends, so the count only reaches zero when the whole reaction is done.
 */
class ChainQueue(
    private val work: SubjectWork = NoSubjectWork,
) {
    private class Chain(
        val subject: Protagonist?,
        val key: Any?,
        val handle: AutoCloseable,
        val run: suspend () -> Unit,
    )

    private val lock = Any()
    private val waiting = ArrayDeque<Chain>()

    /** Queues [run] for [subject]; with a [key] equal to a waiting chain's, it merges into that chain instead. */
    fun enqueue(
        subject: Protagonist?,
        name: String,
        key: Any? = null,
        run: suspend () -> Unit,
    ) {
        synchronized(lock) {
            if (key != null && waiting.any { it.key == key }) return
            waiting += Chain(subject, key, subject?.let { work.begin(it, name) } ?: AutoCloseable {}, run)
        }
    }

    /** Drops every waiting chain of [protagonist], as when its player is wiped between tests. */
    fun clear(protagonist: Protagonist) {
        val dropped = synchronized(lock) { waiting.filter { it.subject == protagonist }.also { waiting.removeAll(it) } }
        dropped.forEach { it.handle.close() }
    }

    /** Runs waiting chains until none is left, including the chains they queue. A failing chain is logged and ends. */
    suspend fun runPending() {
        while (true) {
            val chain = synchronized(lock) { waiting.removeFirstOrNull() } ?: return
            try {
                chain.run()
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (failure: Exception) {
                log.log(Level.WARNING, "A chain failed and ended.", failure)
            } finally {
                chain.handle.close()
            }
        }
    }

    private companion object {
        val log: Logger = Logger.getLogger(ChainQueue::class.java.name)
    }
}
