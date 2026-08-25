package com.typewritermc.realm.repository

import com.typewritermc.library.Book
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.types.Color

interface TagRepository {
    suspend fun listTags(): List<Tag>

    suspend fun getTag(id: TagId): Tag?

    suspend fun findMissing(ids: Set<TagId>): Set<TagId>

    suspend fun createTag(
        name: LibraryName,
        color: Color,
        parentIds: Set<TagId>,
        placement: GridPlacement,
        encodeEvents: (Tag) -> List<OutboxEvent>,
    ): TagCreateResult

    suspend fun updateTag(
        expectedRevision: Long,
        tag: Tag,
        encodeEvents: (Tag) -> List<OutboxEvent>,
    ): TagUpdateResult

    suspend fun deleteTag(
        id: TagId,
        encodeEvents: (TagDeletion) -> List<OutboxEvent>,
    ): TagDeleteResult
}

sealed interface TagCreateResult {
    data class Success(
        val tag: Tag,
    ) : TagCreateResult

    data object NameInvalid : TagCreateResult

    data object WidthInvalid : TagCreateResult

    data object HeightInvalid : TagCreateResult

    data class ParentsNotFound(
        val parentIds: Set<TagId>,
    ) : TagCreateResult
}

sealed interface TagUpdateResult {
    data class Success(
        val tag: Tag,
    ) : TagUpdateResult

    data class Conflict(
        val actual: Tag,
    ) : TagUpdateResult

    data object NotFound : TagUpdateResult

    data object NameInvalid : TagUpdateResult

    data object WidthInvalid : TagUpdateResult

    data object HeightInvalid : TagUpdateResult

    data class ParentsNotFound(
        val parentIds: Set<TagId>,
    ) : TagUpdateResult

    data object InheritanceCycle : TagUpdateResult
}

sealed interface TagDeleteResult {
    data class Success(
        val deletion: TagDeletion,
    ) : TagDeleteResult

    data object NotFound : TagDeleteResult
}

data class TagDeletion(
    val childTags: List<Tag>,
    val books: List<Book>,
)
