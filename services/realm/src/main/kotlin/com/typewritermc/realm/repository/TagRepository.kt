package com.typewritermc.realm.repository

import protokt.v1.typewriter.models.v1.Placement
import protokt.v1.typewriter.models.v1.Tag

interface TagRepository {
    suspend fun listTags(): List<Tag>
    suspend fun getTag(id: String): Tag?
    suspend fun createTag(name: String, color: Int, parentIds: List<String>, placement: Placement): Tag
    suspend fun updateTag(tag: Tag): Tag
    suspend fun deleteTag(id: String): Boolean
    suspend fun moveTag(id: String, x: Int, y: Int): Boolean
    suspend fun resizeTag(id: String, width: Int, height: Int): Boolean
}
