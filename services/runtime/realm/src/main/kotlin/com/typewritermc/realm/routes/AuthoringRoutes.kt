package com.typewritermc.realm.routes

import com.typewritermc.authoring.ArgumentLocation
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.DefaultTypeArgumentOperations
import com.typewritermc.realm.authoring.LinkRepairIntent
import com.typewritermc.realm.authoring.TypeArgumentChangePreview
import com.typewritermc.realm.authoring.TypeArgumentOperations
import com.typewritermc.realm.authoring.TypePreviewResult
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.communicator.transfer.BoundedByteTransferEncoder
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferChunk
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferPlan
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import okio.ByteString.Companion.toByteString
import skirout.editor.v1.authoring.AuthoringStateTransferChunk
import skirout.editor.v1.authoring.AuthoringTransferUnavailable
import skirout.editor.v1.authoring.AuthoringTransferUnavailableReason
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring.ArgumentLocation as SkirArgumentLocation
import skirout.editor.v1.authoring.AuthoringResource as SkirAuthoringResource
import skirout.editor.v1.authoring.AuthoringState as SkirAuthoringState
import skirout.editor.v1.authoring.CatalogChanged as SkirCatalogChanged
import skirout.editor.v1.authoring.LinkRepairIntent as SkirLinkRepairIntent
import skirout.editor.v1.authoring.PreparedEditResult as SkirPreparedEditResult
import skirout.editor.v1.authoring.TypeArgumentChangePreview as SkirTypeArgumentChangePreview
import skirout.editor.v1.authoring.TypePreviewResult as SkirTypePreviewResult
import skirout.editor.v1.authoring_facts.LinkProjection as SkirLinkProjection
import skirout.editor.v1.catalog.ResourceDefinitionId as SkirResourceDefinitionId
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.NamedTypeUse as SkirNamedTypeUse
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse
import skirout.kernel.v1.bounded_transfer.BoundedTransferChunk as SkirBoundedTransferChunk

internal class AuthoringRoutes private constructor(
    private val repository: AuthoringRepository,
    private val snapshots: AuthoringViewStore,
    private val captureFindings: suspend (com.typewritermc.realm.authoring.AuthoringView) -> CapturedFindings,
    private val typeArguments: TypeArgumentOperations = DefaultTypeArgumentOperations(snapshots),
    private val contracts: EditorContracts,
) {
    constructor(
        repository: AuthoringRepository,
        snapshots: AuthoringViewStore,
        events: EditorCheckEvents,
        typeArguments: TypeArgumentOperations = DefaultTypeArgumentOperations(snapshots),
        contracts: EditorContracts,
    ) : this(repository, snapshots, events::capture, typeArguments, contracts)

    constructor(
        repository: AuthoringRepository,
        snapshots: AuthoringViewStore,
        findings: () -> List<com.typewritermc.realm.checking.FindingSet>,
        typeArguments: TypeArgumentOperations = DefaultTypeArgumentOperations(snapshots),
        contracts: EditorContracts,
    ) : this(
        repository,
        snapshots,
        { root -> captureFindings(root, findings()) },
        typeArguments,
        contracts,
    )

    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.queryAuthoringState) { call ->
                val transfer = query(call.request)
                transfer.updates.forEach { update -> call.publishUpdate(update).requirePublished() }
                transfer.initial
            }
            unary(contracts.commitPreparedEdit) { call ->
                val edit = SkirAuthoringOperationCodec.decode(call.request).getOrThrow()
                CommitPreparedEditResponse.ResultWrapper(
                    SkirAuthoringOperationCodec.encode(repository.commit(edit)).getOrThrow(),
                )
            }
            unary(contracts.previewTypeArgumentChange) { call ->
                PreviewTypeArgumentChangeResponse.ResultWrapper(preview(call.request).toWire())
            }
            unary(contracts.prepareTypeArgumentChange) { call ->
                val preview = call.request.toDomain()
                PrepareTypeArgumentChangeResponse.ResultWrapper(
                    typeArguments.prepare(preview).toWire(),
                )
            }
        }

    private suspend fun query(request: QueryAuthoringStateRequest): AuthoringStateTransfer {
        val lease = snapshots.capture()
        lease.use { snapshot ->
            val root = snapshot.root
            if (root.catalog.generation.value != request.generation.value) {
                return AuthoringStateTransfer(
                    QueryAuthoringStateResponse.CatalogChangedWrapper(
                        SkirCatalogChanged(actualGeneration = SkirCatalogGeneration(value = root.catalog.generation.value)),
                    ),
                    emptyList(),
                )
            }
            val projection =
                ResourceValueMapper.project(
                    root.links.values,
                    root.resources,
                    root.catalog.relations,
                )
            val resources =
                root.resources.entries.sortedBy { it.key.value }.map { (id, record) ->
                    val definition = requireNotNull(root.resourceDefinitions[id])
                    SkirAuthoringResource(
                        id = SkirResourceId(value = id.value),
                        definition = SkirResourceDefinitionId(value = definition.value),
                        content = SkirAuthoringValueCodec.encode(record).getOrThrow(),
                    )
                }
            val links =
                projection.projections.map { link ->
                    SkirLinkProjection(
                        contract =
                            skirout.editor.v1.type_catalog
                                .RelationId(value = link.contract.value),
                        first = SkirResourceId(value = link.first.value),
                        second = SkirResourceId(value = link.second.value),
                        firstLocation = link.firstLocation?.let { SkirAuthoringValueCodec.encode(it).getOrThrow() },
                        secondLocation = link.secondLocation?.let { SkirAuthoringValueCodec.encode(it).getOrThrow() },
                    )
                }
            val capturedFindings = captureFindings(root)
            val authored =
                SkirAuthoringState(
                    generation = SkirCatalogGeneration(value = root.catalog.generation.value),
                    resources = resources,
                    links = links,
                    findings = capturedFindings.findings,
                )
            return authored.toTransfer(request.transferId)
        }
    }

    private fun SkirAuthoringState.toTransfer(transferId: String): AuthoringStateTransfer {
        val encoded = SkirAuthoringState.serializer.toBytes(this).toByteArray()
        return when (val plan = BoundedByteTransferEncoder(nextTransferId = { transferId }).encode(encoded)) {
            is BoundedTransferPlan.Unavailable -> {
                AuthoringStateTransfer(
                    QueryAuthoringStateResponse.UnavailableWrapper(
                        AuthoringTransferUnavailable(
                            generation = generation,
                            reason = AuthoringTransferUnavailableReason.ENCODED_SIZE_LIMIT,
                            encodedSize = plan.encodedSize,
                            maxEncodedSize = plan.maxEncodedSize,
                        ),
                    ),
                    emptyList(),
                )
            }

            is BoundedTransferPlan.Ready -> {
                val responses =
                    plan.chunks.map { chunk ->
                        QueryAuthoringStateResponse.ChunkWrapper(
                            AuthoringStateTransferChunk(
                                generation = generation,
                                transfer = chunk.toWire(),
                            ),
                        )
                    }
                AuthoringStateTransfer(responses.first(), responses.drop(1))
            }
        }
    }

    private fun preview(request: PreviewTypeArgumentChangeRequest): TypePreviewResult {
        val requested = SkirAuthoringValueCodec.decode(request.requested).getOrThrow()
        val requestedCatalog = CatalogGeneration(request.catalog.value)
        val lease = snapshots.capture()
        lease.use { snapshot ->
            if (snapshot.root.catalog.generation != requestedCatalog) {
                return TypePreviewResult.InvalidArguments(
                    listOf(DeclarationDiagnostic(requested.definition, "catalog_changed")),
                )
            }
            return typeArguments.preview(ResourceId(request.resource.value), requested, snapshot)
        }
    }
}

private data class AuthoringStateTransfer(
    val initial: QueryAuthoringStateResponse,
    val updates: List<QueryAuthoringStateResponse>,
)

private fun BoundedTransferChunk.toWire(): SkirBoundedTransferChunk =
    SkirBoundedTransferChunk(
        transferId = transferId,
        index = index,
        chunkCount = chunkCount,
        encodedSize = encodedSize,
        sha256 = sha256,
        payload = payload.toByteArray().toByteString(),
    )

private fun TypePreviewResult.toWire(): SkirTypePreviewResult =
    when (this) {
        is TypePreviewResult.Ready -> {
            SkirTypePreviewResult.ReadyWrapper(preview.toWire())
        }

        is TypePreviewResult.InvalidArguments -> {
            SkirTypePreviewResult.InvalidArgumentsWrapper(
                diagnostics.map { SkirTypeCodec.encode(it).getOrThrow() },
            )
        }

        is TypePreviewResult.Incomplete -> {
            SkirTypePreviewResult.IncompleteWrapper(arguments.map(ArgumentLocation::toWire))
        }

        is TypePreviewResult.Rejected -> {
            SkirTypePreviewResult.RejectedWrapper(
                problems.map { SkirAuthoringValueCodec.encode(it).getOrThrow() },
            )
        }
    }

private val TypeSelection.definition
    get() =
        when (this) {
            is TypeSelection.Complete -> use.definition
            is TypeSelection.Pending -> definition
        }

private fun TypeArgumentChangePreview.toWire(): SkirTypeArgumentChangePreview =
    SkirTypeArgumentChangePreview(
        resource = SkirResourceId(value = resource.value),
        next = SkirAuthoringValueCodec.encode(next).getOrThrow(),
        edit = SkirAuthoringOperationCodec.encode(edit).getOrThrow(),
        linkRepairs = linkRepairs.map(LinkRepairIntent::toWire),
        clearedLocations = clearedLocations.map { SkirAuthoringValueCodec.encode(it).getOrThrow() },
    )

private fun SkirTypeArgumentChangePreview.toDomain(): TypeArgumentChangePreview =
    TypeArgumentChangePreview(
        resource = ResourceId(resource.value),
        next = SkirAuthoringValueCodec.decode(next).getOrThrow(),
        edit = SkirAuthoringOperationCodec.decode(edit).getOrThrow(),
        linkRepairs = linkRepairs.map(SkirLinkRepairIntent::toDomain),
        clearedLocations = clearedLocations.map { SkirAuthoringValueCodec.decode(it).getOrThrow() },
    )

private fun PreparedEditResult.toWire(): SkirPreparedEditResult =
    when (this) {
        is PreparedEditResult.Prepared -> {
            SkirPreparedEditResult.createPrepared(edit = SkirAuthoringOperationCodec.encode(edit).getOrThrow())
        }

        is PreparedEditResult.NeedsInput -> {
            SkirPreparedEditResult.NeedsInputWrapper(locations.map { SkirAuthoringValueCodec.encode(it).getOrThrow() })
        }

        is PreparedEditResult.Rejected -> {
            SkirPreparedEditResult.RejectedWrapper(problems.map { SkirAuthoringValueCodec.encode(it).getOrThrow() })
        }
    }

private fun LinkRepairIntent.toWire(): SkirLinkRepairIntent =
    when (this) {
        is LinkRepairIntent.Clear -> {
            SkirLinkRepairIntent.ClearWrapper(SkirAuthoringValueCodec.encode(occurrence).getOrThrow())
        }

        is LinkRepairIntent.Remove -> {
            SkirLinkRepairIntent.RemoveWrapper(SkirAuthoringValueCodec.encode(occurrence).getOrThrow())
        }
    }

private fun SkirLinkRepairIntent.toDomain(): LinkRepairIntent =
    when (this) {
        is SkirLinkRepairIntent.ClearWrapper -> {
            LinkRepairIntent.Clear(SkirAuthoringValueCodec.decode(value).getOrThrow())
        }

        is SkirLinkRepairIntent.RemoveWrapper -> {
            LinkRepairIntent.Remove(SkirAuthoringValueCodec.decode(value).getOrThrow())
        }

        else -> {
            error("Unknown Skir link repair intent variant.")
        }
    }

private fun ArgumentLocation.toWire() = SkirArgumentLocation(index = index)

private fun TypeUse.Named.toWire(): SkirNamedTypeUse = (SkirTypeCodec.encode(this).getOrThrow() as SkirTypeUse.NamedWrapper).value

private fun SkirNamedTypeUse.toDomain(): TypeUse.Named = SkirTypeCodec.decode(SkirTypeUse.NamedWrapper(this)).getOrThrow() as TypeUse.Named
