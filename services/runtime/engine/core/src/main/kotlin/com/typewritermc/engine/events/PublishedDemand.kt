package com.typewritermc.engine.events

import com.typewritermc.events.Demand
import java.util.concurrent.CopyOnWriteArrayList

/** The demand the event runtime hands a configured source: [update] tells every watcher a changed set. */
internal class PublishedDemand<C : Any>(
    initial: Set<C>,
) : Demand<C> {
    @Volatile
    override var current: Set<C> = initial
        private set
    private val watchers = CopyOnWriteArrayList<(Set<C>) -> Unit>()

    @Synchronized
    override fun watch(changed: (Set<C>) -> Unit): AutoCloseable {
        watchers += changed
        changed(current)
        return AutoCloseable { watchers -= changed }
    }

    @Synchronized
    fun update(configurations: Set<C>) {
        if (configurations == current) return
        current = configurations
        watchers.forEach { it(configurations) }
    }
}
