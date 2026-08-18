package com.typewritermc.realm.repository

import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.Tag

interface TagRepository {
    suspend fun listTags(): List<Tag>

    suspend fun getTag(id: RecordId): Tag?

    suspend fun findMissing(ids: List<RecordId>): List<RecordId>

    suspend fun createTag(
        name: String,
        color: Color,
        parentIds: List<RecordId>,
        placement: Placement,
    ): TagCreateResult

    suspend fun updateTag(
        expectedRevision: Long,
        tag: Tag,
    ): TagUpdateResult

    suspend fun deleteTag(id: RecordId): TagDeleteResult
}

sealed interface TagCreateResult {
    data class Success(
        val tag: Tag,
    ) : TagCreateResult

    data object NameInvalid : TagCreateResult

    data object WidthInvalid : TagCreateResult

    data object HeightInvalid : TagCreateResult

    data class ParentsNotFound(
        val parentIds: List<RecordId>,
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
        val parentIds: List<RecordId>,
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
    val childTagIds: List<RecordId>,
    val bookIds: List<RecordId>,
)
