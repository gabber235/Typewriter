package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutation
import com.typewritermc.elements.ElementValuePath
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

interface AuthoringRepository {
    suspend fun snapshot(scopes: Set<AuthoringSnapshotScope>): AuthoringSnapshotResult

    suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult
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

data class AuthoringSnapshotResult(
    val sequence: Long,
    val slices: List<AuthoringSnapshotSlice>,
)

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

@Serializable
data class ExpectedChange<T>(
    val expected: T,
    val value: T,
)

@Serializable
data class ExpectedElementValueMutation(
    val expected: DataValue,
    val mutation: ElementValueMutation,
)

@Serializable
data class AuthoringElement(
    val id: ElementInstanceId,
    val page: Ref<LibraryPage>,
    val elementType: ElementTypeId,
    val schemaRevision: Int,
    val name: String,
    val value: DataValue,
    val placement: ElementPlacement,
) {
    init {
        require(schemaRevision > 0) { "Authoring element schema revisions must be positive." }
        require(name.isNotBlank()) { "Authoring element names must not be blank." }
    }
}

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
        val name: ExpectedChange<String>? = null,
        val placement: ExpectedChange<ElementPlacement>? = null,
        val valueMutations: List<ExpectedElementValueMutation> = emptyList(),
    ) : AuthoringOperation {
        override val resource get() = AuthoringResourceRef.Element(id)
    }

    @Serializable
    @SerialName("duplicate_element")
    data class DuplicateElement(
        val sourceId: ElementInstanceId,
        val expectedValue: DataValue,
        val newId: ElementInstanceId,
        val page: Ref<LibraryPage>,
        val name: String,
        val placement: ElementPlacement,
        val referenceRewrites: Map<ResourceId, ResourceId> = emptyMap(),
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

@Serializable
data class AuthoringChanged(
    val sequence: Long,
    val batchId: BatchId,
    val changes: List<AuthoringResourceChange>,
    val indirectlyAffectedResources: Set<AuthoringResourceRef>,
)

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

@Serializable
data class PropertyConflict(
    val resource: AuthoringResourceRef,
    val path: ElementValuePath,
    val expected: AuthoringPropertyValue?,
    val actual: AuthoringPropertyValue?,
)

@Serializable
data class AuthoringDiagnostic(
    val code: String,
    val message: String = code,
    val resource: AuthoringResourceRef? = null,
    val path: ElementValuePath? = null,
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
}
