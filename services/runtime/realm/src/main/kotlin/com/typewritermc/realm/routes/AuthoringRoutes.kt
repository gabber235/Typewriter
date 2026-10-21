package com.typewritermc.realm.routes

import com.typewritermc.authoring.ArgumentLocation
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringEditCommit
import com.typewritermc.protocol.transport.generated.authoringStateQuery
import com.typewritermc.protocol.transport.generated.authoringTypeCommit
import com.typewritermc.protocol.transport.generated.authoringTypePreview
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.DefaultTypeArgumentOperations
import com.typewritermc.realm.authoring.TypeArgumentOperations
import com.typewritermc.realm.authoring.TypePreviewResult
import com.typewritermc.realm.authoring.requireValid
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.requireValid
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.authoring.ArgumentLocation as SkirArgumentLocation
import skirout.editor.v1.authoring.AuthoringResource as SkirAuthoringResource
import skirout.editor.v1.authoring.AuthoringState as SkirAuthoringState
import skirout.editor.v1.authoring.CatalogChanged as SkirCatalogChanged
import skirout.editor.v1.authoring_facts.LinkProjection as SkirLinkProjection
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

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
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.authoringStateQuery) { call -> query(call.request) }
            unary(address.authoringEditCommit) { call ->
                val edit = SkirAuthoringOperationCodec.decode(call.request).getOrThrow()
                SkirAuthoringOperationCodec.encode(repository.commit(edit)).getOrThrow()
            }
            unary(address.authoringTypePreview) { call ->
                preview(call.request).toWire()
            }
            unary(address.authoringTypeCommit) { call ->
                typeArguments.prepare(call.request.requireValid()).toWire()
            }
        }

    private suspend fun query(request: QueryAuthoringStateRequest): QueryAuthoringStateResponse {
        val lease = views.capture()
        lease.use { snapshot ->
            val root = snapshot.root
            if (root.catalog.generation.value != request.generation.value) {
                return QueryAuthoringStateResponse.CatalogChangedErrorWrapper(
                    SkirCatalogChanged(actualGeneration = root.catalog.generation),
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
                        content = record,
                    )
                }
            val links =
                projection.projections.map { link ->
                    SkirLinkProjection(
                        contract =
                            link.contract,
                        first = SkirResourceId(value = link.first.value),
                        second = SkirResourceId(value = link.second.value),
                        firstLocation = link.firstLocation,
                        secondLocation = link.secondLocation,
                    )
                }
            val capturedFindings = captureFindings(root, findings())
            val authored =
                SkirAuthoringState(
                    generation = root.catalog.generation,
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
        val requested = request.requested.requireValid()
        val requestedCatalog = request.catalog
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
            PreviewTypeArgumentChangeResponse.ReadyWrapper(preview)
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
                problems,
            )
        }
    }

private fun PreparedEditResult.toWire(): PrepareTypeArgumentChangeResponse =
    when (this) {
        is PreparedEditResult.Prepared -> {
            PrepareTypeArgumentChangeResponse.createPrepared(edit = SkirAuthoringOperationCodec.encode(edit).getOrThrow())
        }

        is PreparedEditResult.NeedsInput -> {
            PrepareTypeArgumentChangeResponse.NeedsInputWrapper(locations)
        }

        is PreparedEditResult.Rejected -> {
            PrepareTypeArgumentChangeResponse.RejectedErrorWrapper(problems)
        }
    }

private fun ArgumentLocation.toWire() = SkirArgumentLocation(index = index)
