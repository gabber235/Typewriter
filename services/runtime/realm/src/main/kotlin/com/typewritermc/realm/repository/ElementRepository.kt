package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementValueMutation
import com.typewritermc.elements.StoredElement
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

interface ElementRepository {
    suspend fun getPageElements(pageId: PageId): List<StoredElement>

    suspend fun createElements(command: CreateElementsCommand): ElementBatchResult

    suspend fun updateElementValues(command: UpdateElementValuesCommand): ElementBatchResult

    suspend fun moveElementsToPages(command: MoveElementsToPagesCommand): ElementBatchResult

    suspend fun moveGraphElements(command: MoveGraphElementsCommand): ElementBatchResult

    suspend fun resizeGraphElements(command: ResizeGraphElementsCommand): ElementBatchResult

    suspend fun updateCueTimings(command: UpdateCueTimingsCommand): ElementBatchResult

    suspend fun deleteElements(command: DeleteElementsCommand): ElementBatchResult

    suspend fun duplicateElements(command: DuplicateElementsCommand): ElementBatchResult
}

data class PageInvalidation(
    val batchId: BatchId,
    val revision: Long,
    val pageIds: Set<PageId>,
    val affectsCompilation: Boolean,
)

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
data class CreateElementsCommand(
    val batchId: BatchId,
    val elements: List<ElementCreation>,
) {
    init {
        require(elements.isNotEmpty()) { "Create element batches must not be empty." }
        require(elements.map { it.element.id }.distinct().size == elements.size) {
            "Create element batches must not contain duplicate ids."
        }
    }
}

@Serializable
data class ElementCreation(
    val page: Ref<Page>,
    val element: StoredElement,
)

@Serializable
data class UpdateElementValuesCommand(
    val batchId: BatchId,
    val updates: List<ElementValueUpdate>,
) {
    init {
        updates.requireUniqueIds("Update element value", ElementValueUpdate::id)
    }
}

@Serializable
data class ElementValueUpdate(
    val id: ElementInstanceId,
    val expectedRevision: Long,
    val name: String,
    val mutations: List<ElementValueMutation>,
) {
    init {
        require(mutations.isNotEmpty()) { "Element value updates must contain at least one mutation." }
    }
}

@Serializable
data class MoveElementsToPagesCommand(
    val batchId: BatchId,
    val moves: List<ElementPageMove>,
) {
    init {
        moves.requireUniqueIds("Move element to page", ElementPageMove::id)
    }
}

@Serializable
data class ElementPageMove(
    val id: ElementInstanceId,
    val expectedRevision: Long,
    val page: Ref<Page>,
    val placement: ElementPlacement,
)

@Serializable
data class MoveGraphElementsCommand(
    val batchId: BatchId,
    val moves: List<GraphElementMove>,
) {
    init {
        moves.requireUniqueIds("Move graph element", GraphElementMove::id)
    }
}

@Serializable
data class GraphElementMove(
    val id: ElementInstanceId,
    val expectedRevision: Long,
    val x: Int,
    val y: Int,
)

@Serializable
data class ResizeGraphElementsCommand(
    val batchId: BatchId,
    val resizes: List<GraphElementResize>,
) {
    init {
        resizes.requireUniqueIds("Resize graph element", GraphElementResize::id)
        require(resizes.all { it.width > 0 && it.height > 0 }) { "Graph element dimensions must be positive." }
    }
}

@Serializable
data class GraphElementResize(
    val id: ElementInstanceId,
    val expectedRevision: Long,
    val width: Int,
    val height: Int,
)

@Serializable
data class UpdateCueTimingsCommand(
    val batchId: BatchId,
    val updates: List<CueTimingUpdate>,
) {
    init {
        updates.requireUniqueIds("Update cue timing", CueTimingUpdate::id)
    }
}

@Serializable
data class CueTimingUpdate(
    val id: ElementInstanceId,
    val expectedRevision: Long,
    val placement: ElementPlacement,
) {
    init {
        require(placement !is ElementPlacement.Graph) { "Cue timing updates require timeline placement." }
    }
}

@Serializable
data class DeleteElementsCommand(
    val batchId: BatchId,
    val deletions: List<ElementDeletion>,
) {
    init {
        deletions.requireUniqueIds("Delete element", ElementDeletion::id)
    }
}

@Serializable
data class ElementDeletion(
    val id: ElementInstanceId,
    val expectedRevision: Long,
)

@Serializable
data class DuplicateElementsCommand(
    val batchId: BatchId,
    val duplications: List<ElementDuplication>,
) {
    init {
        require(duplications.isNotEmpty()) { "Duplicate element batches must not be empty." }
        require(duplications.map(ElementDuplication::sourceId).distinct().size == duplications.size) {
            "Duplicate element batches must not contain duplicate sources."
        }
        require(duplications.map(ElementDuplication::newId).distinct().size == duplications.size) {
            "Duplicate element batches must not contain duplicate destinations."
        }
    }
}

@Serializable
data class ElementDuplication(
    val sourceId: ElementInstanceId,
    val expectedRevision: Long,
    val newId: ElementInstanceId,
    val page: Ref<Page>,
    val name: String,
    val placement: ElementPlacement,
    val referenceRewrites: Map<ResourceId, ResourceId> = emptyMap(),
)

sealed interface ElementBatchResult {
    data class Success(
        val batchId: BatchId,
        val elements: List<StoredElement>,
        val affectedPages: Set<PageId>,
    ) : ElementBatchResult

    data class Conflict(
        val conflicts: List<ElementConflict>,
    ) : ElementBatchResult

    data class ValidationFailure(
        val diagnostics: List<ElementBatchDiagnostic>,
    ) : ElementBatchResult
}

data class ElementConflict(
    val id: ElementInstanceId,
    val expectedRevision: Long,
    val actual: StoredElement?,
)

data class ElementBatchDiagnostic(
    val code: String,
    val elementId: ElementInstanceId? = null,
    val pageId: PageId? = null,
)

private fun <T> List<T>.requireUniqueIds(
    operation: String,
    id: (T) -> ElementInstanceId,
) {
    require(isNotEmpty()) { "$operation batches must not be empty." }
    require(map(id).distinct().size == size) { "$operation batches must not contain duplicate ids." }
}
