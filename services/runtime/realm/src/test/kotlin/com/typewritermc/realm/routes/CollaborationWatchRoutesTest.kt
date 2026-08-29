package com.typewritermc.realm.routes

import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.engine.CompiledManifest
import com.typewritermc.engine.ContentDigest
import com.typewritermc.library.BookId
import com.typewritermc.library.LibraryName
import com.typewritermc.loader.api.RealmServiceAddress
import com.typewritermc.realm.compiler.SurrealCompiledContentRepository
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.realm.repository.BookCreation
import com.typewritermc.realm.repository.CreateBooksCommand
import com.typewritermc.realm.repository.LibraryBatchResult
import com.typewritermc.realm.repository.SurrealLibraryBatchRepository
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.library.v2.authoring.WatchCompiledContentRequest
import skirout.library.v2.authoring.WatchCompiledContentResponse
import skirout.library.v2.authoring.WatchLibraryInvalidationsRequest
import skirout.library.v2.authoring.WatchLibraryInvalidationsResponse

val CollaborationWatchRoutesTest by testSuite {
    test("library invalidation watch starts at the committed collaboration revision") {
        runTest {
            RouteFixture().use { fixture ->
                SurrealLibraryBatchRepository(fixture.repositories.database)
                    .createBooks(
                        CreateBooksCommand(
                            BatchId("watch-revision-book"),
                            listOf(
                                BookCreation(
                                    BookId("watch-revision-book"),
                                    LibraryName("watch_revision_book"),
                                    Icon.parse("mdi:book"),
                                    Color(0u),
                                    emptyList(),
                                ),
                            ),
                        ),
                    ) as LibraryBatchResult.Success

                val response =
                    fixture.request(
                        "library.invalidate.watch.v2",
                        WatchLibraryInvalidationsRequest(),
                        WatchLibraryInvalidationsRequest.serializer,
                        WatchLibraryInvalidationsResponse.serializer,
                    ) as WatchLibraryInvalidationsResponse.InitialWrapper

                response.value.revision shouldBe 1
            }
        }
    }

    test("compiled content watch returns the active activation") {
        runTest {
            RouteFixture().use { fixture ->
                val manifest = compiledManifest()
                val activation = compiledActivation(manifest, 1)
                fixture.compiledContent.publish(manifest, emptyList(), activation) shouldBe true

                val response =
                    fixture.request(
                        "compiled.content.watch.v2",
                        WatchCompiledContentRequest(),
                        WatchCompiledContentRequest.serializer,
                        WatchCompiledContentResponse.serializer,
                    ) as WatchCompiledContentResponse.InitialWrapper

                response.value.activation?.activationRevision shouldBe 1
                response.value.activation?.manifestDigest shouldBe manifest.digest.value
            }
        }
    }

    test("activation publication and outbox insertion share the repository transaction") {
        runTest {
            RouteFixture().use { fixture ->
                val address = RealmServiceAddress("realm", "organization")
                val events = CompiledContentActivationEvents()
                events.configure(LibraryContracts(address), address)
                val content =
                    SurrealCompiledContentRepository(
                        fixture.repositories.database,
                        fixture.repositories.outbox,
                        events::encode,
                    )
                val manifest = compiledManifest()
                val activation = compiledActivation(manifest, 1)

                content.publish(manifest, emptyList(), activation) shouldBe true

                val pending = fixture.repositories.outbox.pending(10)
                pending.size shouldBe 1
                val update =
                    WatchCompiledContentResponse.serializer.fromBytes(
                        pending
                            .single()
                            .event.payload
                            .toByteArray(),
                    )
                (update as WatchCompiledContentResponse.ActivatedWrapper).value.activationRevision shouldBe 1
            }
        }
    }
}

private fun compiledManifest() =
    CompiledManifest(
        formatRevision = 1,
        digest = ContentDigest("a".repeat(64)),
        sourceRevision = "0",
        catalogRevision = "catalog:1",
        pages = emptyList(),
    )

private fun compiledActivation(
    manifest: CompiledManifest,
    revision: Long,
) = CompiledContentActivation(
    activationRevision = revision,
    manifestDigest = manifest.digest,
    manifest = CompiledBlobPointer(ContentDigest("b".repeat(64)), 1),
    shards = emptyList(),
)
