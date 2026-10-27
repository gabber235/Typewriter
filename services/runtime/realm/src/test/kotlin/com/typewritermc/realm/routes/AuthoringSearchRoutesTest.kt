package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringSearch
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.record
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
import skirout.kernel.v1.resource_id.ResourceId

val AuthoringSearchRoutesTest by testSuite {
    val book = ResourceId(value = "book")
    val removed = ResourceId(value = "removed")

    test("a search hit shows the saved record while the index still holds older content, and skips deleted resources") {
        runTest {
            withSearch(book, removed) { wire ->
                val saved = resources.getValue(book)

                val hits =
                    wire
                        .call(
                            RealmRouteScope::authoringSearch,
                            SearchAuthoringRequest(
                                generation = generation,
                                query = "readable",
                                roots = listOf(TEST_TYPE),
                                contexts = listOf(book),
                                target = TEST_TYPE.namedUse(),
                            ),
                        ).shouldBeInstanceOf<SearchAuthoringResponse.SuccessWrapper>()
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
            withSearch(book, removed) { wire ->
                wire
                    .call(
                        RealmRouteScope::authoringSearch,
                        SearchAuthoringRequest(
                            generation = CatalogGeneration(value = "previous"),
                            query = "readable",
                            roots = listOf(TEST_TYPE),
                            contexts = listOf(book),
                            target = TEST_TYPE.namedUse(),
                        ),
                    ).shouldBeInstanceOf<SearchAuthoringResponse.CatalogChangedErrorWrapper>()
                    .value.actualGeneration shouldBe generation
            }
        }
    }

    test("a search with invalid type data is refused as invalid_search") {
        runTest {
            withSearch(book, removed) { wire ->
                wire
                    .call(
                        RealmRouteScope::authoringSearch,
                        SearchAuthoringRequest(
                            generation = generation,
                            query = "readable",
                            roots = listOf(TEST_TYPE),
                            contexts = listOf(ResourceId(value = "")),
                            target = TEST_TYPE.namedUse(),
                        ),
                    ).shouldBeInstanceOf<SearchAuthoringResponse.InvalidErrorWrapper>()
                    .value.diagnostics
                    .map { it.code } shouldBe listOf("invalid_search")
            }
        }
    }
}
