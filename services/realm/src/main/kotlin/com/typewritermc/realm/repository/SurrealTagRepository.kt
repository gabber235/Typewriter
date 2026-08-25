package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.realm.repository.records.TagRecord
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.surrealTagIds
import com.typewritermc.realm.repository.utils.toTagId

class SurrealTagRepository(
    private val database: Surreal,
) : TagRepository {
    override suspend fun listTags(): List<Tag> {
        val result = database.query("SELECT * FROM tag ORDER BY name, id").take(0)
        return TagRecord.parseList(result).map(TagRecord::toTag)
    }

    override suspend fun getTag(id: TagId): Tag? {
        val result =
            database
                .query(
                    $$"SELECT * FROM $tag",
                    mapOf("tag" to id.surrealId()),
                ).take(0)
        return TagRecord.parseList(result).firstOrNull()?.toTag()
    }

    override suspend fun findMissing(ids: Set<TagId>): Set<TagId> {
        if (ids.isEmpty()) return emptySet()
        val result =
            database
                .query(
                    $$"$tags.filter(|$tag| !record::exists($tag))",
                    mapOf("tags" to ids.surrealTagIds()),
                ).take(0)
        return result.array.mapTo(linkedSetOf()) { it.recordId.toTagId() }
    }
}
