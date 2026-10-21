package com.typewritermc.realm.routes

import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.Diagnostic
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.realm.checking.toWire
import com.typewritermc.realm.compiler.DiagnosticEvidence
import com.typewritermc.realm.compiler.PublicationActivationPhase
import com.typewritermc.realm.compiler.PublicationBaseline
import com.typewritermc.realm.compiler.PublicationBlocker
import com.typewritermc.realm.compiler.PublicationBlockers
import com.typewritermc.realm.compiler.PublicationCandidateId
import com.typewritermc.realm.compiler.PublicationChange
import com.typewritermc.realm.compiler.PublicationDelta
import com.typewritermc.realm.compiler.PublicationFailure
import com.typewritermc.realm.compiler.PublicationNotice
import com.typewritermc.realm.compiler.PublicationResult
import com.typewritermc.realm.compiler.PublicationState
import com.typewritermc.realm.compiler.PublicationStatus
import com.typewritermc.realm.compiler.PublicationView
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compiled_content.CompiledContentChanged
import skirout.editor.v1.publication.PublicationDiagnosticDetails
import skirout.editor.v1.publication.PublicationPendingReview
import skirout.editor.v1.publication.PublicationViewChanged
import skirout.editor.v1.publication.PublicationViewId
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.publication.QueryPublicationViewResponse
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.compilation_root.CompilationRoot as SkirCompilationRoot
import skirout.editor.v1.publication.DiagnosticEvidence as SkirDiagnosticEvidence
import skirout.editor.v1.publication.PublicationActivationPhase as SkirPublicationActivationPhase
import skirout.editor.v1.publication.PublicationBaseline as WirePublicationBaseline
import skirout.editor.v1.publication.PublicationBlocker as WirePublicationBlocker
import skirout.editor.v1.publication.PublicationBlockers as WirePublicationBlockers
import skirout.editor.v1.publication.PublicationCandidateId as SkirPublicationCandidateId
import skirout.editor.v1.publication.PublicationChange as WirePublicationChange
import skirout.editor.v1.publication.PublicationDelta as SkirPublicationDelta
import skirout.editor.v1.publication.PublicationFailure as WirePublicationFailure
import skirout.editor.v1.publication.PublicationNotice as WirePublicationNotice
import skirout.editor.v1.publication.PublicationResult as WirePublicationResult
import skirout.editor.v1.publication.PublicationStatus as WirePublicationStatus
import skirout.editor.v1.publication.PublicationView as WirePublicationView

/** Queries one immutable review view and accepts only its issued candidate. */
internal class PublicationRoutes(
    private val publisher: RealmPublicationCoordinator,
    private val contracts: EditorContracts,
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.publishAuthoring) { call ->
                if (call.request.candidate.value
                        .isBlank()
                ) {
                    return@unary PublishAuthoringResponse.ResultWrapper(
                        WirePublicationResult.CandidateChangedWrapper(publisher.views.value.changed()),
                    )
                }
                val result =
                    publisher.publish(
                        PublicationCandidateId(call.request.candidate.value),
                    ) { attempt ->
                        if (attempt.state == PublicationState.Complete) {
                            call.communicator
                                .publish(
                                    contracts.compiledContentChanged,
                                    address,
                                    CompiledContentChanged(
                                        generation =
                                            CatalogGeneration(value = attempt.catalog.value),
                                    ),
                                ).requirePublished()
                        }
                    }
                PublishAuthoringResponse.ResultWrapper(result.toWire())
            }
            watch(contracts.watchPublication) { publisher.views.value.changed() }
            unary(contracts.queryPublicationView) { call ->
                val view = publisher.views.value
                if (view.id.value != call.request.expected.value) {
                    QueryPublicationViewResponse.ViewChangedErrorWrapper(view.changed())
                } else {
                    QueryPublicationViewResponse.ViewWrapper(view.toWire())
                }
            }
        }
}

internal fun PublicationView.changed() = PublicationViewChanged(current = wireId())

private fun PublicationView.wireId() = PublicationViewId(value = id.value)

internal fun PublicationView.toWire() = WirePublicationView(id = wireId(), status = status.toWire(evidence))

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
                candidate =
                    SkirPublicationCandidateId(value = candidate.value),
                baseline = baseline.toWire(),
                changes = changes.toWire(),
                notices =
                    notices.map {
                        it.toWire(evidence)
                    },
            )
        }

        is PublicationStatus.Blocked -> {
            WirePublicationStatus.createBlocked(
                baseline = baseline.toWire(),
                blockers = blockers.toWire(evidence),
                notices =
                    notices.map {
                        it.toWire(evidence)
                    },
                confirmedChanges = confirmedChanges.map { it.toWire() },
                pendingRoots = pendingRoots.map { it.toWire() },
            )
        }

        is PublicationStatus.Checking -> {
            WirePublicationStatus.createChecking(baseline = baseline.toWire(), findings = findings.map { it.toWire() })
        }

        is PublicationStatus.Publishing -> {
            WirePublicationStatus.createPublishing(
                publication =
                    PublicationId(value = publication.value),
                phase =
                    when (phase) {
                        PublicationActivationPhase.Storing -> {
                            SkirPublicationActivationPhase.STORING
                        }

                        PublicationActivationPhase.Activating -> {
                            SkirPublicationActivationPhase.ACTIVATING
                        }
                    },
                releasing = releasing.toWire(),
                next =
                    PublicationPendingReview(
                        findings =
                            next.findings.map {
                                it.toWire()
                            },
                        confirmedChanges = next.confirmedChanges.map { it.toWire() },
                        pendingRoots = next.pendingRoots.map { it.toWire() },
                        blockers = next.blockers.map { it.toWire(evidence) },
                        notices = next.notices.map { it.toWire(evidence) },
                    ),
            )
        }

        is PublicationStatus.Unavailable -> {
            WirePublicationStatus.createUnavailable(
                baseline = baseline.toWire(),
                failure = failure.toWire(),
                findings = findings.map { it.toWire() },
            )
        }
    }

private fun PublicationBaseline.toWire(): WirePublicationBaseline =
    when (this) {
        PublicationBaseline.Initial -> {
            WirePublicationBaseline.INITIAL
        }

        is PublicationBaseline.Selected -> {
            WirePublicationBaseline.SelectedWrapper(
                PublicationId(value = publication.value),
            )
        }
    }

private fun PublicationFailure.toWire(): WirePublicationFailure =
    when (this) {
        is PublicationFailure.EvaluationInterrupted -> {
            WirePublicationFailure.EvaluationInterruptedWrapper(
                message,
            )
        }

        is PublicationFailure.ImplementationUnavailable -> {
            WirePublicationFailure
                .ImplementationUnavailableWrapper(
                    message,
                )
        }

        is PublicationFailure.PublicationInterrupted -> {
            WirePublicationFailure.PublicationInterruptedWrapper(
                PublicationId(value = publication.value),
            )
        }
    }

private fun PublicationChange.toWire(): WirePublicationChange =
    when (this) {
        is PublicationChange.RootAdded -> WirePublicationChange.RootAddedWrapper(root.toWire())
        is PublicationChange.RootUpdated -> WirePublicationChange.RootUpdatedWrapper(root.toWire())
        is PublicationChange.RootRemoved -> WirePublicationChange.RootRemovedWrapper(root.toWire())
        PublicationChange.RequirementsChanged -> WirePublicationChange.REQUIREMENTS_CHANGED
    }

private fun CompilationRoot.toWire() =
    SkirCompilationRoot(
        projection =
            CompilationProjectionId(value = projection.value),
        resource =
            ResourceId(value = resource.value),
    )

private fun PublicationDelta.toWire() =
    SkirPublicationDelta(
        first = first.toWire(),
        additional = additional.map { it.toWire() },
    )

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

private fun PublicationResult.toWire(): WirePublicationResult =
    when (this) {
        PublicationResult.Publishing -> {
            WirePublicationResult.PUBLISHING
        }

        is PublicationResult.Activated -> {
            WirePublicationResult.createActivated(
                publication =
                    PublicationId(value = publication.value),
            )
        }

        is PublicationResult.Blocked -> {
            WirePublicationResult.BlockedWrapper(blockers.toWire())
        }

        is PublicationResult.Interrupted -> {
            WirePublicationResult.InterruptedWrapper(
                PublicationId(value = publication.value),
            )
        }

        PublicationResult.NoChanges -> {
            WirePublicationResult.NO_CHANGES
        }

        is PublicationResult.CandidateChanged -> {
            WirePublicationResult.CandidateChangedWrapper(
                PublicationViewChanged(
                    current =
                        PublicationViewId(value = view.value),
                ),
            )
        }
    }
