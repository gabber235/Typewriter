package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.utils.TagRecord
import com.typewritermc.realm.repository.utils.requireValidId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.services.libs.utils.DeferredProvider
import protokt.v1.typewriter.models.v1.Placement
import protokt.v1.typewriter.models.v1.Tag

class SurrealTagRepository(
    private val db: DeferredProvider<Surreal>
) : TagRepository {

    override suspend fun listTags(): List<Tag> {
        val result = db.get().query("SELECT * FROM tag")
            .take(0)

        return TagRecord.parseList(result).map { it.toTag() }
    }

    override suspend fun getTag(id: String): Tag? {
        requireValidId("Tag", id)

        val result = db.get().queryBind(
            $$"SELECT * FROM type::record('tag', $id)",
            mapOf("id" to id)
        ).take(0)

        return TagRecord.parseList(result).firstOrNull()?.toTag()
    }

    override suspend fun createTag(name: String, color: Int, parentIds: List<String>, placement: Placement): Tag {
        for (parentId in parentIds) {
            requireValidId("Tag", parentId)
        }
        val colorLong = color.toUInt().toLong()

        val createResult = db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $tag_record = CREATE tag SET
                    name = $name,
                    color = $color,
                    placement = { x: $x ?? NONE, y: $y ?? NONE, width: $width ?? NONE, height: $height ?? NONE };

                LET $parent_records = $parent_ids.map(|$pid| type::record('tag', $pid));
                FOR $parent IN $parent_records {
                    RELATE $tag_record->inherits->$parent;
                };

                RETURN SELECT * FROM $tag_record.id;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf(
                "name" to name,
                "color" to colorLong,
                "x" to placement.x,
                "y" to placement.y,
                "width" to placement.width,
                "height" to placement.height,
                "parent_ids" to parentIds
            )
        ).takeTransaction(0)

        val records = TagRecord.parseList(createResult)
        val record = records.firstOrNull() ?: throw IllegalStateException("Failed to create tag")
        return record.toTag()
    }

    override suspend fun updateTag(tag: Tag): Tag {
        requireValidId("Tag", tag.tagId)
        val colorLong = tag.color?.value?.toLong()
        val placement = tag.placement

        println("Updating tag with ID: ${tag.tagId}: $tag")

        val result = db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $tag_record = type::record('tag', $id);

                IF !record::exists($tag_record) {
                    THROW 'Tag not found';
                };

                UPDATE $tag_record SET
                    name = $name,
                    color = $color,
                    placement = { x: $x, y: $y, width: $width, height: $height };

                LET $target_parents = ($parent_ids.map(|$pid| type::record('tag', $pid))) ?? [];
                LET $current_parents = (SELECT VALUE ->inherits->tag FROM ONLY $tag_record) ?? [];

                LET $new_parents = array::complement($target_parents, $current_parents);
                LET $remove_parents = array::complement($current_parents, $target_parents);

                FOR $parent IN $new_parents {
                    RELATE $tag_record->inherits->$parent;
                };

                FOR $parent IN $remove_parents {
                    DELETE inherits WHERE in = $tag_record AND out = $parent;
                };

                RETURN SELECT * FROM $tag_record FETCH parents;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf(
                "id" to tag.tagId,
                "name" to tag.name.orEmpty(),
                "color" to colorLong,
                "x" to placement?.x,
                "y" to placement?.y,
                "width" to placement?.width,
                "height" to placement?.height,
                "parent_ids" to tag.parentIds
            )
        ).takeTransaction(0)

        return TagRecord.parseList(result).firstOrNull()?.toTag()
            ?: throw IllegalStateException("Failed to update tag: $result")
    }

    override suspend fun deleteTag(id: String): Boolean {
        requireValidId("Tag", id)

        return db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $tag_record = type::record('tag', $id);

                IF !record::exists($tag_record) {
                    RETURN false;
                };

                DELETE inherits WHERE in = $tag_record OR out = $tag_record;
                DELETE $tag_record;
                RETURN true;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("id" to id)
        ).takeTransaction(0).boolean
    }

    override suspend fun moveTag(id: String, x: Int?, y: Int?): Boolean {
        requireValidId("Tag", id)

        return db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $tag_record = type::record('tag', $id);

                IF !record::exists($tag_record) {
                    RETURN false;
                };

                UPDATE $tag_record SET placement.x = $x ?? $tag_record.placement.x, placement.y = $y ?? $tag_record.placement.y;
                RETURN true;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("id" to id, "x" to x, "y" to y)
        ).takeTransaction(0).boolean
    }

    override suspend fun resizeTag(id: String, width: Int?, height: Int?): Boolean {
        requireValidId("Tag", id)

        return db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $tag_record = type::record('tag', $id);

                IF !record::exists($tag_record) {
                    RETURN false;
                };

                UPDATE $tag_record SET placement.width = $width ?? $tag_record.placement.width, placement.height = $height ?? $tag_record.placement.height;
                RETURN true;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("id" to id, "width" to width, "height" to height)
        ).takeTransaction(0).boolean
    }
}
