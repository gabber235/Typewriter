package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.AuthoringBatch
import com.typewritermc.realm.repository.AuthoringOperation
import com.typewritermc.realm.repository.AuthoringResourceKind
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataPathSegment
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypedValueEnvelope
import com.typewritermc.types.expression
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.library.v1.authoring.ApplyAuthoringBatchRequest
import skirout.library.v1.authoring.PreviewAuthoringBatchRequest
import skirout.editor.v1.path.DataPath as WireDataPath
import skirout.editor.v1.path.DataPathSegment as WireDataPathSegment
import skirout.library.v1.authoring.AuthoringOperation as WireOperation
import skirout.library.v1.authoring.AuthoringResource as WireResource
import skirout.library.v1.authoring.ResourceKind as WireResourceKind

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
                kind = value.resource.kind.toDomain(),
                content = value.resource.content.toDomain(),
            )
        }

        is WireOperation.CommitWrapper -> {
            require(value.base.id == value.id && value.proposed.id == value.id) { "Commit resource ids must agree." }
            require(value.base.kind == value.proposed.kind) { "Commit resource kinds must agree." }
            AuthoringOperation.CommitResource(
                id = value.id.toDomain(),
                observedSequence = value.observedSequence,
                base = value.base.content.toDomain(),
                proposed = value.proposed.content.toDomain(),
                changedPaths = value.changedPaths.map(WireDataPath::toDomain),
            )
        }

        is WireOperation.DeleteWrapper -> {
            AuthoringOperation.DeleteResource(value.id.toDomain())
        }

        is WireOperation.Unknown -> {
            error("Unknown authoring operation")
        }
    }

private fun WireResource.toDomain(): com.typewritermc.realm.repository.AuthoringGraphResource =
    com.typewritermc.realm.repository.AuthoringGraphResource(
        id = id.toDomain(),
        kind = kind.toDomain(),
        content = content.toDomain(),
    )

private fun skirout.editor.v1.type_catalog.ResourceId.toDomain(): ResourceId = ResourceId(value)

private fun WireResourceKind.toDomain(): AuthoringResourceKind =
    when (this) {
        WireResourceKind.BOOK -> AuthoringResourceKind.BOOK
        WireResourceKind.TAG -> AuthoringResourceKind.TAG
        WireResourceKind.PAGE -> AuthoringResourceKind.PAGE
        WireResourceKind.ELEMENT -> AuthoringResourceKind.ELEMENT
        else -> error("Unknown resource kind")
    }

private fun skirout.editor.v1.typed_value.TypedValueEnvelope.toDomain(): TypedValueEnvelope =
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
