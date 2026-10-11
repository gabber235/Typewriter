package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.realm.compiler.PublicationState
import com.typewritermc.realm.checking.toWire
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.communicator.transfer.BoundedByteTransferEncoder
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferPlan
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import okio.ByteString.Companion.toByteString
import skirout.editor.v1.publication.PublicationView as WirePublicationView
import skirout.editor.v1.publication.PublicationStatus as WirePublicationStatus
import skirout.editor.v1.publication.PublicationResult as WirePublicationResult
import skirout.editor.v1.publication.PublicationChange as WirePublicationChange
import skirout.editor.v1.publication.PublicationNotice as WirePublicationNotice
import skirout.editor.v1.publication.PublicationFailure as WirePublicationFailure
import skirout.editor.v1.publication.PublicationBaseline as WirePublicationBaseline
import skirout.editor.v1.publication.PublicationBlockers as WirePublicationBlockers
import skirout.editor.v1.publication.PublicationBlocker as WirePublicationBlocker
import skirout.editor.v1.publication.*

/** Queries one immutable review view and accepts only its issued candidate. */
internal class PublicationRoutes(
    private val publisher: RealmPublicationCoordinator,
    private val contracts: EditorContracts,
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) = with(builder) {
        unary(contracts.publishAuthoring) { call ->
            if (call.request.candidate.value.isBlank()) {
                return@unary PublishAuthoringResponse.ResultWrapper(WirePublicationResult.CandidateChangedWrapper(publisher.views.value.changed()))
            }
            val result = publisher.publish(com.typewritermc.realm.compiler.PublicationCandidateId(call.request.candidate.value)) { attempt ->
                if (attempt.state == PublicationState.Complete) {
                    call.communicator.publish(
                        contracts.compiledContentChanged, address,
                        skirout.editor.v1.compiled_content.CompiledContentChanged(
                            generation = skirout.editor.v1.type_catalog.CatalogGeneration(value = attempt.catalog.value),
                        ),
                    ).requirePublished()
                }
            }
            PublishAuthoringResponse.ResultWrapper(result.toWire())
        }
        watch(contracts.watchPublication) { publisher.views.value.changed() }
        watch(contracts.queryPublicationView) { call ->
            val view = publisher.views.value
            if (view.id.value != call.request.expected.value) return@watch QueryPublicationViewResponse.ChangedWrapper(view.changed())
            val bytes = WirePublicationView.serializer.toBytes(view.toWire()).toByteArray()
            when (val plan = BoundedByteTransferEncoder(nextTransferId = { call.request.transferId }).encode(bytes)) {
                is BoundedTransferPlan.Unavailable -> QueryPublicationViewResponse.UnavailableWrapper(
                    PublicationTransferUnavailable(view = view.wireId(), encodedSize = plan.encodedSize, maxEncodedSize = plan.maxEncodedSize),
                )
                is BoundedTransferPlan.Ready -> {
                    val chunks = plan.chunks.map { chunk ->
                        QueryPublicationViewResponse.ChunkWrapper(
                            PublicationViewChunk(
                                view = view.wireId(),
                                transfer = skirout.kernel.v1.bounded_transfer.BoundedTransferChunk(
                                    transferId = chunk.transferId, index = chunk.index, chunkCount = chunk.chunkCount,
                                    encodedSize = chunk.encodedSize, sha256 = chunk.sha256, payload = chunk.payload.toByteArray().toByteString(),
                                ),
                            ),
                        )
                    }
                    chunks.drop(1).forEach { call.publishUpdate(it).requirePublished() }
                    chunks.first()
                }
            }
        }
    }
}

internal fun com.typewritermc.realm.compiler.PublicationView.changed() = PublicationViewChanged(current = wireId())
private fun com.typewritermc.realm.compiler.PublicationView.wireId() = skirout.editor.v1.publication.PublicationViewId(value = id.value)
internal fun com.typewritermc.realm.compiler.PublicationView.toWire() = WirePublicationView(id = wireId(), status = status.toWire())

private fun com.typewritermc.realm.compiler.PublicationStatus.toWire(): WirePublicationStatus = when (this) {
    is com.typewritermc.realm.compiler.PublicationStatus.Empty -> WirePublicationStatus.createEmpty(notices = notices.map { it.toWire() })
    is com.typewritermc.realm.compiler.PublicationStatus.Current -> WirePublicationStatus.createCurrent(
        selected = skirout.editor.v1.type_catalog.PublicationId(value = selected.value), notices = notices.map { it.toWire() },
    )
    is com.typewritermc.realm.compiler.PublicationStatus.Ready -> WirePublicationStatus.createReady(
        candidate = skirout.editor.v1.publication.PublicationCandidateId(value = candidate.value), baseline = baseline.toWire(), changes = changes.toWire(), notices = notices.map { it.toWire() },
    )
    is com.typewritermc.realm.compiler.PublicationStatus.Blocked -> WirePublicationStatus.createBlocked(
        baseline = baseline.toWire(), blockers = blockers.toWire(), notices = notices.map { it.toWire() }, confirmedChanges = confirmedChanges.map { it.toWire() }, pendingRoots = pendingRoots.map { it.toWire() },
    )
    is com.typewritermc.realm.compiler.PublicationStatus.Checking -> WirePublicationStatus.createChecking(baseline = baseline.toWire(), findings = findings.map { it.toWire() })
    is com.typewritermc.realm.compiler.PublicationStatus.Publishing -> WirePublicationStatus.createPublishing(
        publication = skirout.editor.v1.type_catalog.PublicationId(value = publication.value),
        phase = when (phase) {
            com.typewritermc.realm.compiler.PublicationActivationPhase.Storing -> skirout.editor.v1.publication.PublicationActivationPhase.STORING
            com.typewritermc.realm.compiler.PublicationActivationPhase.Activating -> skirout.editor.v1.publication.PublicationActivationPhase.ACTIVATING
        },
        releasing = releasing.toWire(),
        next = skirout.editor.v1.publication.PublicationPendingReview(
            findings = next.findings.map { it.toWire() }, confirmedChanges = next.confirmedChanges.map { it.toWire() }, pendingRoots = next.pendingRoots.map { it.toWire() },
            blockers = next.blockers.map { WirePublicationBlocker(details = it.diagnostic.details()) }, notices = next.notices.map { it.toWire() },
        ),
    )
    is com.typewritermc.realm.compiler.PublicationStatus.Unavailable -> WirePublicationStatus.createUnavailable(baseline = baseline.toWire(), failure = failure.toWire(), findings = findings.map { it.toWire() })
}

private fun com.typewritermc.realm.compiler.PublicationBaseline.toWire(): WirePublicationBaseline = when (this) {
    com.typewritermc.realm.compiler.PublicationBaseline.Initial -> WirePublicationBaseline.INITIAL
    is com.typewritermc.realm.compiler.PublicationBaseline.Selected -> WirePublicationBaseline.SelectedWrapper(skirout.editor.v1.type_catalog.PublicationId(value = publication.value))
}
private fun com.typewritermc.realm.compiler.PublicationFailure.toWire(): WirePublicationFailure = when (this) {
    is com.typewritermc.realm.compiler.PublicationFailure.EvaluationInterrupted -> WirePublicationFailure.EvaluationInterruptedWrapper(message)
    is com.typewritermc.realm.compiler.PublicationFailure.ImplementationUnavailable -> WirePublicationFailure.ImplementationUnavailableWrapper(message)
    is com.typewritermc.realm.compiler.PublicationFailure.PublicationInterrupted -> WirePublicationFailure.PublicationInterruptedWrapper(skirout.editor.v1.type_catalog.PublicationId(value = publication.value))
}
private fun com.typewritermc.realm.compiler.PublicationChange.toWire(): WirePublicationChange = when (this) {
    is com.typewritermc.realm.compiler.PublicationChange.RootAdded -> WirePublicationChange.RootAddedWrapper(root.toWire())
    is com.typewritermc.realm.compiler.PublicationChange.RootUpdated -> WirePublicationChange.RootUpdatedWrapper(root.toWire())
    is com.typewritermc.realm.compiler.PublicationChange.RootRemoved -> WirePublicationChange.RootRemovedWrapper(root.toWire())
    com.typewritermc.realm.compiler.PublicationChange.RequirementsChanged -> WirePublicationChange.REQUIREMENTS_CHANGED
}
private fun com.typewritermc.engine.CompilationRoot.toWire() = skirout.editor.v1.compilation_root.CompilationRoot(
    projection = skirout.editor.v1.compilation_root.CompilationProjectionId(value = projection.value), resource = skirout.editor.v1.type_catalog.ResourceId(value = resource.value),
)
private fun com.typewritermc.realm.compiler.PublicationDelta.toWire() = skirout.editor.v1.publication.PublicationDelta(first = first.toWire(), additional = additional.map { it.toWire() })
private fun com.typewritermc.realm.compiler.PublicationBlockers.toWire() = WirePublicationBlockers(first = first.toWire(), additional = additional.map { it.toWire() })
private fun com.typewritermc.realm.compiler.PublicationBlocker.toWire() = WirePublicationBlocker(details = diagnostic.details())
private fun com.typewritermc.realm.compiler.PublicationNotice.toWire(): WirePublicationNotice = when (this) {
    is com.typewritermc.realm.compiler.PublicationNotice.Information -> WirePublicationNotice.InformationWrapper(diagnostic.details())
    is com.typewritermc.realm.compiler.PublicationNotice.Warning -> WirePublicationNotice.WarningWrapper(diagnostic.details())
}
private fun com.typewritermc.checking.Diagnostic.details(): PublicationDiagnosticDetails {
    val encoded = SkirTypeCodec.encode(this).getOrThrow()
    return PublicationDiagnosticDetails(id = encoded.id, origin = encoded.origin, code = encoded.code, message = encoded.message, primary = encoded.primary, related = encoded.related)
}
private fun com.typewritermc.realm.compiler.PublicationResult.toWire(): WirePublicationResult = when (this) {
    com.typewritermc.realm.compiler.PublicationResult.Publishing -> WirePublicationResult.PUBLISHING
    is com.typewritermc.realm.compiler.PublicationResult.Activated -> WirePublicationResult.createActivated(publication = skirout.editor.v1.type_catalog.PublicationId(value = publication.value))
    is com.typewritermc.realm.compiler.PublicationResult.Blocked -> WirePublicationResult.BlockedWrapper(blockers.toWire())
    is com.typewritermc.realm.compiler.PublicationResult.Interrupted -> WirePublicationResult.InterruptedWrapper(skirout.editor.v1.type_catalog.PublicationId(value = publication.value))
    com.typewritermc.realm.compiler.PublicationResult.NoChanges -> WirePublicationResult.NO_CHANGES
    is com.typewritermc.realm.compiler.PublicationResult.CandidateChanged -> WirePublicationResult.CandidateChangedWrapper(PublicationViewChanged(current = skirout.editor.v1.publication.PublicationViewId(value = view.value)))
}
