package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.AuthoringGraphQueryResult
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.AuthoringResourceKind
import com.typewritermc.realm.repository.GraphSelection
import com.typewritermc.realm.repository.RelationDirection
import com.typewritermc.realm.repository.RelationFilter
import com.typewritermc.realm.repository.RelationStep
import com.typewritermc.realm.repository.ResourceFilter
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.ResourceSeed
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataPathSegment
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypedValueEnvelope
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.library.v1.authoring.AuthoringDiagnostic
import skirout.library.v1.authoring.AuthoringEdge
import skirout.library.v1.authoring.AuthoringEdgeId
import skirout.library.v1.authoring.AuthoringEdgeOrigin
import skirout.library.v1.authoring.AuthoringResource
import skirout.library.v1.authoring.AuthoringResourcePresentation
import skirout.library.v1.authoring.QueryAuthoringGraphRequest
import skirout.library.v1.authoring.QueryAuthoringGraphResponse
import skirout.editor.v1.path.DataPath as WireDataPath
import skirout.editor.v1.path.DataPathSegment as WireDataPathSegment
import skirout.editor.v1.type_catalog.ResourceId as WireResourceId
import skirout.editor.v1.typed_value.TypedValueEnvelope as WireTypedValueEnvelope
import skirout.library.v1.authoring.GraphSelection as WireGraphSelection
import skirout.library.v1.authoring.GraphSelectionResult as WireGraphSelectionResult
import skirout.library.v1.authoring.RelationDirection as WireRelationDirection
import skirout.library.v1.authoring.RelationFilter as WireRelationFilter
import skirout.library.v1.authoring.RelationStep as WireRelationStep
import skirout.library.v1.authoring.ResourceFilter as WireResourceFilter
import skirout.library.v1.authoring.ResourceKind as WireResourceKind
import skirout.library.v1.authoring.ResourceSeed as WireResourceSeed

internal fun QueryAuthoringGraphRequest.toDomain(): List<GraphSelection> = selections.map(WireGraphSelection::toDomain)

internal fun WireGraphSelection.toDomain(): GraphSelection =
    GraphSelection(
        key = key,
        seed = seed.toDomain(),
        steps = steps.map(WireRelationStep::toDomain),
    )

private fun WireResourceSeed.toDomain(): ResourceSeed =
    when (this) {
        is WireResourceSeed.IdsWrapper -> {
            ResourceSeed.Ids(
                values = value.values.map { ResourceId(it.value) },
                requireAssignableTo = value.requireAssignableTo?.let { SkirTypeCodec.decode(it).getOrThrow() },
            )
        }

        is WireResourceSeed.ScanWrapper -> {
            ResourceSeed.Scan(value.filter.toDomain())
        }

        is WireResourceSeed.Unknown -> {
            throw IllegalArgumentException("Unknown resource seed.")
        }
    }

internal fun WireResourceFilter.toDomain(): ResourceFilter =
    ResourceFilter(
        kinds = kinds.map(WireResourceKind::toDomain).toSet(),
        assignableTo = assignableTo?.let { SkirTypeCodec.decode(it).getOrThrow() },
    )

private fun WireRelationStep.toDomain(): RelationStep =
    RelationStep(
        relations = relations.toDomain(),
        direction =
            when (direction) {
                WireRelationDirection.OUTGOING -> RelationDirection.OUTGOING
                WireRelationDirection.INCOMING -> RelationDirection.INCOMING
                WireRelationDirection.BOTH -> RelationDirection.BOTH
                else -> throw IllegalArgumentException("Unknown relation direction.")
            },
        minDepth = minDepth,
        maxDepth = maxDepth,
        target = target?.toDomain(),
    )

private fun WireRelationFilter.toDomain(): RelationFilter =
    when (this) {
        WireRelationFilter.ANY -> {
            RelationFilter.Any
        }

        is WireRelationFilter.OrdinaryReferencesWrapper -> {
            RelationFilter.OrdinaryReferences(
                sourcePathPrefixes = value.sourcePathPrefixes.map(WireDataPath::toDomain),
                expectedTarget = value.expectedTarget?.let { SkirTypeCodec.decode(it).getOrThrow() },
            )
        }

        is WireRelationFilter.DeclaredWrapper -> {
            RelationFilter.Declared(value.relationIds.mapTo(linkedSetOf()) { RelationId(it.value) })
        }

        is WireRelationFilter.Unknown -> {
            throw IllegalArgumentException("Unknown relation filter.")
        }
    }

internal fun AuthoringGraphQueryResult.toWire(subjects: AuthoringSubjectProjector): QueryAuthoringGraphResponse =
    when (this) {
        is AuthoringGraphQueryResult.CatalogChanged -> {
            QueryAuthoringGraphResponse.createCatalogChanged(
                actualGeneration = CatalogGeneration(value = actualGeneration),
            )
        }

        is AuthoringGraphQueryResult.Invalid -> {
            QueryAuthoringGraphResponse.createInvalid(
                diagnostics = listOf(AuthoringDiagnostic(code = code, message = message, resource = null, path = null)),
            )
        }

        is AuthoringGraphQueryResult.Success -> {
            QueryAuthoringGraphResponse.createSuccess(
                generation = CatalogGeneration(value = snapshot.generation),
                sequence = snapshot.sequence,
                resources = snapshot.resources.map(AuthoringGraphResource::toWire),
                edges = snapshot.edges.map(StoredResourceRelation::toWire),
                selections =
                    snapshot.selections.map { selection ->
                        WireGraphSelectionResult(
                            key = selection.key,
                            resourceIds = selection.resourceIds.map(ResourceId::toWire),
                            edgeIds = selection.edgeIds.map { AuthoringEdgeId(value = it) },
                            missingIds = selection.missingIds.map(ResourceId::toWire),
                            incompatibleIds = selection.incompatibleIds.map(ResourceId::toWire),
                        )
                    },
                diagnostics = emptyList(),
                presentations =
                    snapshot.resources.map { resource ->
                        AuthoringResourcePresentation(
                            resource = resource.id.toWire(),
                            subject = subjects.project(resource, snapshot.edges),
                        )
                    },
            )
        }
    }

internal fun AuthoringGraphResource.toWire(): AuthoringResource =
    AuthoringResource(
        id = id.toWire(),
        kind = kind.toWire(),
        content = content.toWire(),
    )

internal fun TypedValueEnvelope.toWire(): WireTypedValueEnvelope {
    val root =
        (rootType as? TypeExpression.Named)?.reference
            ?: throw IllegalArgumentException("Authored resources require a nominal root type.")
    return WireTypedValueEnvelope(
        rootType = SkirTypeCodec.encode(root).getOrThrow(),
        rootValue = SkirDataValueCodec.encode(rootValue).getOrThrow(),
    )
}

internal fun StoredResourceRelation.toWire(): AuthoringEdge =
    AuthoringEdge(
        id = AuthoringEdgeId(value = id),
        source = source.toWire(),
        target = target.toWire(),
        origin =
            when (val value = origin) {
                is ResourceRelationOrigin.Reference -> {
                    AuthoringEdgeOrigin.createOrdinaryReference(
                        path = value.sourcePath.toWirePath(),
                        slot = value.slot.value,
                        expectedTarget = SkirTypeCodec.encode(value.expectedTarget).getOrThrow(),
                    )
                }

                is ResourceRelationOrigin.Declared -> {
                    AuthoringEdgeOrigin.createDeclaredRelation(
                        relationId =
                            skirout.library.v1.authoring
                                .RelationId(value = value.relationId.value),
                    )
                }
            },
    )

internal fun ResourceId.toWire(): WireResourceId = WireResourceId(value = value)

private fun AuthoringResourceKind.toWire(): WireResourceKind =
    when (this) {
        AuthoringResourceKind.BOOK -> WireResourceKind.BOOK
        AuthoringResourceKind.TAG -> WireResourceKind.TAG
        AuthoringResourceKind.PAGE -> WireResourceKind.PAGE
        AuthoringResourceKind.ELEMENT -> WireResourceKind.ELEMENT
    }

private fun WireResourceKind.toDomain(): AuthoringResourceKind =
    when (this) {
        WireResourceKind.BOOK -> AuthoringResourceKind.BOOK
        WireResourceKind.TAG -> AuthoringResourceKind.TAG
        WireResourceKind.PAGE -> AuthoringResourceKind.PAGE
        WireResourceKind.ELEMENT -> AuthoringResourceKind.ELEMENT
        else -> throw IllegalArgumentException("Unknown resource kind.")
    }

private fun WireDataPath.toDomain(): DataPath =
    DataPath(
        segments.map { segment ->
            when (segment) {
                is WireDataPathSegment.FieldWrapper -> {
                    DataPathSegment.Field(segment.value.fieldName)
                }

                is WireDataPathSegment.IndexWrapper -> {
                    DataPathSegment.Index(segment.value.index)
                }

                is WireDataPathSegment.MapKeyWrapper -> {
                    DataPathSegment.MapKey(SkirDataValueCodec.decode(segment.value.key).getOrThrow())
                }

                is WireDataPathSegment.Unknown -> {
                    throw IllegalArgumentException("Unknown data path segment.")
                }
            }
        },
    )

internal fun DataPath.toWirePath(): WireDataPath =
    WireDataPath(
        segments =
            segments.map { segment ->
                when (segment) {
                    is DataPathSegment.Field -> {
                        WireDataPathSegment.createField(fieldName = segment.name)
                    }

                    is DataPathSegment.Index -> {
                        WireDataPathSegment.createIndex(index = segment.index)
                    }

                    is DataPathSegment.MapKey -> {
                        WireDataPathSegment.createMapKey(key = SkirDataValueCodec.encode(segment.key).getOrThrow())
                    }
                }
            },
    )
