package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringSearch
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.ResourceId
import com.typewritermc.types.requireValid
import com.typewritermc.types.use
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.AuthoringSearchHit
import skirout.editor.v1.authoring.PresentationSubject
import skirout.editor.v1.authoring.SearchAuthoringRequest
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.typed_value.PortableValue as SkirPortableValue

internal class AuthoringSearchRoutes(
    private val repository: AuthoringSearchRepository,
    private val views: AuthoringViewStore,
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.authoringSearch) { call -> search(call.request) }
        }

    internal fun search(request: SearchAuthoringRequest): SearchAuthoringResponse =
        views.read { root ->
            if (root.catalog.generation.value != request.generation.value) {
                return@read SearchAuthoringResponse.createCatalogChangedError(
                    actualGeneration = SkirCatalogGeneration(value = root.catalog.generation.value),
                )
            }
            try {
                val candidates =
                    repository.search(
                        root,
                        request.query,
                        request.contexts.mapTo(linkedSetOf()) { ResourceId(it.value) },
                        request.roots.mapTo(linkedSetOf()) { it.requireValid() },
                        request.target?.requireValid(),
                        MAX_SEARCH_CANDIDATES,
                    )
                SearchAuthoringResponse.createSuccess(
                    generation = SkirCatalogGeneration(value = root.catalog.generation.value),
                    hits =
                        candidates
                            .mapNotNull { candidate ->
                                val record = root.resources[candidate.resource] ?: return@mapNotNull null
                                candidate.toWire(record)
                            }.take(MAX_SEARCH_RESULTS),
                    diagnostics = emptyList(),
                )
            } catch (_: IllegalArgumentException) {
                invalidSearch("invalid_search", "The search request contains invalid type data.")
            }
        }
}

private fun invalidSearch(
    code: String,
    message: String,
): SearchAuthoringResponse =
    SearchAuthoringResponse.createInvalidError(
        diagnostics = listOf(AuthoringDiagnostic(code = code, message = message, resource = null, path = null)),
    )

private fun IndexedAuthoringSearchCandidate.toWire(record: AuthoringRecord): AuthoringSearchHit {
    val wireResource = SkirResourceId(value = resource.value)
    return AuthoringSearchHit(
        resource = wireResource,
        subject =
            PresentationSubject(
                resource = wireResource,
                content = record,
            ),
        context =
            SkirPortableValue(
                actualType = ScalarKind.TEXT.use,
                payload = DataValue.StringValueWrapper(text),
            ),
    )
}

private const val MAX_SEARCH_CANDIDATES = 256
private const val MAX_SEARCH_RESULTS = 100
