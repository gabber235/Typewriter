package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.TEST_TYPE
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.record
import com.typewritermc.realm.checking.tokensFor
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
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
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse

val AuthoringSearchRoutesTest by testSuite {
    test("authoring search route returns typed subjects and readable descriptors") {
        runTest {
            val resource = ResourceId("book")
            val authored = record(name = "Readable Book")
            val catalog = TestCatalogLease()
            val snapshots =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(
                        resources = mapOf(resource to authored),
                        resourceDefinitions =
                            mapOf(resource to ResourceDefinitionId("book")),
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

                    repository.receivedGeneration shouldBe catalog.generation
                    repository.receivedQuery shouldBe "readable"
                    repository.receivedContexts shouldBe setOf(resource)
                    repository.receivedRoots shouldBe setOf(TEST_TYPE)
                    repository.receivedTarget shouldBe TypeUse.Named(TEST_TYPE)
                    val hit = response.value.hits.single()
                    hit.resource.value shouldBe resource.value
                    hit.definition.value shouldBe "book"
                    SkirAuthoringValueCodec.decode(hit.subject.content).getOrThrow() shouldBe authored
                    SkirDataValueCodec.decode(hit.subject.descriptor).getOrThrow() shouldBe
                        DataValue.StringValue("Readable Book")
                    SkirTypeCodec.decode(hit.context.actualType).getOrThrow() shouldBe TypeUse.Scalar(ScalarKind.Text)
                    SkirDataValueCodec.decode(hit.context.payload).getOrThrow() shouldBe
                        DataValue.StringValue("book Readable Book")
                }
            } finally {
                snapshots.close()
            }
        }
    }

    test("authoring search route rejects a changed catalog") {
        runTest {
            val resource = ResourceId("book")
            val authored = record(name = "Readable Book")
            val catalog = TestCatalogLease()
            val snapshots =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(
                        resources = mapOf(resource to authored),
                        resourceDefinitions =
                            mapOf(resource to ResourceDefinitionId("book")),
                    ),
                )
            try {
                RouteFixture { contracts, _, _ ->
                    communicatorRoutes {
                        AuthoringSearchRoutes(RecordingSearchRepository(), snapshots, contracts).register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture.request(
                            "editor.authoring.search",
                            searchRequest(CatalogGeneration("old"), resource),
                            SearchAuthoringRequest.serializer,
                            SearchAuthoringResponse.serializer,
                        ) as SearchAuthoringResponse.CatalogChangedWrapper

                    response.value.actualGeneration.value shouldBe catalog.generation.value
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
        query = "readable",
        roots = listOf(target.value.definition),
        contexts = listOf(SkirResourceId(value = context.value)),
        target = target.value,
    )
}

private class RecordingSearchRepository : AuthoringSearchRepository {
    var receivedGeneration: CatalogGeneration? = null
    var receivedQuery: String? = null
    var receivedContexts: Set<ResourceId>? = null
    var receivedRoots: Set<TypeDefinitionId>? = null
    var receivedTarget: TypeUse.Named? = null

    override fun search(
        view: com.typewritermc.realm.authoring.AuthoringView,
        query: String,
        contexts: Set<ResourceId>,
        roots: Set<TypeDefinitionId>,
        target: TypeUse.Named?,
        limit: Int,
    ): List<IndexedAuthoringSearchCandidate> {
        receivedGeneration = view.catalog.generation
        receivedQuery = query
        receivedContexts = contexts
        receivedRoots = roots
        receivedTarget = target
        return listOf(
            IndexedAuthoringSearchCandidate(
                ResourceId("book"),
                ResourceDefinitionId("book"),
                record(name = "stale indexed content"),
                "book Readable Book",
            ),
        )
    }
}
