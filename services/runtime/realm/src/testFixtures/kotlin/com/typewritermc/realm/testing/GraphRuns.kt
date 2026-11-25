package com.typewritermc.realm.testing

import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.realm.authoring.LinksAt
import com.typewritermc.realm.authoring.ProjectionAt
import com.typewritermc.realm.checking.CheckRun
import com.typewritermc.realm.formula.CheckFormula
import com.typewritermc.realm.formula.Evaluate
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

/**
 * Counts, per key, how often a realm's live graph gained a result: computed there, also a rerun that gives an equal
 * result, or computed in a fork it merged. Tests read which results were made again; graph work counts what they cost.
 */
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

    /** How often the value at each location was evaluated so far. */
    internal fun evaluations(): Map<ValueLocation, Long> = counts { (it as? Evaluate)?.at }

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
