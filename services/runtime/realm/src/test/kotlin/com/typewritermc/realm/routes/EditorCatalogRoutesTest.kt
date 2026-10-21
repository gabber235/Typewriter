package com.typewritermc.realm.routes

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogInvalidated
import skirout.editor.v1.catalog.WatchEditorCatalogRequest

val EditorCatalogRoutesTest by testSuite {
    test("routes use one injected captured catalog source") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("route_catalog")
            try {
                val source = RetainedRealmEditorCatalogSource(catalogs)
                RouteFixture { contracts, _, _ ->
                    communicatorRoutes { EditorCatalogRoutes(source, UnusedInitialization, contracts).register(this) }
                }.use { fixture ->
                    val fetch =
                        fixture.request(
                            "editor.catalog.fetch",
                            CatalogFetchRequest(expectedGeneration = null),
                            CatalogFetchRequest.serializer,
                            CatalogFetchResult.serializer,
                        )
                    val watch =
                        fixture.request(
                            "editor.catalog.invalidate",
                            WatchEditorCatalogRequest(),
                            WatchEditorCatalogRequest.serializer,
                            CatalogInvalidated.serializer,
                        )

                    val snapshot = (fetch as CatalogFetchResult.CatalogWrapper).value
                    snapshot.generation.value shouldBe "route_catalog"
                    watch.generation.value shouldBe "route_catalog"
                }
            } finally {
                catalogs.close()
            }
        }
    }
}

private data object UnusedInitialization : InitializationRuntime {
    override suspend fun step(operation: com.typewritermc.authoring.PreparationOperation): com.typewritermc.authoring.PreparationStep =
        error("Not used")
}
