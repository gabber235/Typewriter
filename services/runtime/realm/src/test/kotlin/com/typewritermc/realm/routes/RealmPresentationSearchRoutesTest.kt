package com.typewritermc.realm.routes

import com.typewritermc.authoring.complete
import com.typewritermc.operations.MoveToOwner
import com.typewritermc.operations.OperationResourceOption
import com.typewritermc.realm.TestRealmStructure
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.toTemplate
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeTemplate

val RealmPresentationSearchRoutesTest by testSuite {
    test("switching from an operation search cancels its stream even when the next capability is unavailable") {
        runTest {
            RealmCatalogStore().use { catalogs ->
                CoreOperationsFixture().use { fixture ->
                    catalogs.installTestCatalog("generation")
                    val operation = PendingSearchSource(backgroundScope)
                    val source = CapabilityRealmPresentationSearchSource(backgroundScope, catalogs, fixture.views, operation)
                    val candidates = fixture.candidateSearch(MoveToOwner, "destination")
                    source.watch(validSearchRequest().copy(capabilityId = CapabilityId(value = candidates.value))) { }
                    runCurrent()
                    operation.active.toSet() shouldBe setOf("search")

                    val replacement = source.watch(validSearchRequest()) { }
                    runCurrent()

                    (replacement as RealmPresentationSearchUpdate.SnapshotWrapper).value.status shouldBe RealmPresentationSearchStatus.ERROR
                    operation.active.toSet() shouldBe emptySet()
                    source.cancel("search") shouldBe false
                }
            }
        }
    }

    test("an operation field search offers its declared candidates filtered by the query, never others") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val source = OperationRealmPresentationSearchSource(backgroundScope, fixture.views)

                suspend fun search(query: String): List<OperationResourceOption> {
                    val published = mutableListOf<RealmPresentationSearchUpdate>()
                    source.watch(fixture.candidateRequest(MoveToOwner, "destination", query, "graph-entry"), published::add)
                    runCurrent()
                    val snapshot = (published.single() as RealmPresentationSearchUpdate.SnapshotWrapper).value
                    snapshot.status shouldBe RealmPresentationSearchStatus.READY
                    return snapshot.values.map(fixture::option)
                }

                search("").map { it.id.value }.toSet() shouldBe setOf("canvas", "timeline")
                search("page 2").map { it.id.value } shouldBe listOf("timeline")
                search("nothing").map { it.id.value } shouldBe emptyList()
            }
        }
    }

    test("an operation field search is unavailable for a selection the operation does not apply to") {
        runTest {
            CoreOperationsFixture().use { fixture ->
                val source = OperationRealmPresentationSearchSource(backgroundScope, fixture.views)
                val response =
                    source.watch(
                        fixture.candidateRequest(MoveToOwner, "destination", "", TestRealmStructure.root.value).copy(
                            capabilityId = CapabilityId(value = "unknown"),
                        ),
                    ) { }
                (response is RealmPresentationSearchUpdate.UnavailableWrapper) shouldBe true
            }
        }
    }

    test("unavailable source returns a correlated typed diagnostic") {
        runTest {
            val response = UnavailableRealmPresentationSearchSource().watch(validSearchRequest()) { }

            val unavailable = response as RealmPresentationSearchUpdate.UnavailableWrapper
            unavailable.value.subscriptionId shouldBe "search"
            unavailable.value.diagnostics
                .single()
                .message shouldBe "Realm presentation search source is unavailable"
        }
    }

    test("source receives the complete request and can publish replacement snapshots") {
        runTest {
            val source = FakeRealmPresentationSearchSource()
            val request = validSearchRequest()
            val published = mutableListOf<RealmPresentationSearchUpdate>()

            val initial = source.watch(request, published::add) as RealmPresentationSearchUpdate.SnapshotWrapper
            val update = published.single() as RealmPresentationSearchUpdate.SnapshotWrapper

            source.request shouldBe request
            initial.value.status shouldBe RealmPresentationSearchStatus.LOADING
            update.value.subscriptionId shouldBe request.subscriptionId
            update.value.status shouldBe RealmPresentationSearchStatus.READY
            update.value.values shouldContainExactly listOf(DataValue.StringValueWrapper("Alex"))
            update.value.guidance shouldContainExactly listOf("Search by player name")
        }
    }

    test("invalid request is rejected before a source can start") {
        val invalid =
            validSearchRequest().copy(
                capabilityId = CapabilityId(value = ""),
                payload = DataValue.UNKNOWN,
                resultType = TypeTemplate.UNKNOWN,
            )

        val response = requireNotNull(invalidRealmPresentationSearchRequest(invalid)) as RealmPresentationSearchUpdate.SnapshotWrapper

        response.value.status shouldBe RealmPresentationSearchStatus.ERROR
        response.value.diagnostics.size shouldBe 3
    }

    test("mismatched source subscriptions become correlated error snapshots") {
        val response = invalidRealmPresentationSearchResponse("search") as RealmPresentationSearchUpdate.SnapshotWrapper

        response.value.subscriptionId shouldBe "search"
        response.value.status shouldBe RealmPresentationSearchStatus.ERROR
        response.value.diagnostics
            .single()
            .message shouldBe "Realm presentation search response used a different subscription ID"
    }
}

private class PendingSearchSource(
    private val scope: CoroutineScope,
) : RealmPresentationSearchSource {
    val active = mutableSetOf<String>()
    private val jobs = mutableMapOf<String, Job>()

    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate {
        jobs[request.subscriptionId] =
            scope.launch {
                active += request.subscriptionId
                try {
                    awaitCancellation()
                } finally {
                    active -= request.subscriptionId
                }
            }
        return RealmPresentationSearchUpdate.createSnapshot(
            subscriptionId = request.subscriptionId,
            status = RealmPresentationSearchStatus.LOADING,
            values = emptyList(),
            guidance = emptyList(),
            diagnostics = emptyList(),
        )
    }

    override fun cancel(subscriptionId: String): Boolean =
        jobs.remove(subscriptionId)?.let {
            it.cancel()
            true
        } ?: false
}

private class FakeRealmPresentationSearchSource : RealmPresentationSearchSource {
    var request: RealmPresentationSearchRequest? = null

    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate {
        this.request = request
        updates.publish(
            RealmPresentationSearchUpdate.createSnapshot(
                subscriptionId = request.subscriptionId,
                status = RealmPresentationSearchStatus.READY,
                values = listOf(DataValue.StringValueWrapper("Alex")),
                guidance = listOf("Search by player name"),
                diagnostics = emptyList(),
            ),
        )
        return RealmPresentationSearchUpdate.createSnapshot(
            subscriptionId = request.subscriptionId,
            status = RealmPresentationSearchStatus.LOADING,
            values = emptyList(),
            guidance = emptyList(),
            diagnostics = emptyList(),
        )
    }

    override fun cancel(subscriptionId: String): Boolean = false
}

private fun validSearchRequest() =
    RealmPresentationSearchRequest(
        subscriptionId = "search",
        generation = CatalogGeneration(value = "generation"),
        capabilityId = CapabilityId(value = "capability"),
        payload = DataValue.StringValueWrapper("server"),
        resultType = TypeTemplate.ScalarWrapper(skirout.editor.v1.type_catalog.ScalarKind.TEXT),
        operationContext = null,
        query =
            RealmSearchQuery(
                normalizedQuery = "alex",
                terms = listOf("alex"),
                selectors = emptyList(),
                selectorExpression = null,
            ),
    )

/** A search over the candidates of [field] in the input of the operation object [operation], for dragging [subjects]. */
private fun CoreOperationsFixture.candidateRequest(
    operation: Any,
    field: String,
    query: String,
    vararg subjects: String,
) = validSearchRequest().copy(
    generation = CatalogGeneration(value = catalogGeneration()),
    capabilityId = CapabilityId(value = candidateSearch(operation, field).value),
    resultType =
        com.typewritermc.types.skir.SkirTypeCodec
            .encode(
                com.typewritermc.operations.OperationResourceOptionDefinition.use
                    .toTemplate(),
            ).getOrThrow(),
    operationContext = searchContext(*subjects),
    query = RealmSearchQuery(normalizedQuery = query, terms = listOf(query), selectors = emptyList(), selectorExpression = null),
)

/** Decodes one search result value as an operation resource option. */
private fun CoreOperationsFixture.option(value: DataValue): OperationResourceOption =
    views.read { root ->
        val checked =
            (root.catalog.checked.resolve(com.typewritermc.operations.OperationResourceOptionDefinition.use) as Resolution.Ready).value
        val complete =
            checked.complete(
                com.typewritermc.types.skir.SkirDataValueCodec
                    .decode(value)
                    .getOrThrow(),
            ) as com.typewritermc.authoring.CompletenessResult.Complete
        root.catalog.nativeBindings
            .bind(checked)
            .decode(complete.value) as OperationResourceOption
    }
