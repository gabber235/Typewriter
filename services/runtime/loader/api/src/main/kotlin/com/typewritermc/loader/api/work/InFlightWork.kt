package com.typewritermc.loader.api.work

import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext

/**
 * The work in flight in the runtimes of one host: every task an engine's dispatcher runs, and every outbound operation
 * a runtime makes through the host's messaging and shared artifacts, from its start until its result is back with
 * its caller. A host drains it before shutdown or rollout, exports [count] as a metric, and a stepped game test starts
 * no tick while work a tick caused still runs.
 *
 * Each item costs one atomic increment and one decrement. Item events reach observers only while one is attached; an
 * observer hears the end of exactly the items it heard begin. Any thread may begin, end and observe.
 */
class InFlightWork {
    private val running = AtomicInteger()
    private val observers = CopyOnWriteArrayList<WorkObserver>()

    /** How many items run now. */
    val count: Int get() = running.get()

    /** Item [name] for [subjects] (null: for every subject) begins now and runs until [WorkItem.end]. */
    fun begin(
        name: String,
        subjects: Set<WorkSubject>?,
    ): WorkItem {
        running.incrementAndGet()
        if (observers.isEmpty()) return WorkItem(this, name, subjects, emptyList())
        val heard = observers.toList()
        val item = WorkItem(this, name, subjects, heard)
        heard.forEach { it.began(item) }
        return item
    }

    /** [observer] hears every item that begins from now on, until the returned handle closes. */
    fun observe(observer: WorkObserver): AutoCloseable {
        observers += observer
        return AutoCloseable { observers -= observer }
    }

    internal fun ended(
        item: WorkItem,
        failure: Throwable?,
    ) {
        running.decrementAndGet()
        item.heard.forEach { it.ended(item, failure) }
    }
}

/** One item of [InFlightWork]: [name] says what runs, [subjects] for whom, null for every subject. */
class WorkItem internal constructor(
    private val work: InFlightWork,
    val name: String,
    val subjects: Set<WorkSubject>?,
    internal val heard: List<WorkObserver>,
) {
    private val done =
        java.util.concurrent.atomic
            .AtomicBoolean()

    /** The item ended; ending it again does nothing. */
    fun end() = finish(null)

    /** The item ended without its effect: its outbound operation failed with [cause]. Ending it again does nothing. */
    fun failed(cause: Throwable) = finish(cause)

    private fun finish(failure: Throwable?) {
        if (done.compareAndSet(false, true)) work.ended(this, failure)
    }

    override fun toString(): String = "$name for ${subjects ?: "every subject"}"
}

/** Hears the items of [InFlightWork] while attached. Called on the thread that begins or ends the item; keep it short. */
interface WorkObserver {
    fun began(item: WorkItem)

    /** [item] ended; [failure] is why it ended without its effect, null when it ran to its end. */
    fun ended(
        item: WorkItem,
        failure: Throwable?,
    )
}

/** Whom work is for: a principal, `minecraft` and a player's UUID for a Minecraft player. */
data class WorkSubject(
    val kind: String,
    val id: String,
)

/**
 * The subjects of the work running in a coroutine and its children. Work without it is for every subject. Where it
 * is set decides only whom a stalled or failed item is reported to, never whether work counts.
 */
class WorkSubjects(
    val subjects: Set<WorkSubject>,
) : AbstractCoroutineContextElement(WorkSubjects) {
    companion object Key : CoroutineContext.Key<WorkSubjects>

    override fun toString(): String = "WorkSubjects($subjects)"
}
