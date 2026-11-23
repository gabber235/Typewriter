package com.typewritermc.realm.authoring

import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.formula.graph.GraphWork
import com.typewritermc.services.libs.telemetry.ServiceTelemetry

/**
 * Counts what the realm's live graph computes and evicts, by the kind of query, so an operator sees how much check
 * work each commit causes and whether the memo limit forgets results.
 */
class RealmGraphTelemetry(
    telemetry: ServiceTelemetry,
) : GraphListener {
    private val computed = telemetry.counter("typewriter.graph.computed", "{computation}")
    private val evicted = telemetry.counter("typewriter.graph.evicted", "{memo}")

    override fun computed(key: GraphKey<*>) = computed.add("query.kind" to key.kind)

    override fun evicted(key: GraphKey<*>) = evicted.add("query.kind" to key.kind)

    private val GraphKey<*>.kind: String get() = this::class.simpleName ?: "anonymous"
}

/**
 * Records what one operation's graph reads did, as the counter [name] split by kind of work and by the attributes
 * given, so an operator sees what an operation cost in graph steps.
 */
internal class GraphWorkTelemetry(
    telemetry: ServiceTelemetry,
    name: String,
) {
    private val counter = telemetry.counter(name, "{step}")

    fun record(
        work: GraphWork,
        vararg attributes: Pair<String, String>,
    ) {
        val counts = work.counts()
        counter.add(counts.computed, KIND to "computed", *attributes)
        counter.add(counts.verified, KIND to "verified", *attributes)
        counter.add(counts.walked, KIND to "walked", *attributes)
        counter.add(counts.copied, KIND to "copied", *attributes)
    }

    private companion object {
        const val KIND = "graph.work"
    }
}
