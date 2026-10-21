package com.typewritermc.realm.routes

import com.typewritermc.authoring.ArgumentLocation
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.DefaultTypeArgumentOperations
import com.typewritermc.realm.authoring.LinkRepairIntent
import com.typewritermc.realm.authoring.TypeArgumentChangePreview
import com.typewritermc.realm.authoring.TypeArgumentOperations
import com.typewritermc.realm.authoring.TypePreviewResult
import com.typewritermc.realm.checking.FindingSet
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.authoring.ArgumentLocation as SkirArgumentLocation
import skirout.editor.v1.authoring.AuthoringResource as SkirAuthoringResource
import skirout.editor.v1.authoring.AuthoringState as SkirAuthoringState
import skirout.editor.v1.authoring.CatalogChanged as SkirCatalogChanged
import skirout.editor.v1.authoring.LinkRepairIntent as SkirLinkRepairIntent
import skirout.editor.v1.authoring.TypeArgumentChangePreview as SkirTypeArgumentChangePreview
import skirout.editor.v1.authoring_facts.LinkProjection as SkirLinkProjection
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.NamedTypeUse as SkirNamedTypeUse
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse

/**
 * Exposes saved snapshot queries, prepared edit commit, and type argument previews to the editor.
 *
 * A state query answers with one retained view and its confirmed observation identity. Commit delegates admission
 * to the repository; preview and preparation return proposed edits without changing saved resources. Finding
 * freshness is evaluated against the returned baseline.
 */
internal class AuthoringRoutes(
    private val repository: AuthoringRepository,
    private val views: AuthoringViewStore,
    private val findings: () -> List<FindingSet>,
    private val typeArguments: TypeArgumentOperations = DefaultTypeArgumentOperations(views),
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.queryAuthoringState) { call -> query(call.request) }
            unary(contracts.commitPreparedEdit) { call ->
                val edit = SkirAuthoringOperationCodec.decode(call.request).getOrThrow()
                SkirAuthoringOperationCodec.encode(repository.commit(edit)).getOrThrow()
            }
            unary(contracts.previewTypeArgumentChange) { call ->
                preview(call.request).toWire()
            }
            unary(contracts.prepareTypeArgumentChange) { call ->
                val preview = call.request.toDomain()
                typeArguments.prepare(preview).toWire()
            }
        }

    private suspend fun query(request: QueryAuthoringStateRequest): QueryAuthoringStateResponse {
        val lease = views.capture()
        lease.use { snapshot ->
            val root = snapshot.root
            if (root.catalog.generation.value != request.generation.value) {
                return QueryAuthoringStateResponse.CatalogChangedErrorWrapper(
                    SkirCatalogChanged(actualGeneration = SkirCatalogGeneration(value = root.catalog.generation.value)),
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
                    SkirAuthoringResource(
                        id = SkirResourceId(value = id.value),
                        content = SkirAuthoringValueCodec.encode(record).getOrThrow(),
                    )
                }
            val links =
                projection.projections.map { link ->
                    SkirLinkProjection(
                        contract =
                            RelationId(value = link.contract.value),
                        first = SkirResourceId(value = link.first.value),
                        second = SkirResourceId(value = link.second.value),
                        firstLocation = link.firstLocation?.let { SkirAuthoringValueCodec.encode(it).getOrThrow() },
                        secondLocation = link.secondLocation?.let { SkirAuthoringValueCodec.encode(it).getOrThrow() },
                    )
                }
            val capturedFindings = captureFindings(root, findings())
            val authored =
                SkirAuthoringState(
                    generation = SkirCatalogGeneration(value = root.catalog.generation.value),
                    resources = resources,
                    links = links,
                    findings = capturedFindings.findings,
                    confirmedObservation =
                        AuthoringObservationId(value = root.observationId),
                )
            return QueryAuthoringStateResponse.StateWrapper(authored)
        }
    }

    private fun preview(request: PreviewTypeArgumentChangeRequest): TypePreviewResult {
        val requested = SkirAuthoringValueCodec.decode(request.requested).getOrThrow()
        val requestedCatalog = CatalogGeneration(request.catalog.value)
        val lease = views.capture()
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

private fun TypePreviewResult.toWire(): PreviewTypeArgumentChangeResponse =
    when (this) {
        is TypePreviewResult.Ready -> {
            PreviewTypeArgumentChangeResponse.ReadyWrapper(preview.toWire())
        }

        is TypePreviewResult.InvalidArguments -> {
            PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper(
                diagnostics.map { SkirTypeCodec.encode(it).getOrThrow() },
            )
        }

        is TypePreviewResult.Incomplete -> {
            PreviewTypeArgumentChangeResponse.IncompleteWrapper(arguments.map(ArgumentLocation::toWire))
        }

        is TypePreviewResult.Rejected -> {
            PreviewTypeArgumentChangeResponse.RejectedErrorWrapper(
                problems.map { SkirAuthoringValueCodec.encode(it).getOrThrow() },
            )
        }
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

private fun PreparedEditResult.toWire(): PrepareTypeArgumentChangeResponse =
    when (this) {
        is PreparedEditResult.Prepared -> {
            PrepareTypeArgumentChangeResponse.createPrepared(edit = SkirAuthoringOperationCodec.encode(edit).getOrThrow())
        }

        is PreparedEditResult.NeedsInput -> {
            PrepareTypeArgumentChangeResponse.NeedsInputWrapper(locations.map { SkirAuthoringValueCodec.encode(it).getOrThrow() })
        }

        is PreparedEditResult.Rejected -> {
            PrepareTypeArgumentChangeResponse.RejectedErrorWrapper(problems.map { SkirAuthoringValueCodec.encode(it).getOrThrow() })
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
