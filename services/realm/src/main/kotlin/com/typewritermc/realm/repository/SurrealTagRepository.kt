package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.records.TagCreateOutputRecord
import com.typewritermc.realm.repository.records.TagDeleteOutputRecord
import com.typewritermc.realm.repository.records.TagRecord
import com.typewritermc.realm.repository.records.TagUpdateOutputRecord
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toSkirRecordId
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.Tag

class SurrealTagRepository(
    private val database: Surreal,
) : TagRepository {
    override suspend fun listTags(): List<Tag> {
        val result = database.query("SELECT * FROM tag ORDER BY name, id").take(0)

        return TagRecord.parseList(result).map(TagRecord::toTag)
    }

    override suspend fun getTag(id: RecordId): Tag? {
        val result =
            database
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
    ): TagCreateResult {
        val result =
            database
                .query(
                    $$"""
                BEGIN TRANSACTION;

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
                ).takeTransaction(4)

        return TagCreateOutputRecord.parse(result).toResult()
    }

    override suspend fun updateTag(
        expectedRevision: Long,
        tag: Tag,
    ): TagUpdateResult {
        val result =
            database
                .query(
                    $$"""
                BEGIN TRANSACTION;

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

                COMMIT TRANSACTION;
                    """.trimIndent(),
                    mapOf(
                        "tag" to tag.tagId.surrealId("tag"),
                        "expected_revision" to expectedRevision,
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
                ).takeTransaction(3)

        return TagUpdateOutputRecord.parse(result).toResult()
    }

    override suspend fun deleteTag(id: RecordId): TagDeleteResult {
        val result =
            database
                .query(
                    $$"""
                BEGIN TRANSACTION;

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

                    {
                        kind: "success",
                        deletion: { childTagIds: $child_tags, bookIds: $books },
                    };
                };

                RETURN $result;
                COMMIT TRANSACTION;
                    """.trimIndent(),
                    mapOf("tag" to id.surrealId("tag")),
                ).takeTransaction(2)

        return TagDeleteOutputRecord.parse(result).toResult()
    }
}
