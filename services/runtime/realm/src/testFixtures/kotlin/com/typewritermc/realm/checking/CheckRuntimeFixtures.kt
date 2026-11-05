@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.checking

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.of
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.checking.RealmChecks
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.check
import com.typewritermc.configuration.field
import com.typewritermc.expression.eq
import com.typewritermc.expression.isInstance
import com.typewritermc.expression.length
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.INT_USE
import com.typewritermc.realm.authoring.LIST_USE
import com.typewritermc.realm.authoring.SelectionPredicateEvaluator
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TEXT_USE
import com.typewritermc.realm.authoring.TestDraftType
import com.typewritermc.realm.authoring.ViewReadLimits
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.publication.AuthoringAcceptance
import com.typewritermc.realm.publication.CapturedAssessment
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.checksOf
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.named
import com.typewritermc.types.use
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.catalog.RuleDescriptor
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import kotlin.concurrent.thread

internal val REALM = ResourceId(value = "realm")

/**
 * Runs [test] on a Realm of [catalog] that starts with [seed] saved, and a check runtime over its views that runs
 * checks on [dispatcher] and whose findings committed replies carry. The runtime is closed before the Realm.
 */
internal suspend fun checking(
    catalog: DefinitionCatalog,
    seed: Map<ResourceId, AuthoringRecord>,
    dispatcher: CoroutineDispatcher,
    readLimits: ViewReadLimits = ViewReadLimits(),
    selectionPredicates: SelectionPredicateEvaluator = RealmSelectionPredicateEvaluator(),
    test: suspend (RealmFixture, RealmCheckRuntime) -> Unit,
) {
    RealmFixture.of(catalog, seed).use { realm ->
        val runtime = RealmCheckRuntime(realm.views, dispatcher, selectionPredicates = selectionPredicates, readLimits = readLimits)
        realm.findings = runtime::findings
        runtime.use { test(realm, it) }
    }
}

/** Loads the catalog, runs the checks the test scheduler holds, and waits until every check has ended. */
context(scope: TestScope)
internal suspend fun RealmCheckRuntime.settle() {
    reloadCatalog()
    scope.advanceUntilIdle()
    drain()
}

/** Commits [intent] and tells [runtime] about it, as the Realm does after every committed edit. */
internal suspend fun RealmFixture.commitChecked(
    runtime: RealmCheckRuntime,
    intent: EditIntent,
) {
    commit(intent).shouldBeCommitted()
    runtime.invalidateCurrent()
}

/** Renames [resource]. */
internal fun rename(
    resource: ResourceId,
    name: String,
) = EditIntent.createSetValue(at = location(resource, "name"), value = DataValue.StringValueWrapper(name))

/** Every published finding as the resource it points at and its message. */
internal fun RealmCheckRuntime.reported(): Set<Pair<ResourceId?, String>> =
    findings().flatMapTo(linkedSetOf()) { set -> set.findings.map { it.primary?.resource to it.message } }

/**
 * Runs [test] with an each check that reports test resources not named "valid" and a realm check that always reports,
 * on a Realm of [seed] whose checks run on the test scheduler and have settled.
 */
context(scope: TestScope)
internal suspend fun membership(
    seed: Map<ResourceId, AuthoringRecord>,
    test: suspend (RealmFixture, RealmCheckRuntime) -> Unit,
) {
    val provider =
        object : RealmCheckProvider {
            override fun RealmChecks.register() {
                each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                    check(read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))) { it == "valid" }
                        .error("Name is invalid.", draft.binding.location)
                }
                realm {
                    check(Availability.Available(false)) { it }.error("Realm is invalid.", ValueLocation.of(REALM))
                }
            }
        }
    val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = checksOf(5, provider))
    checking(catalog, seed, StandardTestDispatcher(scope.testScheduler)) { realm, runtime ->
        runtime.settle()
        test(realm, runtime)
    }
}

/** A realm check that always reports the Realm as invalid. */
internal object InvalidRealm : RealmCheckProvider {
    override fun RealmChecks.register() {
        realm {
            check(Availability.Available(false)) { it }.error("Realm is invalid.", ValueLocation.of(REALM))
        }
    }
}

/**
 * An each check over test resources that, while a resource is named "blocked", keeps running until [release] opens,
 * ignoring cancellation as provider code may.
 */
internal class BlockingCheck {
    val started = CountDownLatch(1)
    val release = CountDownLatch(1)
    private val provider =
        object : RealmCheckProvider {
            override fun RealmChecks.register() {
                each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                    val name = read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))
                    if ((name as? Availability.Available)?.value == "blocked") {
                        started.countDown()
                        release.await(10, TimeUnit.SECONDS)
                    }
                }
            }
        }
    val providers = checksOf(12, provider)
}

/**
 * One way a running worker gets cancelled: the subject starts named [seed], [cancel] runs after the catalog loaded,
 * [afterStart] once the blocked worker runs, and [stop] is what has to wait for the worker.
 */
internal class WorkerCancellation(
    val name: String,
    val seed: String,
    val cancel: suspend (RealmFixture, RealmCheckRuntime) -> Unit,
    val afterStart: suspend (RealmFixture, RealmCheckRuntime) -> Unit = { _, _ -> },
    val stop: (RealmCheckRuntime) -> Unit = { runtime ->
        runBlocking { runtime.drain() }
        runtime.close()
    },
)

/**
 * Runs [action] on its own thread and returns once that thread waits or ends, so everything [action] does before it
 * waits has happened. The returned function joins the thread and rethrows what [action] threw.
 */
internal fun waitingOn(action: () -> Unit): () -> Unit {
    val failure = AtomicReference<Throwable>()
    val waiting = setOf(Thread.State.WAITING, Thread.State.TIMED_WAITING, Thread.State.TERMINATED)
    val worker = thread(name = "check-runtime-stopper") { runCatching(action).onFailure(failure::set) }
    val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5)
    while (worker.state !in waiting) {
        check(System.nanoTime() < deadline) { "The stopping thread never waited." }
        Thread.onSpinWait()
    }
    return {
        worker.join(TimeUnit.SECONDS.toMillis(10))
        failure.get()?.let { throw it }
    }
}

/** Captures the saved authoring and assesses it for publication. */
internal suspend fun capturedAcceptance(
    store: AuthoringViewStore,
    runtime: RealmCheckRuntime,
): CapturedAssessment {
    val acceptance = AuthoringAcceptance(store, runtime)
    return acceptance.capture().use { acceptance.evaluate(it) }
}

/** A portable rule on the test resource's name that reports `name_rule` where [predicate] is false. */
internal fun portableNameRule(predicate: ExpressionNode): List<ConfigurationRecipe> {
    val origin = RuleOrigin(owner = TEST_TYPE, ordinal = 20)
    val path = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("name")))
    return listOf(
        ConfigurationRecipe(
            origin = origin,
            relativePath = path,
            representationCondition = RepresentationKind.TEXT,
            rules =
                listOf(
                    OwnedRule(
                        id = RuleId(origin = origin, localIndex = 0),
                        descriptor = RuleDescriptor(predicate = predicate),
                        diagnostic =
                            DiagnosticTemplate(
                                code = "name_rule",
                                message = "Name breaks the rule.",
                                severity = DiagnosticSeverity.ERROR,
                                targets = listOf(path),
                            ),
                    ),
                ),
        ),
    )
}

internal data class TestNativeResource(
    val name: String,
    val count: Int,
    val numbers: List<*>,
)

internal object TestResourceNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_TYPE
    override val provider = NativeBindingId(value = "test.resource")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.resource",
            nativeClass = TestNativeResource::class,
            fields =
                listOf(
                    GeneratedNativeField("name", { arguments.resolver.bind(TEXT_USE) }, TestNativeResource::name),
                    GeneratedNativeField("count", { arguments.resolver.bind(INT_USE) }, TestNativeResource::count),
                    GeneratedNativeField("numbers", { arguments.resolver.bind(LIST_USE.use) }, TestNativeResource::numbers),
                ),
            construct = { fields ->
                TestNativeResource(
                    name = fields.getValue("name") as String,
                    count = fields.getValue("count") as Int,
                    numbers = fields.getValue("numbers") as List<*>,
                )
            },
        )
}

internal class BlockingCaptureStore(
    private val delegate: com.typewritermc.realm.authoring.AuthoringViewStore,
    private val blockedCall: Int,
) : com.typewritermc.realm.authoring.AuthoringViewStore by delegate {
    private val calls = AtomicInteger()
    val entered = CountDownLatch(1)
    val release = CountDownLatch(1)

    override fun capture(): com.typewritermc.realm.authoring.AuthoringLease {
        if (calls.incrementAndGet() == blockedCall) {
            entered.countDown()
            release.await()
        }
        return delegate.capture()
    }
}

/** The rule predicate "the configured text is not empty", built from portable primitives. */
internal fun nameIsNotEmpty(): ExpressionNode =
    (
        com.typewritermc.expression
            .input<String>(ExpressionBindingId(value = "configured_value"))
            .length eq literal(0)
    ).not().toNode()

/** The rule predicate "the configured value is not text", which needs the catalog's type facts to evaluate. */
internal fun nameIsNotText(): ExpressionNode =
    com.typewritermc.expression
        .input<String>(ExpressionBindingId(value = "configured_value"))
        .isInstance(ScalarKind.TEXT.use)
        .not()
        .toNode()
