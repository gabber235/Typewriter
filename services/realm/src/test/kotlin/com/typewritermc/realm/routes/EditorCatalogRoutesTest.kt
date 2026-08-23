package com.typewritermc.realm.routes

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogGeneration
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.element_catalog.ElementCatalogRequest
import skirout.editor.v1.element_catalog.ElementCatalogResult

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

    test("routes element catalog requests through the injected source") {
        runTest {
            val elements =
                RealmElementCatalogSource {
                    ElementCatalogResult.createSuccess(
                        generation = CatalogGeneration(value = "elements"),
                        entries = emptyList(),
                    )
                }
            RouteFixture(elementCatalog = elements).use { fixture ->
                val response =
                    fixture.request(
                        "editor.elements.fetch",
                        ElementCatalogRequest(expectedGeneration = null),
                        ElementCatalogRequest.serializer,
                        ElementCatalogResult.serializer,
                    )

                val success = response as ElementCatalogResult.SuccessWrapper
                success.value.generation.value shouldBe "elements"
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

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate =
        CatalogWatchUpdate.createInitial(value = "fake")
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
