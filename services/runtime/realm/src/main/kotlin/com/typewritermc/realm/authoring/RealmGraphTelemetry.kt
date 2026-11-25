package com.typewritermc.realm.authoring

import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.formula.graph.GraphWork
import com.typewritermc.services.libs.telemetry.ServiceTelemetry

/** An operation that reads the realm's graph; each records its graph work under its own [label]. */
enum class GraphOperation(
    internal val label: String,
) {
    /** Binding the names a commit makes resolve. */
    COMMIT_BIND("commit.bind"),

    /** Judging the findings a commit replies with. */
    COMMIT_REPLY("commit.reply"),

    /** A check pass over the live graph. */
    CHECK_PASS("checks.pass"),

    /** Evaluating every check over one captured view, as publication does. */
    CAPTURE_EVALUATION("capture.evaluation"),

    /** Judging the findings a state query replies with. */
    STATE_REPLY("state.reply"),

    /** Judging the findings a release is gated on. */
    RELEASE_JUDGEMENT("release.judgement"),
}

/** Where the realm records what one operation's graph reads did. */
fun interface GraphWorkRecorder {
    fun record(
        operation: GraphOperation,
        work: GraphWork,
    )
}

/**
 * The realm's graph telemetry. What each operation's graph reads did goes on one counter, split by kind of work, by
 * operation and by kind of query, so an operator sees what every operation cost in graph steps and which queries that
 * work went to. From the live graph's per key events it counts only evictions, by kind of query, so an operator sees
 * whether the memo limit forgets results.
 */
class RealmGraphTelemetry(
    telemetry: ServiceTelemetry,
) : GraphWorkRecorder,
    GraphListener {
    private val counter = telemetry.counter("typewriter.realm.graph_work", "{step}")
    private val evictions = telemetry.counter("typewriter.graph.evicted", "{memo}")

    override fun evicted(key: GraphKey<*>) = evictions.add(QUERY to (key::class.simpleName ?: "anonymous"))

    override fun record(
        operation: GraphOperation,
        work: GraphWork,
    ) {
        work.countsByKind().forEach { (query, counts) ->
            counter.add(counts.computed, KIND to "computed", OPERATION to operation.label, QUERY to query)
            counter.add(counts.verified, KIND to "verified", OPERATION to operation.label, QUERY to query)
            counter.add(counts.walked, KIND to "walked", OPERATION to operation.label, QUERY to query)
        }
    }

    private companion object {
        const val KIND = "graph.work"
        const val OPERATION = "realm.operation"
        const val QUERY = "query.kind"
    }
}
