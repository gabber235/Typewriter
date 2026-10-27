package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.editorCatalogFetch
import com.typewritermc.protocol.transport.generated.editorCatalogWatch
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.catalog.WatchEditorCatalogResponse
import skirout.editor.v1.type_catalog.CatalogGeneration

val EditorCatalogRoutesTest by testSuite {
    test("catalog fetch and watch over the wire report the installed generation") {
        runTest {
            withCatalogRoutes("route_catalog") { wire ->
                wire
                    .call(RealmRouteScope::editorCatalogFetch, CatalogFetchRequest(expectedGeneration = null))
                    .shouldBeInstanceOf<CatalogFetchResult.CatalogWrapper>()
                    .value.generation shouldBe CatalogGeneration(value = "route_catalog")
                wire
                    .watch(RealmRouteScope::editorCatalogWatch, WatchEditorCatalogRequest())
                    .shouldBeInstanceOf<WatchEditorCatalogResponse.InvalidatedWrapper>()
                    .value.generation shouldBe CatalogGeneration(value = "route_catalog")
            }
        }
    }

    test("a catalog fetch expecting an older generation over the wire is answered with the installed one") {
        runTest {
            withCatalogRoutes("route_catalog") { wire ->
                wire
                    .call(
                        RealmRouteScope::editorCatalogFetch,
                        CatalogFetchRequest(expectedGeneration = CatalogGeneration(value = "previous")),
                    ).shouldBeInstanceOf<CatalogFetchResult.GenerationChangedErrorWrapper>()
                    .value shouldBe CatalogGeneration(value = "route_catalog")
            }
        }
    }
}
