package com.typewritermc.realm.repository

import com.typewritermc.library.Tag
import com.typewritermc.library.TagId

interface TagRepository {
    suspend fun listTags(): List<Tag>

    suspend fun getTag(id: TagId): Tag?

    suspend fun findMissing(ids: Set<TagId>): Set<TagId>
}
