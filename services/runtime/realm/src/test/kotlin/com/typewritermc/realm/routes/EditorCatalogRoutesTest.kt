package com.typewritermc.realm.routes

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.type_catalog.CatalogGeneration

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
                (fetch as CatalogFetchResult.SuccessWrapper).value.generation.value shouldBe "fake"
                (watch as CatalogWatchUpdate.InitialWrapper).value.value shouldBe "fake"
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
            capabilityDefinitions = emptyList(),
            subtypeResults = emptyList(),
            diagnostics = emptyList(),
            elementEntries = emptyList(),
            pageEntries = emptyList(),
            pageDiagnostics = emptyList(),
        )

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate =
        CatalogWatchUpdate.createInitial(value = "fake")
}

private fun emptyCatalogRequest() =
    CatalogFetchRequest(
        expectedGeneration = null,
        requestedTypes = emptyList(),
        presentationIds = emptyList(),
        subtypeQueries = emptyList(),
    )
