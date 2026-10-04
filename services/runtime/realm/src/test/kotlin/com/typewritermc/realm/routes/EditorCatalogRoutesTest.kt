package com.typewritermc.realm.routes

import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.PreparedCreation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
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
                val source = SnapshotRealmEditorCatalogSource(catalogs, chunkSize = 32)
                RouteFixture { contracts, _, _ ->
                    communicatorRoutes { EditorCatalogRoutes(source, UnusedInitialization, contracts).register(this) }
                }.use { fixture ->
                    val fetch =
                        fixture.request(
                            "editor.catalog.fetch",
                            CatalogFetchRequest(expectedGeneration = null, transferId = "route_catalog"),
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

                    val initial = (fetch as CatalogFetchResult.ChunkWrapper).value
                    val updates =
                        fixture.transport.actions
                            .filterIsInstance<FakeMessageTransport.Action.Publish>()
                            .filter {
                                it.message.address.value ==
                                    "service.from.realm.organization.organization.realm.editor.catalog.fetch.route_catalog"
                            }.map {
                                (
                                    CatalogFetchResult.serializer.fromBytes(
                                        it.message.payload.toByteArray(),
                                    ) as CatalogFetchResult.ChunkWrapper
                                ).value.transfer
                            }
                    val chunks = listOf(initial.transfer) + updates
                    chunks.map { it.index } shouldBe chunks.indices.toList()
                    chunks.size shouldBe initial.transfer.chunkCount
                    val snapshot =
                        skirout.editor.v1.catalog.EditorCatalogWireSnapshot.serializer.fromBytes(
                            chunks
                                .map { it.payload.toByteArray() }
                                .fold(byteArrayOf()) { combined, bytes -> combined + bytes },
                        )
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
    override suspend fun prepare(request: InitializationRequest): PreparedCreation = error("Not used")
}
