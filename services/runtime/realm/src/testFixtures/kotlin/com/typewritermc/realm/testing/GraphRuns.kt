package com.typewritermc.realm.testing

import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.realm.authoring.LinksAt
import com.typewritermc.realm.authoring.ProjectionAt
import com.typewritermc.realm.checking.CheckRun
import com.typewritermc.realm.formula.CheckFormula
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

/** Counts what a realm's query graph computes, also a rerun that gives an equal result. */
class GraphRuns : GraphListener {
    private val computed = ConcurrentHashMap<GraphKey<*>, AtomicLong>()

    override fun computed(key: GraphKey<*>) {
        computed.computeIfAbsent(key) { AtomicLong() }.incrementAndGet()
    }

    /** How often [key] was computed so far. */
    fun runsOf(key: GraphKey<*>): Long = computed[key]?.get() ?: 0

    /** How often each check instance ran so far. */
    fun checkRuns(): Map<CheckInstanceId, Long> = counts { (it as? CheckRun)?.instance }

    /** How often the formula at each location was checked so far. */
    internal fun formulaChecks(): Map<ValueLocation, Long> = counts { (it as? CheckFormula)?.at }

    /** How often the links of each node were judged for a graph read so far. */
    internal fun linkReads(): Map<ResourceId, Long> = counts { (it as? LinksAt)?.resource }

    /** How often each resource's slice of links was judged so far. */
    internal fun judgements(): Map<ResourceId, Long> = counts { (it as? ProjectionAt)?.resource }

    private fun <K : Any> counts(keyOf: (GraphKey<*>) -> K?): Map<K, Long> =
        buildMap {
            computed.forEach { (key, count) -> keyOf(key)?.let { merge(it, count.get(), Long::plus) } }
        }
}

/** The keys whose count in [after] is higher than in [before]. */
fun <K> Map<K, Long>.grewFrom(before: Map<K, Long>): Set<K> = filterTo(linkedMapOf()) { (key, count) -> count > (before[key] ?: 0) }.keys

/** Tells both listeners what the graph does, this one first. */
operator fun GraphListener.plus(other: GraphListener): GraphListener {
    val first = this
    return object : GraphListener {
        override fun computed(key: GraphKey<*>) {
            first.computed(key)
            other.computed(key)
        }

        override fun evicted(key: GraphKey<*>) {
            first.evicted(key)
            other.evicted(key)
        }
    }
}
