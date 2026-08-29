package com.typewritermc.realm.repository

import com.typewritermc.library.Book
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

interface LibraryBatchRepository {
    suspend fun createBooks(command: CreateBooksCommand): LibraryBatchResult<Book>

    suspend fun updateBooks(command: UpdateBooksCommand): LibraryBatchResult<Book>

    suspend fun deleteBooks(command: DeleteBooksCommand): LibraryBatchResult<Book>

    suspend fun createPages(command: CreatePagesCommand): LibraryBatchResult<Page>

    suspend fun updatePages(command: UpdatePagesCommand): LibraryBatchResult<Page>

    suspend fun movePages(command: MovePagesCommand): LibraryBatchResult<Page>

    suspend fun deletePages(command: DeletePagesCommand): LibraryBatchResult<Page>

    suspend fun createTags(command: CreateTagsCommand): LibraryBatchResult<Tag>

    suspend fun updateTags(command: UpdateTagsCommand): LibraryBatchResult<Tag>

    suspend fun deleteTags(command: DeleteTagsCommand): LibraryBatchResult<Tag>
}

enum class LibraryResourceKind {
    BOOK,
    PAGE,
    TAG,
}

data class LibraryInvalidation(
    val batchId: BatchId,
    val revision: Long,
    val resources: Set<LibraryResourceKind>,
)

sealed interface LibraryBatchResult<out T> {
    data class Success<T>(
        val batchId: BatchId,
        val values: List<T>,
        val affectedPages: Set<PageId>,
    ) : LibraryBatchResult<T>

    data class Conflict<T>(
        val conflicts: List<LibraryResourceConflict<T>>,
    ) : LibraryBatchResult<T>

    data class Invalid(
        val diagnostics: List<String>,
    ) : LibraryBatchResult<Nothing>
}

data class LibraryResourceConflict<T>(
    val id: ResourceId,
    val expectedRevision: Long,
    val actual: T?,
)

@Serializable
data class BookCreation(
    val id: BookId,
    val title: LibraryName,
    val icon: Icon,
    val color: Color,
    val tags: List<Ref<Tag>>,
)

@Serializable
data class BookUpdate(
    val id: BookId,
    val expectedRevision: Long,
    val title: LibraryName,
    val icon: Icon,
    val color: Color,
    val tags: List<Ref<Tag>>,
)

@Serializable
data class BookDeletion(
    val id: BookId,
    val expectedRevision: Long,
)

@Serializable
data class CreateBooksCommand(
    val batchId: BatchId,
    val books: List<BookCreation>,
) {
    init {
        books.requireBatch("Create books") { it.id }
    }
}

@Serializable
data class UpdateBooksCommand(
    val batchId: BatchId,
    val books: List<BookUpdate>,
) {
    init {
        books.requireBatch("Update books") { it.id }
    }
}

@Serializable
data class DeleteBooksCommand(
    val batchId: BatchId,
    val books: List<BookDeletion>,
) {
    init {
        books.requireBatch("Delete books") { it.id }
    }
}

@Serializable
data class PageCreation(
    val id: PageId,
    val book: Ref<Book>,
    val name: LibraryName,
    val kind: PageKindRef,
    val chapter: ChapterPath,
    val priority: Int,
)

@Serializable
data class PageUpdate(
    val id: PageId,
    val expectedRevision: Long,
    val name: LibraryName,
    val chapter: ChapterPath,
    val priority: Int,
)

@Serializable
data class PageMove(
    val id: PageId,
    val expectedRevision: Long,
    val book: Ref<Book>,
    val chapter: ChapterPath,
    val priority: Int,
)

@Serializable
data class PageDeletion(
    val id: PageId,
    val expectedRevision: Long,
)

@Serializable
data class CreatePagesCommand(
    val batchId: BatchId,
    val pages: List<PageCreation>,
) {
    init {
        pages.requireBatch("Create pages") { it.id }
    }
}

@Serializable
data class UpdatePagesCommand(
    val batchId: BatchId,
    val pages: List<PageUpdate>,
) {
    init {
        pages.requireBatch("Update pages") { it.id }
    }
}

@Serializable
data class MovePagesCommand(
    val batchId: BatchId,
    val pages: List<PageMove>,
) {
    init {
        pages.requireBatch("Move pages") { it.id }
    }
}

@Serializable
data class DeletePagesCommand(
    val batchId: BatchId,
    val pages: List<PageDeletion>,
) {
    init {
        pages.requireBatch("Delete pages") { it.id }
    }
}

@Serializable
data class TagCreation(
    val id: TagId,
    val name: LibraryName,
    val color: Color,
    val parents: List<Ref<Tag>>,
    val placement: GridPlacement,
)

@Serializable
data class TagUpdate(
    val id: TagId,
    val expectedRevision: Long,
    val name: LibraryName,
    val color: Color,
    val parents: List<Ref<Tag>>,
    val placement: GridPlacement,
)

@Serializable
data class TagDeletionItem(
    val id: TagId,
    val expectedRevision: Long,
)

@Serializable
data class CreateTagsCommand(
    val batchId: BatchId,
    val tags: List<TagCreation>,
) {
    init {
        tags.requireBatch("Create tags") { it.id }
    }
}

@Serializable
data class UpdateTagsCommand(
    val batchId: BatchId,
    val tags: List<TagUpdate>,
) {
    init {
        tags.requireBatch("Update tags") { it.id }
    }
}

@Serializable
data class DeleteTagsCommand(
    val batchId: BatchId,
    val tags: List<TagDeletionItem>,
) {
    init {
        tags.requireBatch("Delete tags") { it.id }
    }
}

private inline fun <T, I> List<T>.requireBatch(
    operation: String,
    id: (T) -> I,
) {
    require(isNotEmpty()) { "$operation batches must not be empty." }
    require(map(id).distinct().size == size) { "$operation batches must not contain duplicate ids." }
}
