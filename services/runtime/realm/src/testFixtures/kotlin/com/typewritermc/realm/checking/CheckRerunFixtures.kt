@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.checking.RealmChecks
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.checking.check
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.INT_USE
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TEXT_USE
import com.typewritermc.realm.authoring.TestDraftType
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.edit.MemoryAuthoringStorage
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.TestCheckProviders
import com.typewritermc.realm.testing.checksOf
import com.typewritermc.realm.testing.grewFrom
import com.typewritermc.realm.testing.settle
import com.typewritermc.types.integer
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.math.BigInteger
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/** The resource the ghost check looks for, absent unless a test creates it. */
internal val GHOST = ResourceId(value = "ghost")

/** The checks of [RerunChecks], in registration order. An each check has one instance per test resource. */
internal enum class RerunCheck(
    val each: Boolean,
) {
    NAME(each = true),
    COUNT(each = true),
    GHOST(each = false),
    SELECTION(each = false),
}

/**
 * Checks that each read one thing. NAME reads a test resource's name and reports it unless it is "valid"; it throws for
 * "throw", recurses forever for "recurse", fails to link for "linkage", and waits in [RerunGate] for "gated". Each
 * run of it is counted in [NameCheckRuns]. COUNT reads the count and reports a negative
 * one. GHOST reads the name of [GHOST] and reports while it is missing. SELECTION selects the test resources and reports
 * fewer than two.
 */
internal object RerunChecks : RealmCheckProvider {
    override fun RealmChecks.register() {
        each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
            val name = read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))
            NameCheckRuns.ran(draft.binding.location.resource)
            when ((name as? Availability.Available)?.value) {
                "throw" -> error("The name check exploded.")
                "recurse" -> recurse(0)
                "linkage" -> throw NoClassDefFoundError("com/example/Missing")
                "gated" -> RerunGate.pass()
            }
            check(name) { it == "valid" }.error("Name is invalid.", draft.binding.location)
        }
        each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
            check(read(boundPath<Int>(location(draft.binding.location.resource, "count"), INT_USE))) { it >= 0 }
                .error("Count is negative.", draft.binding.location)
        }
        realm {
            val ghost = read(boundPath<String>(location(GHOST, "name"), TEXT_USE))
            check(Availability.Available(ghost is Availability.Available)) { it }.error("Ghost is missing.", ValueLocation.of(REALM))
        }
        realm {
            val selected = select(TypedSelection(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)))).knownMatches
            check(Availability.Available(selected.size)) { it >= 2 }.error("Fewer than two resources.", ValueLocation.of(REALM))
        }
    }

    private fun recurse(depth: Int): Int = recurse(depth + 1) + 1
}

/** Where the NAME check of a resource named "gated" waits, after its reads, until a test releases it. */
internal object RerunGate {
    @Volatile
    private var entered = CountDownLatch(1)

    @Volatile
    private var released = CountDownLatch(1)

    /** Closes the gate again for the next test. */
    fun reset() {
        entered = CountDownLatch(1)
        released = CountDownLatch(1)
    }

    fun pass() {
        entered.countDown()
        released.await(30, TimeUnit.SECONDS)
    }

    /** Waits until a check waits at the gate. */
    fun awaitEntered() = check(entered.await(10, TimeUnit.SECONDS)) { "No check reached the gate." }

    fun release() = released.countDown()
}

/** How often the NAME check ran per resource, counted by the check itself. */
internal object NameCheckRuns {
    private val runs = ConcurrentHashMap<ResourceId, AtomicInteger>()

    fun ran(resource: ResourceId) {
        runs.computeIfAbsent(resource) { AtomicInteger() }.incrementAndGet()
    }

    fun snapshot(): Map<ResourceId, Int> = runs.mapValues { it.value.get() }

    /** The resources whose NAME check ran since [before], with how often. */
    fun since(before: Map<ResourceId, Int>): Map<ResourceId, Int> =
        snapshot().mapValues { (resource, count) -> count - (before[resource] ?: 0) }.filterValues { it > 0 }
}

/** A provider whose registration fails to link a class it needs. */
internal object UnlinkableChecks : RealmCheckProvider {
    override fun RealmChecks.register(): Unit = throw NoClassDefFoundError("com/example/Missing")
}

/** The test definitions with [RerunChecks], or with [providers] instead. */
internal fun rerunCatalog(providers: TestCheckProviders = checksOf(30, RerunChecks)) =
    DefinitionCatalog(TEST_DEFINITIONS, providers = providers)

/** Runs [test] on a Realm of [seed] whose own check runtime runs the checks of [catalog] and has settled. */
internal suspend fun reruns(
    seed: Map<ResourceId, AuthoringRecord>,
    catalog: DefinitionCatalog = rerunCatalog(),
    storage: MemoryAuthoringStorage = MemoryAuthoringStorage(AuthoringSeed(seed)),
    test: suspend RealmFixture.() -> Unit,
) {
    RerunGate.reset()
    RealmFixture.of(catalog, seed, storage).use { realm ->
        realm.checks
        realm.settle()
        realm.test()
    }
}

/** The label of one check instance: the check, and for an each check the resource, as "name@first". */
internal val CheckInstanceId.label: String
    get() =
        RerunCheck.entries[rule.localIndex].let { check ->
            if (check.each) "${check.name.lowercase()}@${location.resource.value}" else check.name.lowercase()
        }

/** The labels of these instances. */
internal fun Collection<CheckInstanceId>.labels(): Set<String> = mapTo(sortedSetOf()) { it.label }

/** How often the graph computed each check instance so far, by label. */
internal fun RealmFixture.runsByLabel(): Map<String, Long> = graphRuns.checkRuns().mapKeys { it.key.label }

/** The labels of the check instances the graph computed again since [before], once every pass has settled. */
internal suspend fun RealmFixture.rerunLabelsSince(before: Map<CheckInstanceId, Long>): Set<String> {
    settle()
    return graphRuns.checkRuns().grewFrom(before).labels()
}

/** The current findings of the instance labelled [label]. */
internal fun RealmFixture.findingsOf(label: String): FindingSet = checks.findings().single { it.ticket.instance.label == label }

/** Every reported message by the label of the instance that reported it. */
internal fun RealmFixture.reportedByLabel(): Set<Pair<String, String>> =
    checks.findings().flatMapTo(sortedSetOf(compareBy({ it.first }, { it.second }))) { set ->
        set.findings.map { set.ticket.instance.label to it.message }
    }

/** The failure codes of the instance's failed outcome; empty when it did not fail. */
internal val FindingSet.failureCodes: List<String>
    get() = (outcome as? CheckOutcome.FailedWrapper)?.value.orEmpty().map { it.code }

/** Whether this evidence holds a fact about which resources exist. */
internal val List<EditExpectation>.holdsResourceIds: Boolean get() = any { it is EditExpectation.ResourceIdsWrapper }

/** The locations whose values this evidence holds. */
internal fun List<EditExpectation>.valueLocations(): List<ValueLocation> =
    filterIsInstance<EditExpectation.ValueWrapper>().map {
        it.value.at
    }

/** Sets [resource]'s count to [count]. */
internal fun recount(
    resource: ResourceId,
    count: Int,
) = EditIntent.createSetValue(at = location(resource, "count"), value = DataValue.integer(BigInteger.valueOf(count.toLong())))

/** Sets [resource]'s numbers, a field no check reads, to one number. */
internal fun renumber(resource: ResourceId): EditIntent =
    EditIntent.createSetValue(
        at = location(resource, "numbers"),
        value = checkNotNull(record(numbers = listOf("one" to 1)).valueAt(ValuePath.root.field("numbers"))),
    )

/** Creates [resource] as a test resource named [name]. */
internal fun create(
    resource: ResourceId,
    name: String = "valid",
) = EditIntent.createCreateResource(id = resource, record = record(name = name))

/** The saved view as the realm reads it now. */
internal val RealmFixture.currentView: AuthoringView get() = views.read { it }

/** The messages and evidence of each instance a captured check of [view] gives, by label. A lease must hold [view]. */
internal suspend fun RealmFixture.capturedByLabel(view: AuthoringView): Map<String, Pair<List<String>, List<EditExpectation>>> =
    checks.evaluateCapture(view).results.associate { result ->
        result.ticket.instance.label to (result.findings.map { it.message } to result.expectations)
    }

/** The live findings and evidence of each instance, by label, in the shape [capturedByLabel] gives. */
internal fun RealmFixture.liveByLabel(): Map<String, Pair<List<String>, List<EditExpectation>>> =
    checks.findings().associate { set -> set.ticket.instance.label to (set.findings.map { it.message } to set.expectations) }

/** Every finding set's catalog generation. */
internal fun RealmFixture.findingGenerations(): Set<String> = checks.findings().mapTo(sortedSetOf()) { it.ticket.catalog.value }
