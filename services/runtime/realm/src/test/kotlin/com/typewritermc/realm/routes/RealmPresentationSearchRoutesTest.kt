@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.complete
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.operations.AnyResourceSubjects
import com.typewritermc.operations.LinkWithInput
import com.typewritermc.operations.LinkWithInputDefinition
import com.typewritermc.operations.LinkWithInputFields
import com.typewritermc.operations.MoveToOwner
import com.typewritermc.operations.OperationInput
import com.typewritermc.operations.OperationResourceOption
import com.typewritermc.operations.ResourceOperationSpecImpl
import com.typewritermc.operations.collectOperation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.fixtureGraphEntry
import com.typewritermc.testing.routes.fixtureGraphPage
import com.typewritermc.testing.routes.fixtureTimelinePage
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.requirePortable
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import com.typewritermc.types.type
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.operation.ResourceOperationId
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.search.RealmSearchSelectorOperator
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.TypeTemplate

/** An entry on a graph page, and the two other pages it can move to: "Page 1" with a graph layout and "Page 2" without. */
private val pages =
    setup("search-pages") {
        library {
            books.book("pages") {
                val entry =
                    pages.fixtureGraphPage("graph") {
                        name = "Page 0"
                        elements.fixtureGraphEntry("entry") { placement = GraphPlacement() }
                    }
                val canvas =
                    pages.fixtureGraphPage("canvas") {
                        name = "Page 1"
                        handle
                    }
                val timeline =
                    pages.fixtureTimelinePage("timeline") {
                        name = "Page 2"
                        handle
                    }
                Triple(entry, canvas, timeline)
            }
        }
    }

private val shelf = setup("shelf") { library { books.book("book") { handle } } }

/** An operation on tags whose target field has a candidate search; a book selection gets no search from it. */
private fun tagOnly(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, LinkWithInput>(
        origin,
        "fixture.TagOnly",
        ResourceTarget.type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.Typed(LinkWithInputDefinition.use),
        "Tag only",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            input { LinkWithInputFields.target { candidates { emptySequence() } } }
            prepare { }
        }
    }

val RealmPresentationSearchRoutesTest by testSuite {
    test("switching from an operation search cancels its stream even when the next capability is unavailable") {
        runTest {
            RealmCatalogStore().use { catalogs ->
                RealmFixture.core().use { realm ->
                    catalogs.installTestCatalog("generation")
                    val operation = PendingSearchSource(backgroundScope)
                    val source = CapabilityRealmPresentationSearchSource(backgroundScope, catalogs, realm.views, operation)
                    val candidates = realm.operations.candidateSearch(realm.operations.operation(MoveToOwner), "destination")
                    source.watch(validSearchRequest().copy(capabilityId = candidates)) { }
                    runCurrent()
                    operation.active.toSet() shouldBe setOf("search")

                    val replacement = source.watch(validSearchRequest()) { }
                    runCurrent()

                    (replacement as RealmPresentationSearchUpdate.SnapshotWrapper).value.status shouldBe
                        RealmPresentationSearchStatus.SEARCH_FAILED_ERROR
                    operation.active.toSet() shouldBe emptySet()
                    source.cancel("search") shouldBe false
                }
            }
        }
    }

    test("an operation field search offers its declared candidates filtered by the query, never others") {
        runTest {
            withSetup(pages, catalog = routeFixtureCatalog) { (entry, canvas, timeline) ->
                val source = OperationRealmPresentationSearchSource(backgroundScope, views)

                suspend fun search(query: String): List<ResourceId> {
                    val published = mutableListOf<RealmPresentationSearchUpdate>()
                    source.watch(candidateRequest(operations.operation(MoveToOwner), "destination", query, entry.resource), published::add)
                    runCurrent()
                    val snapshot = (published.single() as RealmPresentationSearchUpdate.SnapshotWrapper).value
                    snapshot.status shouldBe RealmPresentationSearchStatus.READY
                    return snapshot.values.map { option(it).id }
                }

                search("").toSet() shouldBe setOf(canvas.id, timeline.id)
                search("page 2") shouldBe listOf(timeline.id)
                search("nothing") shouldBe emptyList()
            }
        }
    }

    test("an operation field search is unavailable for a selection the operation does not apply to") {
        runTest {
            withSetup(shelf, catalog = RealmCatalog(operations = { origin -> listOf(tagOnly(origin)) })) { book ->
                val source = OperationRealmPresentationSearchSource(backgroundScope, views)
                val tagOnly = operations.operation("fixture.TagOnly")

                val response = source.watch(candidateRequest(tagOnly, "target", "", book.resource)) { }

                response
                    .shouldBeInstanceOf<RealmPresentationSearchUpdate.UnavailableErrorWrapper>()
                    .value.diagnostics
                    .map { it.message } shouldBe
                    listOf("The operation does not apply to the search selection.")
            }
        }
    }

    test("unavailable source returns a correlated typed diagnostic") {
        runTest {
            val response = UnavailableRealmPresentationSearchSource().watch(validSearchRequest()) { }

            val unavailable = response as RealmPresentationSearchUpdate.UnavailableErrorWrapper
            unavailable.value.subscriptionId shouldBe "search"
            unavailable.value.diagnostics
                .single()
                .message shouldBe "Realm presentation search source is unavailable"
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

        response.value.status shouldBe RealmPresentationSearchStatus.SEARCH_FAILED_ERROR
        response.value.diagnostics.map { it.message } shouldContainExactly
            listOf(
                "Realm search capability ID must not be blank",
                "Realm presentation search payload is missing",
                "Realm presentation search result type is missing",
            )
    }

    test("an unknown selector operator is rejected before a source can start") {
        val selector =
            RealmSearchSelectorExpression.createSelector(selectorId = "type", key = "type", value = "npc")
        val invalid =
            validSearchRequest().copy(
                query =
                    RealmSearchQuery.partial(
                        normalizedQuery = "alex",
                        selectors = listOf(RealmSearchSelector(selectorId = "type", key = "type", value = "npc")),
                        selectorExpression =
                            RealmSearchSelectorExpression.createBinary(
                                operator_ = RealmSearchSelectorOperator.UNKNOWN,
                                left = selector,
                                right = selector,
                            ),
                    ),
            )

        val response = requireNotNull(invalidRealmPresentationSearchRequest(invalid)) as RealmPresentationSearchUpdate.SnapshotWrapper

        response.value.status shouldBe RealmPresentationSearchStatus.SEARCH_FAILED_ERROR
        response.value.diagnostics
            .single()
            .message shouldBe "Realm search selector expression contains an unknown operator"
    }

    test("mismatched source subscriptions become correlated error snapshots") {
        val response = invalidRealmPresentationSearchResponse("search") as RealmPresentationSearchUpdate.SnapshotWrapper

        response.value.subscriptionId shouldBe "search"
        response.value.status shouldBe RealmPresentationSearchStatus.SEARCH_FAILED_ERROR
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
private fun RealmFixture.candidateRequest(
    operation: ResourceOperationId,
    field: String,
    query: String,
    vararg subjects: skirout.kernel.v1.resource_id.ResourceId,
) = validSearchRequest().copy(
    generation = views.read { it.catalog.generation },
    capabilityId = CapabilityId(value = operations.candidateSearch(operation, field).value),
    resultType =
        com.typewritermc.operations.OperationResourceOptionDefinition.use
            .toTemplate()
            .template,
    operationContext = operations.searchContext(*subjects),
    query = RealmSearchQuery(normalizedQuery = query, terms = listOf(query), selectors = emptyList(), selectorExpression = null),
)

/** Decodes one search result value as an operation resource option. */
private fun RealmFixture.option(value: DataValue): OperationResourceOption =
    views.read { root ->
        val checked =
            (root.catalog.checked.resolve(com.typewritermc.operations.OperationResourceOptionDefinition.use.use) as Resolution.Ready).value
        val complete =
            checked.complete(
                value.requirePortable(),
            ) as com.typewritermc.authoring.CompletenessResult.Complete
        root.catalog.nativeBindings
            .bind(checked)
            .decode(complete.value) as OperationResourceOption
    }
