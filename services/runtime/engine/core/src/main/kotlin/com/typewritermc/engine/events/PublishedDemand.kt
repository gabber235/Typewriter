package com.typewritermc.engine.events

import com.typewritermc.events.Demand
import java.util.concurrent.CopyOnWriteArrayList

/** The demand the event runtime hands a subscribed source: [update] tells every watcher a changed set. */
internal class PublishedDemand<S : Any>(
    initial: Set<S>,
) : Demand<S> {
    @Volatile
    override var current: Set<S> = initial
        private set
    private val watchers = CopyOnWriteArrayList<(Set<S>) -> Unit>()

    @Synchronized
    override fun watch(changed: (Set<S>) -> Unit): AutoCloseable {
        watchers += changed
        changed(current)
        return AutoCloseable { watchers -= changed }
    }

    @Synchronized
    fun update(subscriptions: Set<S>) {
        if (subscriptions == current) return
        current = subscriptions
        watchers.forEach { it(subscriptions) }
    }
}
