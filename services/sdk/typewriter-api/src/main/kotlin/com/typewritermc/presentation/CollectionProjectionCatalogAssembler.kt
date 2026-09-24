package com.typewritermc.presentation

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.CollectionProjectionDefinition
import skirout.editor.v1.authoring.CollectionProjectionField
import skirout.editor.v1.authoring.CollectionProjectionSource
import skirout.editor.v1.authoring.ResourceDefinitionId
import skirout.editor.v1.authoring.ResourceFilter
import skirout.editor.v1.path.DataPath
import skirout.editor.v1.path.DataPathSegment
import skirout.editor.v1.path.FieldPathSegment

data class CollectionProjectionCatalog(
    val definitions: List<CollectionProjectionDefinition>,
    val diagnostics: List<PresentationDiagnostic>,
)

/** Compiles discovered row mappings before presentations are selected. */
object CollectionProjectionCatalogAssembler {
    fun assemble(
        providers: Collection<CollectionProjectionProvider>,
        prototypes: TypePrototypeRegistry,
        resourceDefinitions: Collection<AuthoringResourceDefinition>,
    ): CollectionProjectionCatalog {
        val diagnostics = mutableListOf<PresentationDiagnostic>()
        val context = PresentationBuildContext(prototypes)
        val knownResources = resourceDefinitions.mapTo(mutableSetOf()) { it.id.value }
        val candidates =
            providers.sortedWith(compareBy({ it.sourcePart }, { it.declarationName })).mapNotNull { provider ->
                runCatching {
                    val spec = provider.specification(context)
                    require(spec.resourceDefinitionId in knownResources) {
                        "Collection ${spec.sourceId} references unavailable resource definition ${spec.resourceDefinitionId}."
                    }
                    val resourceType = prototypes.require(spec.resourceType).type
                    val rowType = prototypes.require(spec.rowType).type
                    CollectionProjectionDefinition(
                        sourceId = spec.sourceId,
                        resources =
                            ResourceFilter(
                                definitions = listOf(ResourceDefinitionId(value = spec.resourceDefinitionId)),
                                assignableTo = SkirTypeCodec.encode(TypeExpression.Named(resourceType)).getOrThrow(),
                            ),
                        rowType = SkirTypeCodec.encode(rowType).getOrThrow(),
                        fields =
                            spec.fields.map { field ->
                                CollectionProjectionField(
                                    target = path(field.target),
                                    source =
                                        when (val source = field.source) {
                                            CollectionProjectionValueSpec.ResourceId -> {
                                                CollectionProjectionSource.RESOURCE_ID
                                            }

                                            is CollectionProjectionValueSpec.Content -> {
                                                CollectionProjectionSource.ContentWrapper(path(source.field))
                                            }

                                            is CollectionProjectionValueSpec.Literal -> {
                                                CollectionProjectionSource.LiteralWrapper(
                                                    SkirDataValueCodec.encode(source.value).getOrThrow(),
                                                )
                                            }
                                        },
                                )
                            },
                    )
                }.getOrElse { failure ->
                    diagnostics +=
                        PresentationDiagnostic(
                            code = "invalid_collection_projection",
                            message = failure.message ?: "Collection projection compilation failed.",
                            sourcePart = provider.sourcePart,
                            presentationName = provider.declarationName,
                        )
                    null
                }
            }
        val unique =
            candidates.groupBy(CollectionProjectionDefinition::sourceId).flatMap { (sourceId, definitions) ->
                if (definitions.size == 1) {
                    definitions
                } else {
                    diagnostics +=
                        PresentationDiagnostic(
                            code = "duplicate_collection_source",
                            message = "Collection source $sourceId is declared more than once.",
                            presentationName = sourceId,
                        )
                    emptyList()
                }
            }
        return CollectionProjectionCatalog(unique.sortedBy(CollectionProjectionDefinition::sourceId), diagnostics)
    }

    private fun path(field: String) = DataPath(segments = listOf(DataPathSegment.FieldWrapper(FieldPathSegment(fieldName = field))))
}
