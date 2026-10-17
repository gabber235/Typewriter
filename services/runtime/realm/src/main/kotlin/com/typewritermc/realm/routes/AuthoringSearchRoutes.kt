package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.AuthoringSearchHit
import skirout.editor.v1.authoring.PresentationSubject
import skirout.editor.v1.authoring.SearchAuthoringRequest
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.catalog.ResourceDefinitionId as SkirResourceDefinitionId
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.NamedTypeUse as SkirNamedTypeUse
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse
import skirout.editor.v1.typed_value.PortableValue as SkirPortableValue

internal class AuthoringSearchRoutes(
    private val repository: AuthoringSearchRepository,
    private val snapshots: AuthoringViewStore,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.searchAuthoring) { call -> search(call.request) }
        }

    internal fun search(request: SearchAuthoringRequest): SearchAuthoringResponse =
        snapshots.read { root ->
            if (root.catalog.generation.value != request.generation.value) {
                return@read SearchAuthoringResponse.createCatalogChanged(
                    actualGeneration = SkirCatalogGeneration(value = root.catalog.generation.value),
                )
            }
            try {
                val candidates =
                    repository.search(
                        root,
                        request.query,
                        request.contexts.mapTo(linkedSetOf()) { ResourceId(it.value) },
                        request.roots.mapTo(linkedSetOf()) { it.toDomain() },
                        request.target?.toDomain(),
                        MAX_SEARCH_CANDIDATES,
                    )
                SearchAuthoringResponse.createSuccess(
                    generation = SkirCatalogGeneration(value = root.catalog.generation.value),
                    hits =
                        candidates
                            .mapNotNull { candidate ->
                                val record = root.resources[candidate.resource] ?: return@mapNotNull null
                                val definition = root.resourceDefinitions[candidate.resource] ?: return@mapNotNull null
                                candidate.toWire(record, definition.value)
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
    SearchAuthoringResponse.createInvalid(
        diagnostics = listOf(AuthoringDiagnostic(code = code, message = message, resource = null, path = null)),
    )

private fun IndexedAuthoringSearchCandidate.toWire(
    record: AuthoringRecord,
    definition: String,
): AuthoringSearchHit {
    val wireResource = SkirResourceId(value = resource.value)
    val resourceDefinition = SkirResourceDefinitionId(value = definition)
    return AuthoringSearchHit(
        resource = wireResource,
        definition = resourceDefinition,
        subject =
            PresentationSubject(
                resource = wireResource,
                definition = resourceDefinition,
                content = SkirAuthoringValueCodec.encode(record).getOrThrow(),
                descriptor = SkirDataValueCodec.encode(DataValue.StringValue(record.displayName(this.resource))).getOrThrow(),
            ),
        context =
            SkirPortableValue(
                actualType = SkirTypeCodec.encode(TypeUse.Scalar(ScalarKind.Text)).getOrThrow(),
                payload = SkirDataValueCodec.encode(DataValue.StringValue(text)).getOrThrow(),
            ),
    )
}

private fun AuthoringRecord.displayName(resource: ResourceId): String =
    sequenceOf("name", "title")
        .mapNotNull(fields::get)
        .mapNotNull { it.displayText() }
        .firstOrNull(String::isNotBlank)
        ?: resource.value

private fun DataValue.displayText(): String? =
    when (this) {
        is DataValue.StringValue -> value
        is DataValue.EnumCase -> key
        is DataValue.Named -> payload.displayText()
        else -> null
    }

private fun skirout.editor.v1.type_catalog.TypeDefinitionId.toDomain(): TypeDefinitionId =
    (
        SkirTypeCodec
            .decode(SkirTypeUse.NamedWrapper(SkirNamedTypeUse(definition = this, arguments = emptyList())))
            .getOrThrow() as TypeUse.Named
    ).definition

private fun SkirNamedTypeUse.toDomain(): TypeUse.Named = SkirTypeCodec.decode(SkirTypeUse.NamedWrapper(this)).getOrThrow() as TypeUse.Named

private const val MAX_SEARCH_CANDIDATES = 256
private const val MAX_SEARCH_RESULTS = 100
