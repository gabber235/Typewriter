package com.typewritermc.realm.testing

import com.typewritermc.formula.graph.GraphWork
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
 * The seeded realm measurement: realms of the sizes the layer's gates are written for, and what one commit on them
 * costs. It measures and prints; SeededRealmMeasurement asserts the gates on what it measures.
 */

/** How many plain names, formula holders and content holders a seeded realm holds. */
data class SeededSize(
    val names: Int,
    val holders: Int,
    val contentHolders: Int,
)

/** What one value edit cost on one seeded realm with no, one and twenty unrelated broken formulas, [RUNS] edits each. */
data class BrokenFormulaCosts(
    val size: SeededSize,
    val none: List<CommitCost>,
    val one: List<CommitCost>,
    val twenty: List<CommitCost>,
) {
    /** The graph work one broken formula adds to a value edit, from the medians of the runs. */
    val extraForOne: Long get() = one.medianWork() - none.medianWork()

    /** The graph work twenty broken formulas add to a value edit, from the medians of the runs. */
    val extraForTwenty: Long get() = twenty.medianWork() - none.medianWork()

    override fun toString(): String =
        "$size: graph work per value edit, none ${none.medianWork()}, one ${one.medianWork()}, twenty ${twenty.medianWork()}; " +
            "extra for one $extraForOne, for twenty $extraForTwenty"
}

/**
 * Seeds a realm of [size] with hooks, then measures value edits of its last name with no broken formula, after one
 * formula breaks, and after nineteen more break; the broken formulas read none of the edited name. Prints each commit.
 */
suspend fun measureBrokenFormulas(size: SeededSize): BrokenFormulaCosts {
    lateinit var costs: BrokenFormulaCosts
    withSetup(seededWorkload(size.names, size.holders, size.contentHolders), catalog = hookCatalog()) { seeded ->
        val edited = seeded.named("n${size.names - 1}")

        suspend fun edits(
            label: String,
            from: Int,
        ) = (from until from + RUNS).map { value -> measuredCommit("$size $label", setVar(edited, intUse, plain(value))).also(::println) }

        println("$size seeded: ${startMeasuring()}")
        edits("warm up", 0)
        val none = edits("no broken formula", 100)
        println(measuredCommit("$size break one", setFormula(seeded.named("f0"), "missing_0 + 1")))
        val one = edits("one broken formula", 200)
        val nineteen = (1..19).map { setFormula(seeded.named("f$it"), "missing_$it + 1") }
        println(measuredCommit("$size break nineteen more", *nineteen.toTypedArray()))
        val twenty = edits("twenty broken formulas", 300)
        costs = BrokenFormulaCosts(size, none, one, twenty).also(::println)
    }
    return costs
}

/** How many value edits each stage measures; the gates read their median. */
private const val RUNS = 5

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
    /** The graph work of the commit's binding and reply, as the realm's telemetry counts it. */
    val commitWork: GraphWork.Counts,
    /** The graph work of the check pass the commit started, as the realm's telemetry counts it. */
    val passWork: GraphWork.Counts,
) {
    /** All the graph work the commit caused. */
    val work: GraphWork.Counts get() = commitWork + passWork

    override fun toString(): String =
        "$label: commit $commit, pass $pass, graph reads during commit $graphReads, reply $replyBytes bytes " +
            "(findings $findingBytes, saved state ${replyBytes - findingBytes}), " +
            "computed $computed, evicted $evicted, evidence held $evidence, hints $hints, " +
            "graph work ${work.total} (commit $commitWork, pass $passWork)"
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
    return "cold pass $pass, finding sets ${sets.size}, evidence held ${sets.sumOf { it.evidence.size }}, findings $codes"
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
    val commitBefore = workCounted(COMMIT_WORK)
    val passBefore = workCounted(PASS_WORK)
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
        evidence = sets.sumOf { it.evidence.size },
        hints = hints - hintsBefore,
        commitWork = workCounted(COMMIT_WORK) - commitBefore,
        passWork = workCounted(PASS_WORK) - passBefore,
    )
}

/** The operations of a commit: binding its names and judging the findings of its reply. */
private val COMMIT_WORK = setOf("commit.bind", "commit.reply")

/** The operation of the check pass a commit starts. */
private val PASS_WORK = setOf("checks.pass")

/** What the realm's [operations] did on the graph so far, as its telemetry counts it. */
private fun RealmFixture.workCounted(operations: Set<String>): GraphWork.Counts {
    val sums = telemetry.counts("typewriter.realm.graph_work", listOf("realm.operation", "graph.work"))

    fun kind(name: String) = sums.filterKeys { (operation, kind) -> operation in operations && kind == name }.values.sum()

    return GraphWork.Counts(kind("computed"), kind("verified"), kind("walked"))
}

private fun List<CommitCost>.medianWork(): Long = map { it.work.total }.sorted()[size / 2]
