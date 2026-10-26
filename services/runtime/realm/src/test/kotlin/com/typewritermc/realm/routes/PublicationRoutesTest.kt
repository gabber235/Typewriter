package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledChanged
import com.typewritermc.protocol.transport.generated.authoringCompiledQuery
import com.typewritermc.protocol.transport.generated.authoringCompiledStatusQuery
import com.typewritermc.protocol.transport.generated.authoringPublicationQuery
import com.typewritermc.protocol.transport.generated.authoringPublish
import com.typewritermc.realm.publication.CompiledArtifactProducerRegistry
import com.typewritermc.realm.publication.CompiledRootStatuses
import com.typewritermc.realm.publication.PublicationFixture
import com.typewritermc.realm.publication.ResourceGraphArtifactProducer
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompilationStatusSelection
import skirout.editor.v1.compiled_content.CompiledContentChanged
import skirout.editor.v1.compiled_content.CompiledResourceState
import skirout.editor.v1.compiled_content.CompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusRequest
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse
import skirout.editor.v1.compiled_content.QueryPublishedContentRequest
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationCandidateId
import skirout.editor.v1.publication.PublishAuthoringRequest
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.publication.QueryPublicationViewRequest
import skirout.editor.v1.publication.QueryPublicationViewResponse
import skirout.editor.v1.type_catalog.InputToken
import skirout.kernel.v1.resource_id.ResourceId

val PublicationRoutesTest by testSuite {
    test("review returns one identified view and obsolete queries return its current identity") {
        runTest {
            withPublicationRoutes { publication, wire ->
                publication.publisher.refresh()
                val reviewed = publication.publisher.views.value

                wire
                    .call(RealmRouteScope::authoringPublicationQuery, QueryPublicationViewRequest(expected = reviewed.id))
                    .shouldBeInstanceOf<QueryPublicationViewResponse.ViewWrapper>()
                    .value shouldBe reviewed

                publication.update("Later saved content")
                publication.publisher.refresh()
                wire
                    .call(RealmRouteScope::authoringPublicationQuery, QueryPublicationViewRequest(expected = reviewed.id))
                    .shouldBeInstanceOf<QueryPublicationViewResponse.ViewChangedErrorWrapper>()
                    .value.current shouldBe publication.publisher.views.value.id
                publication.results.latestReport() shouldBe null
                publication.blobRequests shouldBe 0
            }
        }
    }

    test("publishing the reviewed candidate activates it and announces the new compiled content") {
        runTest {
            withPublicationRoutes { publication, wire ->
                publication.publisher.refresh()

                val activated =
                    wire
                        .call(RealmRouteScope::authoringPublish, PublishAuthoringRequest(candidate = publication.ready().candidate))
                        .shouldBeInstanceOf<PublishAuthoringResponse.ActivatedWrapper>()
                        .value

                activated.publication shouldBe publication.results.selected()?.publication
                wire.events(RealmRouteScope::authoringCompiledChanged) shouldBe
                    listOf(CompiledContentChanged(generation = publication.views.read { it.catalog.generation }))
            }
        }
    }

    test("publishing again without saved changes reports no changes") {
        runTest {
            withPublicationRoutes { publication, wire ->
                publication.publisher.refresh()
                val released = publication.ready().candidate
                val activated = publication.release()
                publication.publisher.refresh()

                wire.call(RealmRouteScope::authoringPublish, PublishAuthoringRequest(candidate = released)) shouldBe
                    PublishAuthoringResponse.NO_CHANGES
                publication.results.latestReport()?.id shouldBe activated.publication
            }
        }
    }

    test("publishing a candidate other than the reviewed one is refused with the current view and starts nothing") {
        runTest {
            withPublicationRoutes { publication, wire ->
                publication.publisher.refresh()
                val stale = publication.ready().candidate
                publication.update("Later saved content")
                publication.publisher.refresh()
                val current = publication.publisher.views.value.id

                for (candidate in listOf(PublicationCandidateId(value = ""), stale)) {
                    wire
                        .call(RealmRouteScope::authoringPublish, PublishAuthoringRequest(candidate = candidate))
                        .shouldBeInstanceOf<PublishAuthoringResponse.CandidateChangedErrorWrapper>()
                        .value.current shouldBe current
                }
                publication.results.latestReport() shouldBe null
            }
        }
    }

    test("publishing while the engine implementation changes is blocked with the reason and selects nothing") {
        runTest {
            withPublicationRoutes { publication, wire ->
                publication.publisher.refresh()
                publication.onStore = { publication.engineInputs = EngineImplementationInputs(token = InputToken(value = "changed")) }

                wire
                    .call(RealmRouteScope::authoringPublish, PublishAuthoringRequest(candidate = publication.ready().candidate))
                    .shouldBeInstanceOf<PublishAuthoringResponse.BlockedErrorWrapper>()
                    .value.first.details.code shouldBe "engine_inputs_changed"
                publication.results.selected() shouldBe null
            }
        }
    }

    test("the compiled content query answers absent before any publication and the selected publication after one") {
        runTest {
            withPublicationRoutes { publication, wire ->
                wire.call(RealmRouteScope::authoringCompiledQuery, QueryPublishedContentRequest()) shouldBe
                    QueryPublishedContentResponse.createAbsent()

                val released = publication.release()

                wire
                    .call(RealmRouteScope::authoringCompiledQuery, QueryPublishedContentRequest())
                    .shouldBeInstanceOf<QueryPublishedContentResponse.ContentWrapper>()
                    .value shouldBe released.content
            }
        }
    }

    test("the compiled status query reports each supplied root, in root order, as active in the selected publication or not compiled") {
        runTest {
            withPublicationRoutes { publication, wire ->
                val released = publication.release()
                val other = CompilationRoot(projection = publication.root.projection, resource = ResourceId(value = "other"))

                wire
                    .call(
                        RealmRouteScope::authoringCompiledStatusQuery,
                        QueryCompiledResourceStatusRequest(
                            selection = CompilationStatusSelection.SuppliedRootsWrapper(setOf(publication.root, other)),
                        ),
                    ).shouldBeInstanceOf<QueryCompiledResourceStatusResponse.SuccessWrapper>()
                    .value.statuses shouldBe
                    listOf(
                        CompiledResourceStatus(root = other, state = CompiledResourceState.NOT_COMPILED),
                        CompiledResourceStatus(root = publication.root, state = CompiledResourceState.ActiveWrapper(released.publication)),
                    )
            }
        }
    }

    test("the compiled status query refuses a supplied root without a projection") {
        runTest {
            withPublicationRoutes { publication, wire ->
                val invalid = CompilationRoot(projection = CompilationProjectionId(value = ""), resource = publication.root.resource)

                wire
                    .call(
                        RealmRouteScope::authoringCompiledStatusQuery,
                        QueryCompiledResourceStatusRequest(selection = CompilationStatusSelection.SuppliedRootsWrapper(setOf(invalid))),
                    ).shouldBeInstanceOf<QueryCompiledResourceStatusResponse.InternalErrorWrapper>()
            }
        }
    }
}

/** Runs [test] against the publication, compiled content and compiled status routes of one [PublicationFixture]. */
private suspend fun withPublicationRoutes(test: suspend (PublicationFixture, RouteFixture) -> Unit) {
    val publication = PublicationFixture()
    try {
        val statuses = CompiledRootStatuses(CompiledArtifactProducerRegistry(listOf(ResourceGraphArtifactProducer)), publication.results)
        RouteFixture { address, _ ->
            communicatorRoutes {
                PublicationRoutes(publication.publisher, address).register(this)
                EditorCompiledContentRoutes(publication.results, address).register(this)
                EditorCompiledResourceStatusRoutes(publication.views, statuses, address).register(this)
            }
        }.use { wire -> test(publication, wire) }
    } finally {
        publication.close()
    }
}
