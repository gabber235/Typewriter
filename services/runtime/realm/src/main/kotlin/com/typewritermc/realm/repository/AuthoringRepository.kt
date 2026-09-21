package com.typewritermc.realm.repository

import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypedValueEnvelope
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Owns transactional mutations of the canonical authored resource graph. */
interface AuthoringRepository {
    suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult

    suspend fun preview(
        generation: String,
        operations: List<AuthoringOperation>,
    ): AuthoringPreviewResult
}

@JvmInline
@Serializable
value class BatchId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Batch ids must not be blank." }
    }
}

@Serializable
data class AuthoringBatch(
    val id: BatchId,
    val generation: String,
    val operations: List<AuthoringOperation>,
) {
    init {
        require(operations.isNotEmpty()) { "Authoring batches must not be empty." }
        require(operations.map(AuthoringOperation::resourceId).distinct().size == operations.size) {
            "Authoring batches must contain at most one operation per resource."
        }
    }
}

@Serializable
sealed interface AuthoringOperation {
    val resourceId: ResourceId

    @Serializable
    @SerialName("create")
    data class CreateResource(
        val id: ResourceId,
        val kind: AuthoringResourceKind,
        val content: TypedValueEnvelope,
    ) : AuthoringOperation {
        override val resourceId: ResourceId = id
    }

    @Serializable
    @SerialName("commit")
    data class CommitResource(
        val id: ResourceId,
        val observedSequence: Long,
        val base: TypedValueEnvelope,
        val proposed: TypedValueEnvelope,
        val changedPaths: List<DataPath>,
    ) : AuthoringOperation {
        override val resourceId: ResourceId = id
    }

    @Serializable
    @SerialName("delete")
    data class DeleteResource(
        val id: ResourceId,
    ) : AuthoringOperation {
        override val resourceId: ResourceId = id
    }
}

@Serializable
data class AuthoringChanged(
    val generation: String,
    val sequence: Long,
    val batchId: BatchId,
    val resources: List<GraphResourceChange>,
    val edges: List<GraphEdgeChange>,
)

@Serializable
sealed interface GraphResourceChange {
    @Serializable
    @SerialName("upsert")
    data class Upsert(
        val resource: AuthoringGraphResource,
    ) : GraphResourceChange

    @Serializable
    @SerialName("remove")
    data class Remove(
        val id: ResourceId,
    ) : GraphResourceChange
}

@Serializable
sealed interface GraphEdgeChange {
    @Serializable
    @SerialName("upsert")
    data class Upsert(
        val edge: StoredResourceRelation,
    ) : GraphEdgeChange

    @Serializable
    @SerialName("remove")
    data class Remove(
        val id: String,
    ) : GraphEdgeChange
}

@Serializable
data class PropertyConflict(
    val resource: ResourceId,
    val path: DataPath,
    val expected: DataValue?,
    val actual: DataValue?,
)

@Serializable
data class AuthoringDiagnostic(
    val code: String,
    val message: String = code,
    val resource: ResourceId? = null,
    val path: DataPath? = null,
)

@Serializable
sealed interface AuthoringBatchResult {
    @Serializable
    @SerialName("applied")
    data class Applied(
        val change: AuthoringChanged,
        val affectsCompilation: Boolean,
    ) : AuthoringBatchResult

    @Serializable
    @SerialName("conflict")
    data class Conflict(
        val conflicts: List<PropertyConflict>,
    ) : AuthoringBatchResult

    @Serializable
    @SerialName("invalid")
    data class Invalid(
        val diagnostics: List<AuthoringDiagnostic>,
    ) : AuthoringBatchResult

    @Serializable
    @SerialName("catalog_changed")
    data class CatalogChanged(
        val actualGeneration: String,
    ) : AuthoringBatchResult
}

sealed interface AuthoringPreviewResult {
    data class Valid(
        val affectedResources: Set<ResourceId>,
        val affectedEdges: Set<String>,
    ) : AuthoringPreviewResult

    data class Conflict(
        val conflicts: List<PropertyConflict>,
    ) : AuthoringPreviewResult

    data class Invalid(
        val diagnostics: List<AuthoringDiagnostic>,
    ) : AuthoringPreviewResult

    data class CatalogChanged(
        val actualGeneration: String,
    ) : AuthoringPreviewResult
}
