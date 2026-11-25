package com.typewritermc.realm.authoring

import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.formula.graph.GraphWork
import com.typewritermc.services.libs.telemetry.ServiceTelemetry

/**
 * Counts what the realm's live graph evicts, by the kind of query, so an operator sees whether the memo limit forgets
 * results. What the graph computes is graph work, recorded per operation by [RealmGraphWorkTelemetry].
 */
class RealmGraphTelemetry(
    telemetry: ServiceTelemetry,
) : GraphListener {
    private val evicted = telemetry.counter("typewriter.graph.evicted", "{memo}")

    override fun evicted(key: GraphKey<*>) = evicted.add("query.kind" to (key::class.simpleName ?: "anonymous"))
}

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
 * Records what each operation's graph reads did on one counter, split by kind of work, by operation and by kind of
 * query, so an operator sees what every operation cost in graph steps and which queries that work went to.
 */
class RealmGraphWorkTelemetry(
    telemetry: ServiceTelemetry,
) : GraphWorkRecorder {
    private val counter = telemetry.counter("typewriter.realm.graph_work", "{step}")

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
