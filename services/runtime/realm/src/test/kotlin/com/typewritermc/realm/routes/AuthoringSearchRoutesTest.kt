package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringSearch
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.SearchAuthoringRequest
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

private val book = ResourceId(value = "book")
private val removed = ResourceId(value = "removed")

/** An index that has not caught up: it still holds an older version of the book and a resource deleted since. */
private object StaleIndex : AuthoringSearchRepository {
    override fun search(
        view: AuthoringView,
        query: String,
        contexts: Set<ResourceId>,
        roots: Set<TypeDefinitionId>,
        target: NamedTypeUse?,
        limit: Int,
    ): List<IndexedAuthoringSearchCandidate> =
        listOf(
            IndexedAuthoringSearchCandidate(book, record(name = "Draft Book"), "book Draft Book"),
            IndexedAuthoringSearchCandidate(removed, record(name = "Removed"), "removed Removed"),
        )
}

val AuthoringSearchRoutesTest by testSuite {
    test("a search hit shows the saved record while the index still holds older content, and skips deleted resources") {
        runTest {
            withSearch { wire ->
                val saved = resources.getValue(book)

                val hits =
                    wire
                        .call(RealmRouteScope::authoringSearch, search(generation))
                        .shouldBeInstanceOf<SearchAuthoringResponse.SuccessWrapper>()
                        .value.hits

                hits.map { it.resource } shouldBe listOf(book)
                hits
                    .single()
                    .subject.content
                    .requireValid() shouldBe saved
                hits
                    .single()
                    .context.payload
                    .requirePortable() shouldBe DataValue.StringValueWrapper("book Draft Book")
            }
        }
    }

    test("a search against an older catalog is answered with the current generation") {
        runTest {
            withSearch { wire ->
                wire
                    .call(RealmRouteScope::authoringSearch, search(CatalogGeneration(value = "previous")))
                    .shouldBeInstanceOf<SearchAuthoringResponse.CatalogChangedErrorWrapper>()
                    .value.actualGeneration shouldBe generation
            }
        }
    }

    test("a search with invalid type data is refused as invalid_search") {
        runTest {
            withSearch { wire ->
                wire
                    .call(RealmRouteScope::authoringSearch, search(generation).copy(contexts = listOf(ResourceId(value = ""))))
                    .shouldBeInstanceOf<SearchAuthoringResponse.InvalidErrorWrapper>()
                    .value.diagnostics
                    .map { it.code } shouldBe listOf("invalid_search")
            }
        }
    }
}

/** Runs [test] against the search route of a Realm that has saved the book under its current name, over [StaleIndex]. */
private suspend fun withSearch(test: suspend RealmFixture.(RouteFixture) -> Unit) =
    RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), mapOf(book to record(name = "Readable Book"))).use { realm ->
        RouteFixture { address, _ -> communicatorRoutes { AuthoringSearchRoutes(StaleIndex, realm.views, address).register(this) } }
            .use { wire -> realm.test(wire) }
    }

private fun search(generation: CatalogGeneration) =
    SearchAuthoringRequest(
        generation = generation,
        query = "readable",
        roots = listOf(TEST_TYPE),
        contexts = listOf(book),
        target = TEST_TYPE.namedUse(),
    )
