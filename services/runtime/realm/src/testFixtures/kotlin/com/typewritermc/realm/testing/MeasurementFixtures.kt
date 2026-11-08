package com.typewritermc.realm.testing

import com.typewritermc.setup.Setup
import com.typewritermc.setup.setup
import com.typewritermc.types.integer
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.type_catalog.DataValue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.nanoseconds
import kotlin.time.measureTime
import kotlin.time.measureTimedValue

/*
 * The seeded realm measurement: a realm of the size the layer's gates are written for, and what one commit on it
 * costs. It measures and prints; SeededRealmMeasurement asserts the gates on what it measures.
 */

/**
 * [names] plain Definitions `n<i>`; [holders] formulas `f<i>` that each name three of them through provider
 * functions and the catalog type Int; the record type Gold under an alias chain three deep; and [contentHolders]
 * Definitions `c<i>` whose type is the end of that chain, so every check of their values resolves content ids through
 * all three.
 */
fun seededWorkload(
    names: Int = 1000,
    holders: Int = 1000,
    contentHolders: Int = 200,
): Setup<FormulaPage> =
    setup("seeded-measurement") {
        formulaPage {
            repeat(names) { definition("n$it", intUse, it) }
            repeat(holders) { i ->
                val (a, b, c) = listOf(i, i * 7 + 1, i * 13 + 2).map { it % names }
                formula("f$i", intUse, "let none: List<Int> = emptyList()\nlet x: Int = n$a.plus(n$b)\nx.times(2) + n$c")
            }
            val gold = customType("Gold") { field("gold", intUse) }
            val first = alias("amount_0", fieldKey(gold))
            val second = alias("amount_1", fieldKey(first))
            val third = alias("amount_2", fieldKey(second))
            repeat(contentHolders) { i ->
                definition("c$i", plainType(fieldKey(third))) {
                    recordValue(
                        it,
                        "gold" to DataValue.integer(i.toLong()),
                    )
                }
            }
        }
    }

/** What one commit cost on a seeded realm, with the check pass that followed it. */
data class CommitCost(
    val label: String,
    val commit: Duration,
    /** From the commit reply until the findings are ready; near zero when the checks finished during the commit. */
    val pass: Duration,
    val graphReads: Duration,
    val replyBytes: Int,
    /** The part of [replyBytes] that is the reply's finding sets; the rest is the saved state's resources and links. */
    val findingBytes: Int,
    val computed: Long,
    val evicted: Long,
    val evidence: Int,
    val hints: Int,
) {
    override fun toString(): String =
        "$label: commit $commit, pass $pass, graph reads during commit $graphReads, reply $replyBytes bytes " +
            "(findings $findingBytes, saved state ${replyBytes - findingBytes}), " +
            "computed $computed, evicted $evicted, evidence held $evidence, hints $hints"
}

/**
 * Starts the realm's checks with replies that carry their findings, as a running Realm does, settles them, and says
 * how long that first pass took and what it found.
 */
internal suspend fun RealmFixture.startMeasuring(): String {
    findings = checks::findings
    val pass = measureTime { checks.drain() }
    val sets = checks.findings()
    val codes = sets.flatMap { it.findings }.groupingBy { it.code }.eachCount()
    return "cold pass $pass, finding sets ${sets.size}, evidence held ${sets.sumOf { it.expectations.size }}, findings $codes"
}

/** Commits [intents] as one edit that must commit, waits for the check pass it starts, and measures both. */
internal suspend fun RealmFixture.measuredCommit(
    label: String,
    vararg intents: EditIntent,
): CommitCost {
    val edit = prepare(intents.toList())
    val computedBefore = graphRuns.totalRuns()
    val evictedBefore = graphRuns.evicted()
    val bindingBefore = bindingNanos.get()
    val hintsBefore = hints
    val (reply, commit) = measureTimedValue { commit(edit) }
    val saved = reply.shouldBeCommitted()
    val pass = measureTime { checks.drain() }
    val sets = checks.findings()
    return CommitCost(
        label = label,
        commit = commit,
        pass = pass,
        graphReads = (bindingNanos.get() - bindingBefore).nanoseconds,
        replyBytes =
            CommitPreparedEditResponse.serializer
                .toJsonCode(reply)
                .encodeToByteArray()
                .size,
        findingBytes =
            saved.findings.sumOf {
                FindingSet.serializer
                    .toJsonCode(it)
                    .encodeToByteArray()
                    .size
            },
        computed = graphRuns.totalRuns() - computedBefore,
        evicted = graphRuns.evicted() - evictedBefore,
        evidence = sets.sumOf { it.expectations.size },
        hints = hints - hintsBefore,
    )
}

/** The middle of these timings, so one run slowed by the machine does not move a gate. */
fun List<Duration>.median(): Duration = sorted()[size / 2]
