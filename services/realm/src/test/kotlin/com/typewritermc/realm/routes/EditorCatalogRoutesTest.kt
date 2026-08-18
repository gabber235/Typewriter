package com.typewritermc.realm.routes

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogGeneration
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.WatchEditorCatalogRequest

val EditorCatalogRoutesTest by testSuite {
    test("production catalog source returns typed unavailable diagnostics") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "editor.catalog.fetch",
                        emptyCatalogRequest(),
                        CatalogFetchRequest.serializer,
                        CatalogFetchResult.serializer,
                    )

                val unavailable = response as CatalogFetchResult.UnavailableWrapper
                unavailable.value.single().message shouldBe "Realm editor catalog source is unavailable"
            }
        }
    }

    test("routes use the injected catalog source") {
        runTest {
            val source = FakeRealmEditorCatalogSource()
            RouteFixture(editorCatalog = source).use { fixture ->
                val fetch =
                    fixture.request(
                        "editor.catalog.fetch",
                        emptyCatalogRequest(),
                        CatalogFetchRequest.serializer,
                        CatalogFetchResult.serializer,
                    )
                val watch =
                    fixture.request(
                        "editor.catalog.invalidate",
                        WatchEditorCatalogRequest(),
                        WatchEditorCatalogRequest.serializer,
                        CatalogWatchUpdate.serializer,
                    )
                val invalidation =
                    fixture
                        .publishedTo("editor.catalog.invalidate", CatalogWatchUpdate.serializer)
                        .single() as CatalogWatchUpdate.InvalidatedWrapper

                (fetch as CatalogFetchResult.SuccessWrapper).value.generation.value shouldBe "fake"
                (watch as CatalogWatchUpdate.InitialWrapper).value.value shouldBe "fake"
                invalidation.value.generation.value shouldBe "next"
            }
        }
    }
}

private class FakeRealmEditorCatalogSource : RealmEditorCatalogSource {
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult =
        CatalogFetchResult.createSuccess(
            generation = CatalogGeneration(value = "fake"),
            typeDefinitions = emptyList(),
            presentationDefinitions = emptyList(),
            conversions = emptyList(),
            realmActionDefinitions = emptyList(),
            subtypeResults = emptyList(),
            diagnostics = emptyList(),
        )

    override suspend fun watch(
        request: WatchEditorCatalogRequest,
        invalidations: RealmEditorCatalogInvalidationPublisher,
    ): CatalogWatchUpdate {
        invalidations.publish(
            CatalogWatchUpdate.createInvalidated(
                generation = CatalogGeneration(value = "next"),
                reason = "test",
            ),
        )
        return CatalogWatchUpdate.createInitial(value = "fake")
    }
}

private fun emptyCatalogRequest() =
    CatalogFetchRequest(
        expectedGeneration = null,
        requestedTypes = emptyList(),
        presentationIds = emptyList(),
        conversionIds = emptyList(),
        realmActionIds = emptyList(),
        subtypeQueries = emptyList(),
    )
