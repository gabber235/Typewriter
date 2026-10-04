package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.checking.TEST_TYPE
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.record
import com.typewritermc.realm.checking.tokensFor
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
import com.typewritermc.realm.search.IndexedAuthoringSearchResult
import com.typewritermc.realm.search.IndexedSelectorFilter
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.SearchAuthoringRequest
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.authoring.SearchFacetId
import skirout.editor.v1.authoring.SearchFacetRequest
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.SnapshotId as SkirSnapshotId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse

val AuthoringSearchRoutesTest by testSuite {
    test("authoring search route returns typed subjects and readable descriptors") {
        runTest {
            val resource = ResourceId("book")
            val authored = record(name = "Readable Book")
            val catalog = TestCatalogLease()
            val snapshots =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(
                        snapshot = SnapshotId("realm:0"),
                        resources = mapOf(resource to authored),
                        inputTokens = tokensFor(mapOf(resource to authored), catalog.generation),
                        resourceDefinitions = mapOf(resource to ResourceDefinitionId("book")),
                    ),
                )
            val repository = RecordingSearchRepository()
            try {
                RouteFixture { contracts, _, _ ->
                    communicatorRoutes {
                        AuthoringSearchRoutes(repository, snapshots, contracts).register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture.request(
                            "editor.authoring.search",
                            searchRequest(catalog.generation, resource),
                            SearchAuthoringRequest.serializer,
                            SearchAuthoringResponse.serializer,
                        ) as SearchAuthoringResponse.SuccessWrapper

                    repository.receivedSnapshot shouldBe SnapshotId("realm:0")
                    repository.receivedQuery shouldBe "readable"
                    repository.receivedContexts shouldBe setOf(resource)
                    repository.receivedRoots shouldBe setOf(TEST_TYPE)
                    repository.receivedTarget shouldBe TypeUse.Named(TEST_TYPE)
                    repository.receivedSelectors shouldBe
                        IndexedSelectorFilter.Match(SearchSelectorId("kind"), "book")

                    val hit = response.value.hits.single()
                    hit.resource.value shouldBe resource.value
                    hit.definition.value shouldBe "book"
                    SkirAuthoringValueCodec.decode(hit.subject.content).getOrThrow() shouldBe authored
                    SkirDataValueCodec.decode(hit.subject.descriptor).getOrThrow() shouldBe
                        DataValue.StringValue("Readable Book")
                    SkirTypeCodec.decode(hit.context.actualType).getOrThrow() shouldBe TypeUse.Scalar(ScalarKind.Text)
                    SkirDataValueCodec.decode(hit.context.payload).getOrThrow() shouldBe
                        DataValue.StringValue("book Readable Book")
                    response.value.facets
                        .single()
                        .suggestions shouldBe listOf("Book")
                    response.value.facets
                        .single()
                        .accepted shouldBe listOf("book")
                    response.value.facets
                        .single()
                        .rejected shouldBe listOf("missing")
                }
            } finally {
                snapshots.close()
            }
        }
    }

    test("authoring search route rejects a changed durable snapshot") {
        runTest {
            val resource = ResourceId("book")
            val authored = record(name = "Readable Book")
            val catalog = TestCatalogLease()
            val snapshots =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(
                        snapshot = SnapshotId("realm:0"),
                        resources = mapOf(resource to authored),
                        inputTokens = tokensFor(mapOf(resource to authored), catalog.generation),
                        resourceDefinitions = mapOf(resource to ResourceDefinitionId("book")),
                    ),
                )
            try {
                RouteFixture { contracts, _, _ ->
                    communicatorRoutes {
                        AuthoringSearchRoutes(SnapshotChangedSearchRepository, snapshots, contracts).register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture.request(
                            "editor.authoring.search",
                            searchRequest(catalog.generation, resource),
                            SearchAuthoringRequest.serializer,
                            SearchAuthoringResponse.serializer,
                        ) as SearchAuthoringResponse.InvalidWrapper

                    response.value.diagnostics
                        .single()
                        .code shouldBe "snapshot_changed"
                }
            } finally {
                snapshots.close()
            }
        }
    }
}

private fun searchRequest(
    generation: CatalogGeneration,
    context: ResourceId,
): SearchAuthoringRequest {
    val target = SkirTypeCodec.encode(TypeUse.Named(TEST_TYPE)).getOrThrow() as SkirTypeUse.NamedWrapper
    return SearchAuthoringRequest(
        generation = SkirCatalogGeneration(value = generation.value),
        snapshot = SkirSnapshotId(value = "realm:0"),
        query =
            RealmSearchQuery(
                normalizedQuery = "readable",
                selectors = listOf(RealmSearchSelector(selectorId = "kind", key = "Kind", value = "book")),
                selectorExpression = null,
                terms = listOf("readable"),
            ),
        roots = listOf(target.value.definition),
        contexts = listOf(SkirResourceId(value = context.value)),
        target = target.value,
        facets =
            listOf(
                SearchFacetRequest(
                    facetId = SearchFacetId(value = "kind"),
                    partial = "b",
                    validate = listOf("book", "missing"),
                ),
            ),
    )
}

private class RecordingSearchRepository : AuthoringSearchRepository {
    var receivedSnapshot: SnapshotId? = null
    var receivedQuery: String? = null
    var receivedContexts: Set<ResourceId>? = null
    var receivedRoots: Set<TypeDefinitionId>? = null
    var receivedTarget: TypeUse.Named? = null
    var receivedSelectors: IndexedSelectorFilter? = null

    override fun search(
        snapshot: SnapshotId,
        catalog: CheckedCatalog,
        query: String,
        contexts: Set<ResourceId>,
        selectors: IndexedSelectorFilter,
        roots: Set<TypeDefinitionId>,
        target: TypeUse.Named?,
        limit: Int,
    ): IndexedAuthoringSearchResult {
        receivedSnapshot = snapshot
        receivedQuery = query
        receivedContexts = contexts
        receivedRoots = roots
        receivedTarget = target
        receivedSelectors = selectors
        return IndexedAuthoringSearchResult.Ready(
            listOf(
                IndexedAuthoringSearchCandidate(
                    resource = ResourceId("book"),
                    definition = ResourceDefinitionId("book"),
                    record = record(name = "stale indexed content"),
                    text = "book Readable Book",
                    ownerPath = emptyList(),
                    selectors = mapOf(SearchSelectorId("kind") to setOf("Book")),
                ),
            ),
        )
    }
}

private data object SnapshotChangedSearchRepository : AuthoringSearchRepository {
    override fun search(
        snapshot: SnapshotId,
        catalog: CheckedCatalog,
        query: String,
        contexts: Set<ResourceId>,
        selectors: IndexedSelectorFilter,
        roots: Set<TypeDefinitionId>,
        target: TypeUse.Named?,
        limit: Int,
    ): IndexedAuthoringSearchResult = IndexedAuthoringSearchResult.SnapshotChanged
}
