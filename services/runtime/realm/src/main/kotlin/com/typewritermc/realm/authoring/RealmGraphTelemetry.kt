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

    companion object {
        val NONE = GraphWorkRecorder { _, _ -> }
    }
}

/**
 * Records what each operation's graph reads did on one counter, split by kind of work and by operation, so an operator
 * sees what every operation cost in graph steps.
 */
class RealmGraphWorkTelemetry(
    telemetry: ServiceTelemetry,
) : GraphWorkRecorder {
    private val counter = telemetry.counter("typewriter.realm.graph_work", "{step}")

    override fun record(
        operation: GraphOperation,
        work: GraphWork,
    ) {
        val counts = work.counts()
        counter.add(counts.computed, KIND to "computed", OPERATION to operation.label)
        counter.add(counts.verified, KIND to "verified", OPERATION to operation.label)
        counter.add(counts.walked, KIND to "walked", OPERATION to operation.label)
        counter.add(counts.read, KIND to "read", OPERATION to operation.label)
    }

    private companion object {
        const val KIND = "graph.work"
        const val OPERATION = "realm.operation"
    }
}
