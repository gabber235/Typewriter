package com.typewritermc.loader.api.work

import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext

/**
 * The work in flight in the runtimes of one host: every task an engine's dispatcher runs, and every outbound operation
 * a runtime makes through the host's messaging and shared artifacts, from its start until its result is back with
 * its caller. The loader's artifact host exports [count] as the gauge `typewriter.work.in_flight` and drains the work,
 * for at most its configured bound, before it closes its runtimes; before a rollout activates a candidate it drains
 * only the work of the runtimes that leave. Either drain logs the [items] still in flight when the bound runs out. A
 * stepped game test starts no tick while work a tick caused still runs.
 *
 * The host hands each runtime it stages the view [of] that runtime, so every item the runtime begins carries it as
 * [WorkItem.runtime]; a view shares the host's items, count and observers.
 *
 * Each item costs one insert into and one removal from a concurrent set, which is what lets a drain name what still
 * runs. Item events reach observers only while one is attached; an observer hears the end of exactly the items it
 * heard begin, before [count] drops. Any thread may begin, end and observe.
 */
class InFlightWork private constructor(
    private val host: Host,
    /** The runtime whose items this view begins; null for the host's own work. */
    val runtime: WorkRuntime?,
) {
    constructor() : this(Host(), null)

    private class Host {
        val running: MutableSet<WorkItem> = ConcurrentHashMap.newKeySet()
        val observers = CopyOnWriteArrayList<WorkObserver>()
    }

    /** The view of this host's work whose items belong to [runtime]. */
    fun of(runtime: WorkRuntime): InFlightWork = InFlightWork(host, runtime)

    /** How many items run now. */
    val count: Int get() = host.running.size

    /** The items that run now, in no particular order. */
    val items: List<WorkItem> get() = host.running.toList()

    /** Item [name] for [subjects] (null: for every subject) begins now and runs until [WorkItem.end]. */
    fun begin(
        name: String,
        subjects: Set<WorkSubject>?,
    ): WorkItem {
        val heard = if (host.observers.isEmpty()) emptyList() else host.observers.toList()
        val item = WorkItem(this, name, subjects, runtime, heard)
        host.running += item
        heard.forEach { it.began(item) }
        return item
    }

    /** [observer] hears every item that begins from now on, until the returned handle closes. */
    fun observe(observer: WorkObserver): AutoCloseable {
        host.observers += observer
        return AutoCloseable { host.observers -= observer }
    }

    internal fun ended(
        item: WorkItem,
        failure: Throwable?,
    ) {
        // Observers hear the end before the count drops, so a count of zero means every end was heard; an observer
        // that throws still lets it drop, so a drain never waits on an item that ended.
        try {
            item.heard.forEach { it.ended(item, failure) }
        } finally {
            host.running -= item
        }
    }
}

/**
 * One item of [InFlightWork]: [name] says what runs, [subjects] for whom (null for every subject), and [runtime] in
 * which runtime (null for the host's own work).
 */
class WorkItem internal constructor(
    private val work: InFlightWork,
    val name: String,
    val subjects: Set<WorkSubject>?,
    val runtime: WorkRuntime?,
    internal val heard: List<WorkObserver>,
) {
    private val done = AtomicBoolean()

    /** The item ended; ending it again does nothing. */
    fun end() = finish(null)

    /** The item ended without its effect: its outbound operation failed with [cause]. Ending it again does nothing. */
    fun failed(cause: Throwable) = finish(cause)

    private fun finish(failure: Throwable?) {
        if (done.compareAndSet(false, true)) work.ended(this, failure)
    }

    override fun toString(): String = "$name for ${subjects ?: "every subject"}" + (runtime?.let { " in $it" } ?: "")
}

/**
 * One runtime a host staged, named by [name]. Two stagings are two runtimes even under one name, as a baseline and the
 * candidate replacing it are, so a runtime equals only itself.
 */
class WorkRuntime(
    val name: String,
) {
    override fun toString(): String = name
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
