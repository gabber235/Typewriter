package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledChanged
import com.typewritermc.protocol.transport.generated.authoringPublicationQuery
import com.typewritermc.protocol.transport.generated.authoringPublicationWatch
import com.typewritermc.protocol.transport.generated.authoringPublish
import com.typewritermc.realm.compiler.PublicationResult
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.compiled_content.CompiledContentChanged
import skirout.editor.v1.publication.PublicationState
import skirout.editor.v1.publication.PublicationView
import skirout.editor.v1.publication.PublicationViewChanged
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.publication.QueryPublicationViewResponse
import skirout.editor.v1.publication.WatchPublicationResponse

/** Queries one immutable review view and accepts only its issued candidate. */
internal class PublicationRoutes(
    private val publisher: RealmPublicationCoordinator,
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.authoringPublish) { call ->
                if (call.request.candidate.value
                        .isBlank()
                ) {
                    return@unary PublishAuthoringResponse.CandidateChangedErrorWrapper(publisher.views.value.changed())
                }
                val result =
                    publisher.publish(call.request.candidate) { attempt ->
                        if (attempt.state == PublicationState.COMPLETE) {
                            call.communicator
                                .publish(
                                    address.authoringCompiledChanged,
                                    address,
                                    CompiledContentChanged(generation = attempt.catalog),
                                ).requirePublished()
                        }
                    }
                result.toWire()
            }
            watch(address.authoringPublicationWatch) { WatchPublicationResponse.ViewChangedWrapper(publisher.views.value.changed()) }
            unary(address.authoringPublicationQuery) { call ->
                val view = publisher.views.value
                if (view.id.value != call.request.expected.value) {
                    QueryPublicationViewResponse.ViewChangedErrorWrapper(view.changed())
                } else {
                    QueryPublicationViewResponse.ViewWrapper(view)
                }
            }
        }
}

internal fun PublicationView.changed() = PublicationViewChanged(current = id)

private fun PublicationResult.toWire(): PublishAuthoringResponse =
    when (this) {
        PublicationResult.Publishing -> {
            PublishAuthoringResponse.PUBLISHING
        }

        is PublicationResult.Activated -> {
            PublishAuthoringResponse.createActivated(publication = publication)
        }

        is PublicationResult.Blocked -> {
            PublishAuthoringResponse.BlockedErrorWrapper(blockers)
        }

        is PublicationResult.Interrupted -> {
            PublishAuthoringResponse.InterruptedErrorWrapper(publication)
        }

        PublicationResult.NoChanges -> {
            PublishAuthoringResponse.NO_CHANGES
        }

        is PublicationResult.CandidateChanged -> {
            PublishAuthoringResponse.CandidateChangedErrorWrapper(
                PublicationViewChanged(current = view),
            )
        }
    }
