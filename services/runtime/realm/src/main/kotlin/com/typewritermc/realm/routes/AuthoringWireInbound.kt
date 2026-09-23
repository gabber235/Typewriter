package com.typewritermc.realm.routes

import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.AuthoringBatch
import com.typewritermc.realm.repository.AuthoringOperation
import com.typewritermc.realm.repository.CreationAttachment
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataPathSegment
import com.typewritermc.types.ResourceId
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.TypedValueEnvelope
import com.typewritermc.types.expression
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.ApplyAuthoringBatchRequest
import skirout.editor.v1.authoring.PreviewAuthoringBatchRequest
import skirout.editor.v1.authoring.AuthoringOperation as WireOperation
import skirout.editor.v1.authoring.AuthoringResource as WireResource
import skirout.editor.v1.authoring.ResourceDefinitionId as WireResourceDefinitionId
import skirout.editor.v1.path.DataPath as WireDataPath
import skirout.editor.v1.path.DataPathSegment as WireDataPathSegment

internal fun ApplyAuthoringBatchRequest.toDomain(): AuthoringBatch =
    AuthoringBatch(
        id = BatchId(batchId),
        generation = generation.value,
        operations = operations.map(WireOperation::toDomain),
    )

internal fun PreviewAuthoringBatchRequest.toDomain(): List<AuthoringOperation> = operations.map(WireOperation::toDomain)

private fun WireOperation.toDomain(): AuthoringOperation =
    when (this) {
        is WireOperation.CreateWrapper -> {
            AuthoringOperation.CreateResource(
                id = value.resource.id.toDomain(),
                definition = value.resource.definition.toDomain(),
                content = value.resource.content.toDomain(),
                attachment = value.attachment?.let { attachment ->
                    CreationAttachment(
                        host = attachment.host.toDomain(),
                        relation = com.typewritermc.types.RelationId(attachment.relation.value),
                        hostSide = when (attachment.hostSide) {
                            skirout.editor.v1.authoring.RelationEndpointSide.SOURCE -> RelationEndpointSide.SOURCE
                            skirout.editor.v1.authoring.RelationEndpointSide.TARGET -> RelationEndpointSide.TARGET
                            else -> error("Unknown relation endpoint side")
                        },
                    )
                },
            )
        }

        is WireOperation.CommitWrapper -> {
            require(value.base.id == value.id && value.proposed.id == value.id) { "Commit resource ids must agree." }
            require(value.base.definition == value.proposed.definition) { "Commit resource definitions must agree." }
            AuthoringOperation.CommitResource(
                id = value.id.toDomain(),
                base = value.base.content.toDomain(),
                proposed = value.proposed.content.toDomain(),
                changedPaths = value.changedPaths.map(WireDataPath::toDomain),
            )
        }

        is WireOperation.DeleteWrapper -> {
            require(value.base.id == value.id) { "Delete resource ids must agree." }
            AuthoringOperation.DeleteResource(
                id = value.id.toDomain(),
                base = value.base.content.toDomain(),
            )
        }

        is WireOperation.DeclareRelationWrapper -> {
            AuthoringOperation.DeclareRelation(
                relation = com.typewritermc.types.RelationId(value.relation.value),
                source = value.source.toDomain(),
                target = value.target.toDomain(),
                sourceBefore = value.sourceBefore?.toDomain(),
                targetBefore = value.targetBefore?.toDomain(),
            )
        }

        is WireOperation.RemoveRelationWrapper -> {
            AuthoringOperation.RemoveRelation(
                relation = com.typewritermc.types.RelationId(value.relation.value),
                source = value.source.toDomain(),
                target = value.target.toDomain(),
            )
        }

        is WireOperation.Unknown -> {
            error("Unknown authoring operation")
        }
    }

private fun WireResource.toDomain(): com.typewritermc.realm.repository.AuthoringGraphResource =
    com.typewritermc.realm.repository.AuthoringGraphResource(
        id = id.toDomain(),
        definition = definition.toDomain(),
        content = content.toDomain(),
    )

private fun skirout.editor.v1.type_catalog.ResourceId.toDomain(): ResourceId = ResourceId(value)

private fun WireResourceDefinitionId.toDomain(): ResourceDefinitionId = ResourceDefinitionId(value)

internal fun skirout.editor.v1.typed_value.TypedValueEnvelope.toDomain(): TypedValueEnvelope =
    TypedValueEnvelope(
        rootType = SkirTypeCodec.decode(rootType).getOrThrow().expression,
        rootValue = SkirDataValueCodec.decode(rootValue).getOrThrow(),
    )

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
                    error("Unknown data path segment")
                }
            }
        },
    )
