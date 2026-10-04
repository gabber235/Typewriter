package com.typewritermc.realm.routes

import com.typewritermc.authoring.ArgumentLocation
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.DefaultTypeArgumentOperations
import com.typewritermc.realm.authoring.LinkRepairIntent
import com.typewritermc.realm.authoring.TypeArgumentChangePreview
import com.typewritermc.realm.authoring.TypeArgumentOperations
import com.typewritermc.realm.authoring.TypePreviewResult
import com.typewritermc.realm.authoring.TypeRepairIntent
import com.typewritermc.realm.authoring.absentInputToken
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
import skirout.editor.v1.authoring.AuthoringSnapshotTransferChunk
import skirout.editor.v1.authoring.AuthoringTransferUnavailable
import skirout.editor.v1.authoring.AuthoringTransferUnavailableReason
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.CommitTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringSnapshotRequest
import skirout.editor.v1.authoring.QueryAuthoringSnapshotResponse
import skirout.editor.v1.authoring.ArgumentLocation as SkirArgumentLocation
import skirout.editor.v1.authoring.AuthoringResource as SkirAuthoringResource
import skirout.editor.v1.authoring.AuthoringSnapshot as SkirAuthoringSnapshot
import skirout.editor.v1.authoring.CatalogChanged as SkirCatalogChanged
import skirout.editor.v1.authoring.LinkProjection as SkirLinkProjection
import skirout.editor.v1.authoring.LinkRepairIntent as SkirLinkRepairIntent
import skirout.editor.v1.authoring.TypeArgumentChangePreview as SkirTypeArgumentChangePreview
import skirout.editor.v1.authoring.TypePreviewResult as SkirTypePreviewResult
import skirout.editor.v1.authoring.TypeRepairIntent as SkirTypeRepairIntent
import skirout.editor.v1.catalog.ResourceDefinitionId as SkirResourceDefinitionId
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.InputToken as SkirInputToken
import skirout.editor.v1.type_catalog.NamedTypeUse as SkirNamedTypeUse
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.SnapshotId as SkirSnapshotId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse
import skirout.kernel.v1.bounded_transfer.BoundedTransferChunk as SkirBoundedTransferChunk

internal class AuthoringRoutes private constructor(
    private val repository: AuthoringRepository,
    private val snapshots: AuthoringSnapshotStore,
    private val captureFindings: suspend (com.typewritermc.realm.authoring.AuthoredSnapshotRoot) -> CapturedFindings,
    private val typeArguments: TypeArgumentOperations = DefaultTypeArgumentOperations(repository, snapshots),
    private val contracts: EditorContracts,
) {
    constructor(
        repository: AuthoringRepository,
        snapshots: AuthoringSnapshotStore,
        events: EditorCheckEvents,
        typeArguments: TypeArgumentOperations = DefaultTypeArgumentOperations(repository, snapshots),
        contracts: EditorContracts,
    ) : this(repository, snapshots, events::capture, typeArguments, contracts)

    constructor(
        repository: AuthoringRepository,
        snapshots: AuthoringSnapshotStore,
        findings: () -> List<com.typewritermc.realm.checking.FindingSet>,
        typeArguments: TypeArgumentOperations = DefaultTypeArgumentOperations(repository, snapshots),
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
            watch(contracts.queryAuthoringSnapshot) { call ->
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
            unary(contracts.commitTypeArgumentChange) { call ->
                val preview = call.request.toDomain()
                CommitTypeArgumentChangeResponse.ResultWrapper(
                    SkirAuthoringOperationCodec.encode(typeArguments.confirm(preview)).getOrThrow(),
                )
            }
        }

    private suspend fun query(request: QueryAuthoringSnapshotRequest): AuthoringSnapshotTransfer {
        val lease = request.snapshot?.let { snapshots.retain(SnapshotId(it.value)) } ?: snapshots.capture()
        lease.use { snapshot ->
            val root = snapshot.root
            if (root.catalog.generation.value != request.generation.value) {
                return AuthoringSnapshotTransfer(
                    QueryAuthoringSnapshotResponse.CatalogChangedWrapper(
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
            val observations =
                root.inputs.entries
                    .sortedBy { it.key.toString() }
                    .map { (identity, token) ->
                        SkirAuthoringValueCodec.encode(InputObservation(identity, token)).getOrThrow()
                    }
            val capturedFindings = captureFindings(root)
            val authored =
                SkirAuthoringSnapshot(
                    snapshot = SkirSnapshotId(value = root.id.value),
                    generation = SkirCatalogGeneration(value = root.catalog.generation.value),
                    resources = resources,
                    links = links,
                    findings = capturedFindings.findings,
                    observations = observations,
                    absentInputToken = SkirInputToken(value = absentInputToken().value),
                    findingsToken = capturedFindings.token,
                )
            return authored.toTransfer(request.transferId)
        }
    }

    private fun SkirAuthoringSnapshot.toTransfer(transferId: String): AuthoringSnapshotTransfer {
        val encoded = SkirAuthoringSnapshot.serializer.toBytes(this).toByteArray()
        return when (val plan = BoundedByteTransferEncoder(nextTransferId = { transferId }).encode(encoded)) {
            is BoundedTransferPlan.Unavailable -> {
                AuthoringSnapshotTransfer(
                    QueryAuthoringSnapshotResponse.UnavailableWrapper(
                        AuthoringTransferUnavailable(
                            generation = generation,
                            snapshot = snapshot,
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
                        QueryAuthoringSnapshotResponse.ChunkWrapper(
                            AuthoringSnapshotTransferChunk(
                                generation = generation,
                                snapshot = snapshot,
                                transfer = chunk.toWire(),
                            ),
                        )
                    }
                AuthoringSnapshotTransfer(responses.first(), responses.drop(1))
            }
        }
    }

    private fun preview(request: PreviewTypeArgumentChangeRequest): TypePreviewResult {
        val requested = SkirAuthoringValueCodec.decode(request.requested).getOrThrow()
        val requestedCatalog = CatalogGeneration(request.catalog.value)
        val lease =
            runCatching { snapshots.retain(SnapshotId(request.snapshot.value)) }
                .getOrElse {
                    return TypePreviewResult.InvalidArguments(
                        listOf(DeclarationDiagnostic(requested.definition, "snapshot_missing")),
                    )
                }
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

private data class AuthoringSnapshotTransfer(
    val initial: QueryAuthoringSnapshotResponse,
    val updates: List<QueryAuthoringSnapshotResponse>,
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
        catalog = SkirCatalogGeneration(value = catalog.value),
        sourceSnapshot = SkirSnapshotId(value = sourceSnapshot.value),
        resource = SkirResourceId(value = resource.value),
        next = SkirAuthoringValueCodec.encode(next).getOrThrow(),
        observations = observations.map { SkirAuthoringValueCodec.encode(it).getOrThrow() },
        intents = intents.map(TypeRepairIntent::toWire),
        linkRepairs = linkRepairs.map(LinkRepairIntent::toWire),
        clearedLocations = clearedLocations.map { SkirAuthoringValueCodec.encode(it).getOrThrow() },
    )

private fun SkirTypeArgumentChangePreview.toDomain(): TypeArgumentChangePreview =
    TypeArgumentChangePreview(
        resource = ResourceId(resource.value),
        next = SkirAuthoringValueCodec.decode(next).getOrThrow(),
        catalog = CatalogGeneration(catalog.value),
        sourceSnapshot = SnapshotId(sourceSnapshot.value),
        observations = observations.map { SkirAuthoringValueCodec.decode(it).getOrThrow() },
        intents = intents.map(SkirTypeRepairIntent::toDomain),
        linkRepairs = linkRepairs.map(SkirLinkRepairIntent::toDomain),
        clearedLocations = clearedLocations.map { SkirAuthoringValueCodec.decode(it).getOrThrow() },
    )

private fun TypeRepairIntent.toWire(): SkirTypeRepairIntent =
    when (this) {
        is TypeRepairIntent.ConfigureResource -> {
            SkirTypeRepairIntent.createConfigureResource(
                resource = SkirResourceId(value = resource.value),
                configuration = SkirAuthoringValueCodec.encode(configuration).getOrThrow(),
            )
        }

        is TypeRepairIntent.Retag -> {
            SkirTypeRepairIntent.createRetag(
                at = SkirAuthoringValueCodec.encode(at).getOrThrow(),
                type = type.toWire(),
            )
        }

        is TypeRepairIntent.Clear -> {
            SkirTypeRepairIntent.ClearWrapper(SkirAuthoringValueCodec.encode(at).getOrThrow())
        }
    }

private fun SkirTypeRepairIntent.toDomain(): TypeRepairIntent =
    when (this) {
        is SkirTypeRepairIntent.ConfigureResourceWrapper -> {
            TypeRepairIntent.ConfigureResource(
                resource = ResourceId(value.resource.value),
                configuration = SkirAuthoringValueCodec.decode(value.configuration).getOrThrow(),
            )
        }

        is SkirTypeRepairIntent.RetagWrapper -> {
            TypeRepairIntent.Retag(
                at = SkirAuthoringValueCodec.decode(value.at).getOrThrow(),
                type = value.type.toDomain(),
            )
        }

        is SkirTypeRepairIntent.ClearWrapper -> {
            TypeRepairIntent.Clear(SkirAuthoringValueCodec.decode(value).getOrThrow())
        }

        else -> {
            error("Unknown Skir type repair intent variant.")
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
