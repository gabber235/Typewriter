package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.records.TagDeletionRecord
import com.typewritermc.realm.repository.records.TagRecord
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.services.libs.utils.DeferredProvider
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.Tag

class SurrealTagRepository(
    private val database: DeferredProvider<Surreal>,
) : TagRepository {
    override suspend fun listTags(): List<Tag> {
        val result = database.get().query("SELECT * FROM tag ORDER BY name, id").take(0)

        return TagRecord.parseList(result).map(TagRecord::toTag)
    }

    override suspend fun getTag(id: RecordId): Tag? {
        val result =
            database
                .get()
                .query(
                    $$"SELECT * FROM $tag",
                    mapOf("tag" to id.surrealId("tag")),
                ).take(0)

        return TagRecord.parseList(result).firstOrNull()?.toTag()
    }

    override suspend fun findMissing(ids: List<RecordId>): List<RecordId> {
        if (ids.isEmpty()) return emptyList()

        val result =
            database
                .get()
                .query(
                    $$"""
                $tags.filter(|$tag| !record::exists($tag))
                    """.trimIndent(),
                    mapOf("tags" to ids.surrealId("tag")),
                ).take(0)
        return result.array.map { it.recordId.toSkirRecordId() }
    }

    override suspend fun createTag(
        name: String,
        color: Color,
        parentIds: List<RecordId>,
        placement: Placement,
    ): RepositoryResult<Tag> =
        repositoryMutation(parentIds) {
            val result =
                database
                    .get()
                    .query(
                        $$"""
                BEGIN TRANSACTION;

                LET $distinct_parent_tags = array::distinct($parent_tags);

                IF $distinct_parent_tags.any(|$tag| !record::exists($tag)) {
                    THROW "parents-not-found-error";
                };

                LET $tag = CREATE ONLY tag SET
                    name = $name,
                    color = $color,
                    placement = { x: $x, y: $y, width: $width, height: $height };

                FOR $parent_tag IN $distinct_parent_tags {
                    RELATE $tag->inherits->$parent_tag;
                };

                RETURN SELECT * FROM $tag.id;
                COMMIT TRANSACTION;
                        """.trimIndent(),
                        mapOf(
                            "name" to name,
                            "color" to color.argb.toUInt().toLong(),
                            "x" to placement.x,
                            "y" to placement.y,
                            "width" to placement.width,
                            "height" to placement.height,
                            "parent_tags" to parentIds.surrealId("tag"),
                        ),
                    ).takeTransaction(5)

            TagRecord.parseList(result).singleOrNull()?.toTag()
                ?: error("Tag creation returned no record")
        }

    override suspend fun updateTag(tag: Tag): RepositoryResult<Tag> =
        repositoryMutation(tag.parentIds) {
            val result =
                database
                    .get()
                    .query(
                        $$"""
                BEGIN TRANSACTION;

                IF !record::exists($tag) {
                    THROW "tag-not-found-error";
                };

                LET $distinct_parent_tags = array::distinct($parent_tags);

                IF $distinct_parent_tags.any(|$tag| !record::exists($tag)) {
                    THROW "parents-not-found-error";
                };

                UPDATE $tag SET
                    name = $name,
                    color = $color,
                    placement = { x: $x, y: $y, width: $width, height: $height };

                LET $current_parents = SELECT VALUE ->inherits->tag FROM ONLY $tag;

                FOR $parent IN array::complement($distinct_parent_tags, $current_parents) {
                    RELATE $tag->inherits->$parent;
                };

                FOR $parent IN array::complement($current_parents, $distinct_parent_tags) {
                    DELETE inherits WHERE in = $tag AND out = $parent;
                };

                RETURN SELECT * FROM $tag.id;

                COMMIT TRANSACTION;
                        """.trimIndent(),
                        mapOf(
                            "tag" to tag.tagId.surrealId("tag"),
                            "name" to tag.name,
                            "color" to
                                tag.color.argb
                                    .toUInt()
                                    .toLong(),
                            "x" to tag.placement.x,
                            "y" to tag.placement.y,
                            "width" to tag.placement.width,
                            "height" to tag.placement.height,
                            "parent_tags" to tag.parentIds.surrealId("tag"),
                        ),
                    ).takeTransaction(8)

            TagRecord.parseList(result).singleOrNull()?.toTag()
                ?: error("Tag update returned no record")
        }

    override suspend fun deleteTag(id: RecordId): RepositoryResult<TagDeletion> =
        repositoryMutation {
            val result =
                database
                    .get()
                    .query(
                        $$"""
                BEGIN TRANSACTION;

                IF !record::exists($tag) {
                    THROW "tag-not-found-error";
                };
                LET $child_tags = SELECT VALUE in FROM inherits WHERE out = $tag;
                LET $books = SELECT VALUE in FROM bears WHERE out = $tag;

                DELETE inherits WHERE in = $tag OR out = $tag;
                DELETE bears WHERE out = $tag;
                DELETE $tag;

                RETURN { childTagIds: $child_tags, bookIds: $books };
                COMMIT TRANSACTION;
                        """.trimIndent(),
                        mapOf("tag" to id.surrealId("tag")),
                    ).takeTransaction(7)

            TagDeletionRecord.parse(result).toTagDeletion()
        }

    override suspend fun moveTag(
        id: RecordId,
        x: Int?,
        y: Int?,
    ): RepositoryResult<Tag> =
        updatePlacement(
            id = id,
            assignments = $$"placement.x = $x ?? placement.x, placement.y = $y ?? placement.y",
            bindings = mapOf("x" to x, "y" to y),
        )

    override suspend fun resizeTag(
        id: RecordId,
        width: Int?,
        height: Int?,
    ): RepositoryResult<Tag> =
        updatePlacement(
            id = id,
            assignments = $$"placement.width = $width ?? placement.width, placement.height = $height ?? placement.height",
            bindings = mapOf("width" to width, "height" to height),
        )

    private suspend fun updatePlacement(
        id: RecordId,
        assignments: String,
        bindings: Map<String, Int?>,
    ): RepositoryResult<Tag> =
        repositoryMutation {
            val result =
                database
                    .get()
                    .query(
                        $$"""
                BEGIN TRANSACTION;

                IF !record::exists($tag) {
                    THROW "tag-not-found-error";
                };

                UPDATE ONLY $tag SET $$assignments RETURN AFTER;

                COMMIT TRANSACTION;
                        """.trimIndent(),
                        mapOf("tag" to id.surrealId("tag")) + bindings,
                    ).takeTransaction(2)

            TagRecord.parseList(result).singleOrNull()?.toTag()
                ?: error("Tag placement update returned no record")
        }
}
