package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutation
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.elementName
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageId
import com.typewritermc.library.TagId
import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import com.typewritermc.library.Book as LibraryBook
import com.typewritermc.library.Page as LibraryPage
import com.typewritermc.library.Tag as LibraryTag

/**
 * Provides consistent scoped snapshots and transactional batches for collaborative editing.
 *
 * Stable batch ids support replay and expected property values detect optimistic conflicts. Domain rejection is
 * returned explicitly; operational storage failures may throw.
 */
interface AuthoringRepository {
    /**
     * Reads the requested scopes at one collaboration sequence.
     *
     * The result is a read view for editor reconciliation, not a compiler snapshot. A page scope uses the same
     * logical document projection as compilation, including reference diagnostics and compile status.
     */
    suspend fun snapshot(scopes: Set<AuthoringSnapshotScope>): AuthoringSnapshotResult

    /**
     * Applies one complete batch atomically and returns a protocol result instead of exposing domain rejection as
     * an exception.
     *
     * Reusing a batch id with the same payload returns the original applied result. A different payload is invalid.
     * Storage failures remain exceptional.
     */
    suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult

    /** Runs operations and page rules in an always cancelled transaction. */
    suspend fun preview(operations: List<AuthoringOperation>): AuthoringPreviewResult
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

/**
 * Selects the smallest authoring view needed by an editor caller.
 *
 * Scopes are assembled together at one collaboration sequence, so callers can reconcile a mixed library, book, and
 * page view without combining observations from different revisions.
 */
@Serializable
sealed interface AuthoringSnapshotScope {
    @Serializable
    @SerialName("library")
    data object Library : AuthoringSnapshotScope

    @Serializable
    @SerialName("book")
    data class Book(
        val id: BookId,
    ) : AuthoringSnapshotScope

    @Serializable
    @SerialName("page")
    data class Page(
        val id: PageId,
    ) : AuthoringSnapshotScope
}

/**
 * Returns requested library, book, or page slices at one collaboration sequence.
 *
 * The sequence supports change event reconciliation and differs from compiler source revision.
 */
data class AuthoringSnapshotResult(
    /** Collaboration sequence shared by every returned slice. */
    val sequence: Long,
    /** One slice for each requested scope, in the scope iteration order. */
    val slices: List<AuthoringSnapshotSlice>,
)

/**
 * Materialized result for one [AuthoringSnapshotScope].
 *
 * A missing book or page is represented by a null resource inside its slice. That lets callers distinguish an
 * empty child collection from a deleted scoped resource.
 */
sealed interface AuthoringSnapshotSlice {
    data class Library(
        val books: List<LibraryBook>,
        val tags: List<LibraryTag>,
    ) : AuthoringSnapshotSlice

    data class Book(
        val id: BookId,
        val book: LibraryBook?,
        val pages: List<LibraryPage>,
    ) : AuthoringSnapshotSlice

    data class Page(
        val id: PageId,
        val document: PageDocument?,
    ) : AuthoringSnapshotSlice
}

/**
 * Pairs the caller observed property with its intended replacement.
 *
 * Property level comparison avoids rejecting unrelated concurrent changes to the same record.
 */
@Serializable
data class ExpectedChange<T>(
    val expected: T,
    val value: T,
)

/**
 * Pairs a structural mutation with the logical target value observed by the caller.
 *
 * The repository checks this expectation before applying nested value edits.
 */
@Serializable
data class ExpectedElementValueMutation(
    val expected: DataValue,
    val mutation: ElementValueMutation,
)

/** Replaces an element schema and value after comparing the complete observed source state. */
@Serializable
data class ElementTypeChange(
    val expectedElementType: ElementTypeId,
    val expectedSchemaRevision: Int,
    val expectedValue: DataValue,
    val elementType: ElementTypeId,
    val schemaRevision: Int,
    val value: DataValue,
) {
    init {
        require(expectedSchemaRevision > 0) { "Expected element schema revisions must be positive." }
        require(schemaRevision > 0) { "Element schema revisions must be positive." }
    }
}

/**
 * Carries a logical element in authoring requests and change events.
 *
 * Persistence decomposes references into slots and edges. Page ownership, schema revision, and placement remain
 * explicit in this model.
 */
@Serializable
data class AuthoringElement(
    val id: ElementInstanceId,
    val page: Ref<LibraryPage>,
    val elementType: ElementTypeId,
    val schemaRevision: Int,
    val value: DataValue,
    val placement: ElementPlacement,
) {
    init {
        require(schemaRevision > 0) { "Authoring element schema revisions must be positive." }
        value.elementName()
    }
}

/**
 * Groups resource operations under a stable idempotency key.
 *
 * Batches must be nonempty with at most one operation per resource. Retry an id only with the same payload;
 * different content under an existing id is invalid.
 */
@Serializable
data class AuthoringBatch(
    val id: BatchId,
    val operations: List<AuthoringOperation>,
) {
    init {
        require(operations.isNotEmpty()) { "Authoring batches must not be empty." }
        require(operations.map(AuthoringOperation::resource).distinct().size == operations.size) {
            "Authoring batches must contain at most one operation per resource."
        }
    }
}

/**
 * Describes create, patch, duplicate, or delete work inside a batch.
 *
 * Expected patch values support optimistic conflict detection. Record existence, containment, reference edges, and
 * hierarchy rules are checked during application.
 */
@Serializable
sealed interface AuthoringOperation {
    val resource: AuthoringResourceRef

    @Serializable
    @SerialName("create_book")
    data class CreateBook(
        val id: BookId,
        val title: LibraryName,
        val icon: Icon,
        val color: Color,
        val tags: List<Ref<LibraryTag>>,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Book(id)
    }

    @Serializable
    @SerialName("patch_book")
    data class PatchBook(
        val id: BookId,
        val title: ExpectedChange<LibraryName>? = null,
        val icon: ExpectedChange<Icon>? = null,
        val color: ExpectedChange<Color>? = null,
        val tags: ExpectedChange<List<Ref<LibraryTag>>>? = null,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Book(id)
    }

    @Serializable
    @SerialName("delete_book")
    data class DeleteBook(
        val id: BookId,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Book(id)
    }

    @Serializable
    @SerialName("create_tag")
    data class CreateTag(
        val id: TagId,
        val name: LibraryName,
        val color: Color,
        val parents: List<Ref<LibraryTag>>,
        val placement: GridPlacement,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Tag(id)
    }

    @Serializable
    @SerialName("patch_tag")
    data class PatchTag(
        val id: TagId,
        val name: ExpectedChange<LibraryName>? = null,
        val color: ExpectedChange<Color>? = null,
        val parents: ExpectedChange<List<Ref<LibraryTag>>>? = null,
        val x: ExpectedChange<Int>? = null,
        val y: ExpectedChange<Int>? = null,
        val width: ExpectedChange<Int>? = null,
        val height: ExpectedChange<Int>? = null,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Tag(id)
    }

    @Serializable
    @SerialName("delete_tag")
    data class DeleteTag(
        val id: TagId,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Tag(id)
    }

    @Serializable
    @SerialName("create_page")
    data class CreatePage(
        val page: LibraryPage,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Page(page.id)
    }

    @Serializable
    @SerialName("patch_page")
    data class PatchPage(
        val id: PageId,
        val book: ExpectedChange<Ref<LibraryBook>>? = null,
        val name: ExpectedChange<LibraryName>? = null,
        val chapter: ExpectedChange<ChapterPath>? = null,
        val priority: ExpectedChange<Int>? = null,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Page(id)
    }

    @Serializable
    @SerialName("delete_page")
    data class DeletePage(
        val id: PageId,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Page(id)
    }

    @Serializable
    @SerialName("create_element")
    data class CreateElement(
        val element: AuthoringElement,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Element(element.id)
    }

    @Serializable
    @SerialName("patch_element")
    data class PatchElement(
        val id: ElementInstanceId,
        val page: ExpectedChange<Ref<LibraryPage>>? = null,
        val placement: ExpectedChange<ElementPlacement>? = null,
        val valueMutations: List<ExpectedElementValueMutation> = emptyList(),
        val elementType: ElementTypeChange? = null,
    ) : AuthoringOperation {
        init {
            require(elementType == null || valueMutations.isEmpty()) {
                "Element type replacement cannot be combined with value mutations."
            }
        }

        override val resource get() = AuthoringResourceRef.Element(id)
    }

    @Serializable
    @SerialName("duplicate_element")
    data class DuplicateElement(
        val sourceId: ElementInstanceId,
        val expectedValue: DataValue,
        val newId: ElementInstanceId,
        val page: Ref<LibraryPage>,
        val placement: ElementPlacement,
        val referenceRewrites: Map<ResourceId, ResourceId> = emptyMap(),
        val valueMutations: List<ElementValueMutation> = emptyList(),
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Element(newId)
    }

    @Serializable
    @SerialName("delete_element")
    data class DeleteElement(
        val id: ElementInstanceId,
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Element(id)
    }
}

@Serializable
sealed interface AuthoringResourceRef {
    val resourceId: ResourceId

    @Serializable
    @SerialName("book")
    data class Book(
        val id: BookId,
    ) : AuthoringResourceRef {
        override val resourceId: ResourceId get() = ResourceId("book", id.key)
    }

    @Serializable
    @SerialName("tag")
    data class Tag(
        val id: TagId,
    ) : AuthoringResourceRef {
        override val resourceId: ResourceId get() = ResourceId("tag", id.key)
    }

    @Serializable
    @SerialName("page")
    data class Page(
        val id: PageId,
    ) : AuthoringResourceRef {
        override val resourceId: ResourceId get() = ResourceId("page", id.key)
    }

    @Serializable
    @SerialName("element")
    data class Element(
        val id: ElementInstanceId,
    ) : AuthoringResourceRef {
        override val resourceId: ResourceId get() = ResourceId("element", id.value)
    }
}

@Serializable
sealed interface AuthoringResourceChange {
    val resource: AuthoringResourceRef

    @Serializable
    @SerialName("upsert_book")
    data class UpsertBook(
        val book: LibraryBook,
    ) : AuthoringResourceChange {
        override val resource get() = AuthoringResourceRef.Book(book.id)
    }

    @Serializable
    @SerialName("remove_book")
    data class RemoveBook(
        val id: BookId,
    ) : AuthoringResourceChange {
        override val resource get() = AuthoringResourceRef.Book(id)
    }

    @Serializable
    @SerialName("upsert_tag")
    data class UpsertTag(
        val tag: LibraryTag,
    ) : AuthoringResourceChange {
        override val resource get() = AuthoringResourceRef.Tag(tag.id)
    }

    @Serializable
    @SerialName("remove_tag")
    data class RemoveTag(
        val id: TagId,
    ) : AuthoringResourceChange {
        override val resource get() = AuthoringResourceRef.Tag(id)
    }

    @Serializable
    @SerialName("upsert_page")
    data class UpsertPage(
        val page: LibraryPage,
    ) : AuthoringResourceChange {
        override val resource get() = AuthoringResourceRef.Page(page.id)
    }

    @Serializable
    @SerialName("remove_page")
    data class RemovePage(
        val id: PageId,
    ) : AuthoringResourceChange {
        override val resource get() = AuthoringResourceRef.Page(id)
    }

    @Serializable
    @SerialName("upsert_element")
    data class UpsertElement(
        val element: AuthoringElement,
    ) : AuthoringResourceChange {
        override val resource get() = AuthoringResourceRef.Element(element.id)
    }

    @Serializable
    @SerialName("remove_element")
    data class RemoveElement(
        val id: ElementInstanceId,
    ) : AuthoringResourceChange {
        override val resource get() = AuthoringResourceRef.Element(id)
    }
}

/**
 * Reports direct committed changes and indirectly affected resources at a collaboration sequence.
 *
 * Indirect resources identify views requiring refresh. Event delivery is separate from committing the database
 * transaction.
 */
@Serializable
data class AuthoringChanged(
    /** Collaboration sequence assigned by the committed transaction. */
    val sequence: Long,
    /** Idempotency key of the batch that produced this change set. */
    val batchId: BatchId,
    /** Resources directly created, updated, or removed by the batch. */
    val changes: List<AuthoringResourceChange>,
    /** Resources whose projected views changed because of references or containment. */
    val indirectlyAffectedResources: Set<AuthoringResourceRef>,
)

/**
 * Transport representation of a value that can participate in optimistic conflict reporting.
 *
 * Values are intentionally limited to properties understood by authoring operations. They are not a general
 * serialization of every library model.
 */
@Serializable
sealed interface AuthoringPropertyValue {
    @Serializable
    @SerialName("string")
    data class StringValue(
        val value: String,
    ) : AuthoringPropertyValue

    @Serializable
    @SerialName("integer")
    data class IntegerValue(
        val value: Int,
    ) : AuthoringPropertyValue

    @Serializable
    @SerialName("color")
    data class ColorValue(
        val value: Color,
    ) : AuthoringPropertyValue

    @Serializable
    @SerialName("resource")
    data class ResourceValue(
        val value: ResourceId,
    ) : AuthoringPropertyValue

    @Serializable
    @SerialName("resources")
    data class ResourcesValue(
        val value: List<ResourceId>,
    ) : AuthoringPropertyValue

    @Serializable
    @SerialName("placement")
    data class PlacementValue(
        val value: ElementPlacement,
    ) : AuthoringPropertyValue

    @Serializable
    @SerialName("data")
    data class DataValueValue(
        val value: DataValue,
    ) : AuthoringPropertyValue
}

/**
 * Locates a rejected property edit with expected and current values when available.
 *
 * Callers should refresh and reconcile intent before retrying.
 */
@Serializable
data class PropertyConflict(
    val resource: AuthoringResourceRef,
    val path: ElementValuePath,
    val expected: AuthoringPropertyValue?,
    val actual: AuthoringPropertyValue?,
)

@Serializable
data class AuthoringDiagnostic(
    /** Stable machine readable reason used by clients and tests. */
    val code: String,
    /** Human readable detail. Defaults to the code when no additional detail is available. */
    val message: String = code,
    /** Resource implicated by the diagnostic, when the failure can be localized. */
    val resource: AuthoringResourceRef? = null,
    /** Nested element value path implicated by the diagnostic, when applicable. */
    val path: ElementValuePath? = null,
)

/**
 * Complete outcome of an authoring batch.
 *
 * Applied also identifies compilation invalidation. Conflict and Invalid never represent partially committed batch
 * edits. Only [Applied] represents committed state; the other outcomes mean that the transaction committed nothing.
 */
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
}

/** Result of executing an authoring mutation without committing it. */
sealed interface AuthoringPreviewResult {
    data class Valid(
        val affectedResources: Set<AuthoringResourceRef>,
    ) : AuthoringPreviewResult

    data class Conflict(
        val conflicts: List<PropertyConflict>,
    ) : AuthoringPreviewResult

    data class Invalid(
        val diagnostics: List<AuthoringDiagnostic>,
    ) : AuthoringPreviewResult
}
