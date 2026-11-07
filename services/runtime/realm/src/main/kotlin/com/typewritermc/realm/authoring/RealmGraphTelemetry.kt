package com.typewritermc.realm.authoring

import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.services.libs.telemetry.ServiceTelemetry

/**
 * Counts what the realm's live graph computes and evicts, by the kind of query, so an operator sees how much check
 * work each commit causes and whether the memo limit forgets results.
 */
class RealmGraphTelemetry(
    telemetry: ServiceTelemetry,
) : GraphListener {
    private val computed = telemetry.counter("typewriter.realm.graph.computed", "{computation}")
    private val evicted = telemetry.counter("typewriter.realm.graph.evicted", "{memo}")

    override fun computed(key: GraphKey<*>) = computed.add("query.kind" to key.kind)

    override fun evicted(key: GraphKey<*>) = evicted.add("query.kind" to key.kind)

    private val GraphKey<*>.kind: String get() = this::class.simpleName ?: "anonymous"
}
