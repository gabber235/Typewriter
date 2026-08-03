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
    ): RepositoryResult<Tag>

    suspend fun updateTag(tag: Tag): RepositoryResult<Tag>

    suspend fun deleteTag(id: RecordId): RepositoryResult<TagDeletion>

    suspend fun moveTag(
        id: RecordId,
        x: Int?,
        y: Int?,
    ): RepositoryResult<Tag>

    suspend fun resizeTag(
        id: RecordId,
        width: Int?,
        height: Int?,
    ): RepositoryResult<Tag>
}

data class TagDeletion(
    val childTagIds: List<RecordId>,
    val bookIds: List<RecordId>,
)
