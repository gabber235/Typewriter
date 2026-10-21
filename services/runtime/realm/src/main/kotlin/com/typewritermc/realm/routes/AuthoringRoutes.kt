package com.typewritermc.realm.routes

import com.typewritermc.authoring.definition
import com.typewritermc.authoring.requireValid
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringEditCommit
import com.typewritermc.protocol.transport.generated.authoringStateQuery
import com.typewritermc.protocol.transport.generated.authoringTypeCommit
import com.typewritermc.protocol.transport.generated.authoringTypePreview
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.DefaultTypeArgumentOperations
import com.typewritermc.realm.authoring.TypeArgumentOperations
import com.typewritermc.realm.authoring.requireValid
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.catalog.of
import com.typewritermc.types.requireValid
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.authoring.AuthoringResource as SkirAuthoringResource
import skirout.editor.v1.authoring.AuthoringState as SkirAuthoringState
import skirout.editor.v1.authoring.CatalogChanged as SkirCatalogChanged

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
            unary(address.authoringEditCommit) { call -> repository.commit(call.request.requireValid()) }
            unary(address.authoringTypePreview) { call -> preview(call.request) }
            unary(address.authoringTypeCommit) { call -> typeArguments.prepare(call.request.requireValid()) }
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
                    SkirAuthoringResource(id = id, content = record)
                }
            val capturedFindings = captureFindings(root, findings())
            val authored =
                SkirAuthoringState(
                    generation = root.catalog.generation,
                    resources = resources,
                    links = projection.projections,
                    findings = capturedFindings.findings,
                    confirmedObservation =
                        AuthoringObservationId(value = root.observationId),
                )
            return QueryAuthoringStateResponse.StateWrapper(authored)
        }
    }

    private fun preview(request: PreviewTypeArgumentChangeRequest): PreviewTypeArgumentChangeResponse {
        val requested = request.requested.requireValid()
        val requestedCatalog = request.catalog
        val lease = views.capture()
        lease.use { snapshot ->
            if (snapshot.root.catalog.generation != requestedCatalog) {
                return PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper(
                    listOf(DeclarationDiagnostic.of(requested.definition, "catalog_changed")),
                )
            }
            return typeArguments.preview(request.resource.requireValid(), requested, snapshot)
        }
    }
}
