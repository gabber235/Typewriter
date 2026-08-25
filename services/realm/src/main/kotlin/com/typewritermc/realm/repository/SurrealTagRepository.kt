package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.realm.outbox.RealmOutbox
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.records.TagCreateOutputRecord
import com.typewritermc.realm.repository.records.TagDeleteOutputRecord
import com.typewritermc.realm.repository.records.TagRecord
import com.typewritermc.realm.repository.records.TagUpdateOutputRecord
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.surrealTagIds
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.types.Color

class SurrealTagRepository(
    private val database: Surreal,
    private val outbox: RealmOutbox = SurrealRealmOutbox(database),
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
                    $$"""
                $tags.filter(|$tag| !record::exists($tag))
                    """.trimIndent(),
                    mapOf("tags" to ids.surrealTagIds()),
                ).take(0)
        return result.array.mapTo(linkedSetOf()) { it.recordId.toTagId() }
    }

    override suspend fun createTag(
        name: LibraryName,
        color: Color,
        parentIds: Set<TagId>,
        placement: GridPlacement,
        encodeEvents: (Tag) -> List<OutboxEvent>,
    ): TagCreateResult {
        val mutation =
            database.inTransaction { transaction ->
                val result =
                    transaction
                        .query(
                            $$"""
                LET $distinct_parent_tags = array::distinct($parent_tags);
                LET $missing_parents = $distinct_parent_tags.filter(|$tag| !record::exists($tag));
                LET $result = IF $missing_parents != [] {
                    { kind: "parents_not_found", parentIds: $missing_parents };
                } ELSE IF !fn::is_id($name) {
                    { kind: "name_invalid" };
                } ELSE IF $width <= 0 {
                    { kind: "width_invalid" };
                } ELSE IF $height <= 0 {
                    { kind: "height_invalid" };
                } ELSE {
                    LET $tag = CREATE ONLY tag SET
                        revision = 1,
                        name = $name,
                        color = $color,
                        placement = { x: $x, y: $y, width: $width, height: $height };

                    FOR $parent_tag IN $distinct_parent_tags {
                        RELATE $tag->inherits->$parent_tag;
                    };

                    { kind: "success", tagId: $tag.id };
                };

                RETURN IF $result.kind = "success" {
                    { kind: "success", tag: (SELECT * FROM ONLY $result.tagId) };
                } ELSE {
                    $result;
                };
                            """.trimIndent(),
                            mapOf(
                                "name" to name.value,
                                "color" to color.argb.toLong(),
                                "x" to placement.x,
                                "y" to placement.y,
                                "width" to placement.width,
                                "height" to placement.height,
                                "parent_tags" to parentIds.surrealTagIds(),
                            ),
                        ).takeTransaction(3)
                TagCreateOutputRecord.parse(result).toResult().also { mutation ->
                    if (mutation is TagCreateResult.Success) outbox.enqueue(transaction, encodeEvents(mutation.tag))
                }
            }
        if (mutation is TagCreateResult.Success) outbox.signalPending()
        return mutation
    }

    override suspend fun updateTag(
        expectedRevision: Long,
        tag: Tag,
        encodeEvents: (Tag) -> List<OutboxEvent>,
    ): TagUpdateResult {
        val mutation =
            database.inTransaction { transaction ->
                val result =
                    transaction
                        .query(
                            $$"""
                LET $actual = SELECT * FROM ONLY $tag;
                LET $result = IF $actual = NONE {
                    { kind: "not_found" };
                } ELSE IF $actual.revision != $expected_revision {
                    { kind: "conflict", tag: $actual };
                } ELSE {
                    LET $distinct_parent_tags = array::distinct($parent_tags);
                    LET $missing_parents = $distinct_parent_tags.filter(|$parent| !record::exists($parent));

                    IF $missing_parents != [] {
                        { kind: "parents_not_found", parentIds: $missing_parents };
                    } ELSE {
                        LET $descendants = $tag.{..+collect}<-inherits<-tag;
                        IF $distinct_parent_tags.any(|$parent| $parent = $tag OR $parent IN $descendants) {
                            { kind: "inheritance_cycle" };
                        } ELSE IF !fn::is_id($name) {
                            { kind: "name_invalid" };
                        } ELSE IF $width <= 0 {
                            { kind: "width_invalid" };
                        } ELSE IF $height <= 0 {
                            { kind: "height_invalid" };
                        } ELSE {
                            UPDATE ONLY $tag SET
                                revision += 1,
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

                            { kind: "success", tagId: $tag };
                        };
                    };
                };

                RETURN IF $result.kind = "success" {
                    { kind: "success", tag: (SELECT * FROM ONLY $result.tagId) };
                } ELSE {
                    $result;
                };
                            """.trimIndent(),
                            mapOf(
                                "tag" to tag.id.surrealId(),
                                "expected_revision" to expectedRevision,
                                "name" to tag.name.value,
                                "color" to tag.color.argb.toLong(),
                                "x" to tag.placement.x,
                                "y" to tag.placement.y,
                                "width" to tag.placement.width,
                                "height" to tag.placement.height,
                                "parent_tags" to tag.parents.surrealTagIds(),
                            ),
                        ).takeTransaction(2)
                TagUpdateOutputRecord.parse(result).toResult().also { mutation ->
                    if (mutation is TagUpdateResult.Success) outbox.enqueue(transaction, encodeEvents(mutation.tag))
                }
            }
        if (mutation is TagUpdateResult.Success) outbox.signalPending()
        return mutation
    }

    override suspend fun deleteTag(
        id: TagId,
        encodeEvents: (TagDeletion) -> List<OutboxEvent>,
    ): TagDeleteResult {
        val mutation =
            database.inTransaction { transaction ->
                val result =
                    transaction
                        .query(
                            $$"""
                LET $result = IF !record::exists($tag) {
                    { kind: "not_found" };
                } ELSE {
                    LET $child_tags = SELECT VALUE in FROM inherits WHERE out = $tag;
                    LET $books = SELECT VALUE in FROM bears WHERE out = $tag;

                    UPDATE $child_tags SET revision += 1;
                    UPDATE $books SET revision += 1;
                    DELETE inherits WHERE in = $tag OR out = $tag;
                    DELETE bears WHERE out = $tag;
                    DELETE $tag;
                    LET $updated_child_tags = SELECT * FROM $child_tags;
                    LET $updated_books = SELECT * FROM $books;

                    {
                        kind: "success",
                        deletion: { childTags: $updated_child_tags, books: $updated_books },
                    };
                };

                RETURN $result;
                            """.trimIndent(),
                            mapOf("tag" to id.surrealId()),
                        ).takeTransaction(1)
                TagDeleteOutputRecord.parse(result).toResult().also { mutation ->
                    if (mutation is TagDeleteResult.Success) outbox.enqueue(transaction, encodeEvents(mutation.deletion))
                }
            }
        if (mutation is TagDeleteResult.Success) outbox.signalPending()
        return mutation
    }
}
