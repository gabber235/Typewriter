package com.typewritermc.realm.routes

import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.Diagnostic
import com.typewritermc.engine.toSkir
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledChanged
import com.typewritermc.protocol.transport.generated.authoringPublicationQuery
import com.typewritermc.protocol.transport.generated.authoringPublicationWatch
import com.typewritermc.protocol.transport.generated.authoringPublish
import com.typewritermc.realm.checking.toWire
import com.typewritermc.realm.compiler.DiagnosticEvidence
import com.typewritermc.realm.compiler.PublicationBlocker
import com.typewritermc.realm.compiler.PublicationBlockers
import com.typewritermc.realm.compiler.PublicationNotice
import com.typewritermc.realm.compiler.PublicationResult
import com.typewritermc.realm.compiler.PublicationState
import com.typewritermc.realm.compiler.PublicationStatus
import com.typewritermc.realm.compiler.PublicationView
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.compiled_content.CompiledContentChanged
import skirout.editor.v1.publication.PublicationDiagnosticDetails
import skirout.editor.v1.publication.PublicationPendingReview
import skirout.editor.v1.publication.PublicationViewChanged
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.publication.QueryPublicationViewResponse
import skirout.editor.v1.publication.WatchPublicationResponse
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.publication.DiagnosticEvidence as SkirDiagnosticEvidence
import skirout.editor.v1.publication.PublicationBlocker as WirePublicationBlocker
import skirout.editor.v1.publication.PublicationBlockers as WirePublicationBlockers
import skirout.editor.v1.publication.PublicationNotice as WirePublicationNotice
import skirout.editor.v1.publication.PublicationStatus as WirePublicationStatus
import skirout.editor.v1.publication.PublicationView as WirePublicationView

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
                        if (attempt.state == PublicationState.Complete) {
                            call.communicator
                                .publish(
                                    address.authoringCompiledChanged,
                                    address,
                                    CompiledContentChanged(
                                        generation =
                                            CatalogGeneration(value = attempt.catalog.value),
                                    ),
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
                    QueryPublicationViewResponse.ViewWrapper(view.toWire())
                }
            }
        }
}

internal fun PublicationView.changed() = PublicationViewChanged(current = id)

internal fun PublicationView.toWire() = WirePublicationView(id = id, status = status.toWire(evidence))

private fun PublicationStatus.toWire(evidence: Map<DiagnosticId, DiagnosticEvidence>): WirePublicationStatus =
    when (this) {
        is PublicationStatus.Empty -> {
            WirePublicationStatus.createEmpty(notices = notices.map { it.toWire(evidence) })
        }

        is PublicationStatus.Current -> {
            WirePublicationStatus.createCurrent(
                selected =
                    PublicationId(value = selected.value),
                notices = notices.map { it.toWire(evidence) },
            )
        }

        is PublicationStatus.Ready -> {
            WirePublicationStatus.createReady(
                candidate = candidate,
                baseline = baseline,
                changes = changes,
                notices =
                    notices.map {
                        it.toWire(evidence)
                    },
            )
        }

        is PublicationStatus.Blocked -> {
            WirePublicationStatus.createBlocked(
                baseline = baseline,
                blockers = blockers.toWire(evidence),
                notices =
                    notices.map {
                        it.toWire(evidence)
                    },
                confirmedChanges = confirmedChanges,
                pendingRoots = pendingRoots.map { it.toSkir() },
            )
        }

        is PublicationStatus.Checking -> {
            WirePublicationStatus.createChecking(baseline = baseline, findings = findings.map { it.toWire() })
        }

        is PublicationStatus.Publishing -> {
            WirePublicationStatus.createPublishing(
                publication =
                    PublicationId(value = publication.value),
                phase = phase,
                releasing = releasing,
                next =
                    PublicationPendingReview(
                        findings =
                            next.findings.map {
                                it.toWire()
                            },
                        confirmedChanges = next.confirmedChanges,
                        pendingRoots = next.pendingRoots.map { it.toSkir() },
                        blockers = next.blockers.map { it.toWire(evidence) },
                        notices = next.notices.map { it.toWire(evidence) },
                    ),
            )
        }

        is PublicationStatus.Unavailable -> {
            WirePublicationStatus.createUnavailable(
                baseline = baseline,
                failure = failure,
                findings = findings.map { it.toWire() },
            )
        }
    }

private fun PublicationBlockers.toWire(evidence: Map<DiagnosticId, DiagnosticEvidence> = emptyMap()) =
    WirePublicationBlockers(
        first = first.toWire(evidence),
        additional = additional.map { it.toWire(evidence) },
    )

private fun PublicationBlocker.toWire(evidence: Map<DiagnosticId, DiagnosticEvidence> = emptyMap()) =
    WirePublicationBlocker(details = diagnostic.details(evidence[diagnostic.id]))

private fun PublicationNotice.toWire(evidence: Map<DiagnosticId, DiagnosticEvidence>): WirePublicationNotice =
    when (this) {
        is PublicationNotice.Information -> {
            WirePublicationNotice.InformationWrapper(
                diagnostic.details(evidence[diagnostic.id]),
            )
        }

        is PublicationNotice.Warning -> {
            WirePublicationNotice.WarningWrapper(
                diagnostic.details(evidence[diagnostic.id]),
            )
        }
    }

private fun Diagnostic.details(evidence: DiagnosticEvidence?): PublicationDiagnosticDetails {
    val encoded = SkirTypeCodec.encode(this).getOrThrow()
    return PublicationDiagnosticDetails(
        id = encoded.id,
        origin = encoded.origin,
        code = encoded.code,
        message = encoded.message,
        primary = encoded.primary,
        related = encoded.related,
        evidence =
            evidence?.let { captured ->
                SkirDiagnosticEvidence(
                    catalog =
                        CatalogGeneration(value = captured.catalog.value),
                    expectations = captured.expectations.map { SkirAuthoringOperationCodec.encode(it).getOrThrow() },
                )
            },
    )
}

private fun PublicationResult.toWire(): PublishAuthoringResponse =
    when (this) {
        PublicationResult.Publishing -> {
            PublishAuthoringResponse.PUBLISHING
        }

        is PublicationResult.Activated -> {
            PublishAuthoringResponse.createActivated(
                publication =
                    PublicationId(value = publication.value),
            )
        }

        is PublicationResult.Blocked -> {
            PublishAuthoringResponse.BlockedErrorWrapper(blockers.toWire())
        }

        is PublicationResult.Interrupted -> {
            PublishAuthoringResponse.InterruptedErrorWrapper(
                PublicationId(value = publication.value),
            )
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
