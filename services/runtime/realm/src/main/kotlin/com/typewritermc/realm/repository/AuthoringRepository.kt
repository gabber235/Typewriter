package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringChangeSummary
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.RelationId
import com.typewritermc.authoring.AuthoringPresentationSubject
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.ResourceDefinitionId
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

/** Materializes the registered presentation subject for resources changed by one committed graph plan. */
internal fun interface AuthoringPresentationMaterializer {
    fun materialize(
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
        change: AuthoringChangeSummary,
    ): List<AuthoringPresentationChange>
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
        val direct = operations.mapNotNull(AuthoringOperation::directResourceId)
        require(direct.distinct().size == direct.size) {
            "Authoring batches must contain at most one operation per resource."
        }
    }
}

@Serializable
sealed interface AuthoringOperation {
    @Serializable
    @SerialName("create")
    data class CreateResource(
        val id: ResourceId,
        val definition: ResourceDefinitionId,
        val content: TypedValueEnvelope,
        val attachment: CreationAttachment? = null,
    ) : AuthoringOperation

    @Serializable
    @SerialName("commit")
    data class CommitResource(
        val id: ResourceId,
        val base: TypedValueEnvelope,
        val proposed: TypedValueEnvelope,
        val changedPaths: List<DataPath>,
    ) : AuthoringOperation

    @Serializable
    @SerialName("delete")
    data class DeleteResource(
        val id: ResourceId,
        val base: TypedValueEnvelope,
    ) : AuthoringOperation

    @Serializable
    @SerialName("declare_relation")
    data class DeclareRelation(
        val relation: com.typewritermc.types.RelationId,
        val source: ResourceId,
        val target: ResourceId,
        val sourceBefore: ResourceId? = null,
        val targetBefore: ResourceId? = null,
    ) : AuthoringOperation

    @Serializable
    @SerialName("remove_relation")
    data class RemoveRelation(
        val relation: com.typewritermc.types.RelationId,
        val source: ResourceId,
        val target: ResourceId,
    ) : AuthoringOperation

    val directResourceId: ResourceId?
        get() =
            when (this) {
                is CreateResource -> id
                is CommitResource -> id
                is DeleteResource -> id
                is DeclareRelation -> null
                is RemoveRelation -> null
            }
}

@Serializable
data class CreationAttachment(
    val host: ResourceId,
    val relation: RelationId,
    val hostSide: RelationEndpointSide,
)

@Serializable
data class AuthoringChanged(
    val generation: String,
    val sequence: Long,
    val batchId: BatchId,
    val resources: List<GraphResourceChange>,
    val edges: List<GraphEdgeChange>,
    val presentations: List<AuthoringPresentationChange> = emptyList(),
    val compilationImpact: List<CompilationRoot> = emptyList(),
)

@Serializable
sealed interface AuthoringPresentationChange {
    val resource: ResourceId

    @Serializable
    @SerialName("upsert")
    data class Upsert(
        override val resource: ResourceId,
        val subject: AuthoringPresentationSubject,
    ) : AuthoringPresentationChange

    @Serializable
    @SerialName("remove")
    data class Remove(
        override val resource: ResourceId,
    ) : AuthoringPresentationChange
}

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
