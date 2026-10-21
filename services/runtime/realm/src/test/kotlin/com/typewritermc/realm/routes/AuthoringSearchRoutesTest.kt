package com.typewritermc.realm.routes

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.TEST_TYPE
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.record
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.SearchAuthoringRequest
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

val AuthoringSearchRoutesTest by testSuite {
    test("authoring search route returns typed subjects and readable descriptors") {
        runTest {
            val resource = ResourceId("book")
            val authored = record(name = "Readable Book")
            val catalog = TestCatalogLease()
            val views =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(resources = mapOf(resource to authored)),
                )
            val repository = RecordingSearchRepository()
            try {
                RouteFixture { address, _ ->
                    communicatorRoutes {
                        AuthoringSearchRoutes(repository, views, address).register(this)
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
                    repository.receivedTarget shouldBe TEST_TYPE.namedUse()
                    val hit = response.value.hits.single()
                    hit.resource.value shouldBe resource.value
                    SkirAuthoringValueCodec.decode(hit.subject.content).getOrThrow() shouldBe authored
                    hit.context.actualType.requireValid() shouldBe ScalarKind.TEXT.use
                    hit.context.payload.requirePortable() shouldBe
                        DataValue.StringValueWrapper("book Readable Book")
                }
            } finally {
                views.close()
            }
        }
    }

    test("authoring search route rejects a changed catalog") {
        runTest {
            val resource = ResourceId("book")
            val authored = record(name = "Readable Book")
            val catalog = TestCatalogLease()
            val views =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(resources = mapOf(resource to authored)),
                )
            try {
                RouteFixture { address, _ ->
                    communicatorRoutes {
                        AuthoringSearchRoutes(RecordingSearchRepository(), views, address).register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture.request(
                            "editor.authoring.search",
                            searchRequest(CatalogGeneration("old"), resource),
                            SearchAuthoringRequest.serializer,
                            SearchAuthoringResponse.serializer,
                        ) as SearchAuthoringResponse.CatalogChangedErrorWrapper

                    response.value.actualGeneration.value shouldBe catalog.generation.value
                }
            } finally {
                views.close()
            }
        }
    }
}

private fun searchRequest(
    generation: CatalogGeneration,
    context: ResourceId,
): SearchAuthoringRequest =
    SearchAuthoringRequest(
        generation = SkirCatalogGeneration(value = generation.value),
        query = "readable",
        roots = listOf(TEST_TYPE),
        contexts = listOf(SkirResourceId(value = context.value)),
        target = TEST_TYPE.namedUse(),
    )

private class RecordingSearchRepository : AuthoringSearchRepository {
    var receivedGeneration: CatalogGeneration? = null
    var receivedQuery: String? = null
    var receivedContexts: Set<ResourceId>? = null
    var receivedRoots: Set<TypeDefinitionId>? = null
    var receivedTarget: NamedTypeUse? = null

    override fun search(
        view: com.typewritermc.realm.authoring.AuthoringView,
        query: String,
        contexts: Set<ResourceId>,
        roots: Set<TypeDefinitionId>,
        target: NamedTypeUse?,
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
                record(name = "stale indexed content"),
                "book Readable Book",
            ),
        )
    }
}
